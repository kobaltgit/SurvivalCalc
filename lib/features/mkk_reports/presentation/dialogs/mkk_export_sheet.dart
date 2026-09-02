import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:survival_calc/core/services/file_saver_service.dart';
import 'package:survival_calc/core/theme/outdoor_theme.dart';
import 'package:survival_calc/features/calculator/presentation/providers/calculator_providers.dart';
import 'package:survival_calc/features/mkk_reports/domain/services/expedition_archive_service.dart';
import 'package:survival_calc/features/mkk_reports/domain/services/mkk_markdown_generator.dart';
import 'package:survival_calc/features/mkk_reports/domain/services/mkk_pdf_generator.dart';
import 'package:survival_calc/features/tracking/domain/models/daily_camp_note.dart';
import 'package:survival_calc/features/tracking/domain/models/daily_track.dart';
import 'package:survival_calc/features/tracking/domain/models/way_point.dart';
import 'package:survival_calc/features/tracking/presentation/providers/tracking_providers.dart';

class MkkExportSheet extends ConsumerStatefulWidget {
  const MkkExportSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const MkkExportSheet(),
    );
  }

  @override
  ConsumerState<MkkExportSheet> createState() => _MkkExportSheetState();
}

class _MkkExportSheetState extends ConsumerState<MkkExportSheet> {
  bool _isGeneratingPassport = false;
  bool _isGeneratingReport = false;
  bool _isExportingZip = false;

  @override
  Widget build(BuildContext context) {
    final tripProfile = ref.watch(tripProfileProvider);
    final participants = ref.watch(participantsProvider);
    final calcResult = ref.watch(tripCalculationResultProvider);
    final tracksAsync = ref.watch(currentTripTracksProvider);
    final sandboxAsync = ref.watch(sandboxTracksProvider);
    final trackingState = ref.watch(trackingProvider);

    List<DailyTrack> tracks = List<DailyTrack>.from(tracksAsync.value ?? []);

    // 1. If current trip has no saved tracks yet, include sandbox tracks so simulation is reflected
    if (tracks.isEmpty && sandboxAsync.value != null && sandboxAsync.value!.isNotEmpty) {
      tracks = List<DailyTrack>.from(sandboxAsync.value!);
    }

    // 2. If an active track is currently running (live GPS or simulation), include it
    if (trackingState.activeTrack != null &&
        trackingState.activeTrack!.points.isNotEmpty &&
        !tracks.any((t) => t.id == trackingState.activeTrack!.id)) {
      tracks.add(trackingState.activeTrack!);
    }

    // Sort tracks chronologically
    tracks.sort((a, b) => a.startTime.compareTo(b.startTime));

    final List<WayPoint> waypoints = [
      ...tracks.expand((t) => t.waypoints),
      if (trackingState.activeTrack != null)
        ...trackingState.activeTrack!.waypoints.where(
          (wp) => !tracks.any((t) => t.waypoints.any((w) => w.id == wp.id)),
        ),
    ];
    final List<DailyCampNote> campNotes = [
      ...tracks.expand((t) => t.debrief?.notes ?? <DailyCampNote>[]),
      if (trackingState.activeTrack?.debrief != null)
        ...trackingState.activeTrack!.debrief!.notes,
    ];

    return Container(
      decoration: const BoxDecoration(
        color: OutdoorTheme.darkBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: OutdoorTheme.signalOrange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.picture_as_pdf, color: OutdoorTheme.signalOrange, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Экспорт документов МКК',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: OutdoorTheme.textPrimary,
                            ),
                          ),
                          Text(
                            'Маршрутная книжка, Отчет и ZIP-архив',
                            style: TextStyle(fontSize: 12, color: OutdoorTheme.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: OutdoorTheme.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: OutdoorTheme.borderSubtle),
              const SizedBox(height: 12),

              // Document 1: Pre-trip Passport / Form No. 5 Tour
              _buildDocCard(
                context: context,
                isLoading: _isGeneratingPassport,
                icon: Icons.menu_book,
                badgeColor: OutdoorTheme.signalOrange,
                title: '📕 Маршрутная книжка (Форма № 5 – Тур, ФСТР 2020)',
                subtitle: 'Официальный заявочный бланк ФСТР: титул МЧС, состав группы с ПДн, заявленный график по дням, норматив веса М/Ж (п. 4.6), координатор и штампы МКК.',
                onPrint: () async {
                  setState(() => _isGeneratingPassport = true);
                  try {
                    final pdfBytes = await MkkPdfGenerator.generatePreTripPassportPdf(
                      profile: tripProfile,
                      participants: participants,
                      calcResult: calcResult,
                    );
                    final safeTitle = tripProfile.title.replaceAll(RegExp(r'[^\w\dа-яА-Я_\-]'), '_');
                    await FileSaverService.openPdfInViewer(
                      bytes: pdfBytes,
                      filename: 'RouteBook_Form5_$safeTitle.pdf',
                    );
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Ошибка формирования PDF: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isGeneratingPassport = false);
                  }
                },
                onShare: () async {
                  setState(() => _isGeneratingPassport = true);
                  try {
                    final pdfBytes = await MkkPdfGenerator.generatePreTripPassportPdf(
                      profile: tripProfile,
                      participants: participants,
                      calcResult: calcResult,
                    );
                    final safeTitle = tripProfile.title.replaceAll(RegExp(r'[^\w\dа-яА-Я_\-]'), '_');
                    await FileSaverService.saveAndShareFile(
                      bytes: pdfBytes,
                      filename: 'RouteBook_Form5_$safeTitle.pdf',
                      mimeType: 'application/pdf',
                      subject: 'Маршрутная книжка (Форма № 5 - Тур): ${tripProfile.title}',
                    );
                    if (context.mounted && kIsWeb) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Документ PDF загружен!'),
                          backgroundColor: OutdoorTheme.tacticalGreen,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Ошибка экспорта PDF: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isGeneratingPassport = false);
                  }
                },
                onCopyMarkdown: () {
                  final md = MkkMarkdownGenerator.generatePreTripPassportMarkdown(
                    profile: tripProfile,
                    participants: participants,
                    calcResult: calcResult,
                  );
                  Clipboard.setData(ClipboardData(text: md));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('📋 Маршрутная книжка скопирована в буфер обмена (Markdown / Word)!'),
                      backgroundColor: OutdoorTheme.tacticalGreen,
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),

              // Document 2: Post-trip Technical Report
              _buildDocCard(
                context: context,
                isLoading: _isGeneratingReport,
                icon: Icons.assignment_turned_in,
                badgeColor: OutdoorTheme.tacticalGreen,
                title: '📗 Итоговый технический отчет о походе',
                subtitle: 'Отчет после прохождения: сравнение План/Факт, треки по дням, паспорт путевых точек, погода и дневник лагеря.',
                onPrint: () async {
                  setState(() => _isGeneratingReport = true);
                  try {
                    final pdfBytes = await MkkPdfGenerator.generatePostTripReportPdf(
                      profile: tripProfile,
                      participants: participants,
                      tracks: tracks,
                      waypoints: waypoints,
                      campNotes: campNotes,
                    );
                    final safeTitle = tripProfile.title.replaceAll(RegExp(r'[^\w\dа-яА-Я_\-]'), '_');
                    await FileSaverService.openPdfInViewer(
                      bytes: pdfBytes,
                      filename: 'Report_$safeTitle.pdf',
                    );
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Ошибка формирования отчета PDF: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isGeneratingReport = false);
                  }
                },
                onShare: () async {
                  setState(() => _isGeneratingReport = true);
                  try {
                    final pdfBytes = await MkkPdfGenerator.generatePostTripReportPdf(
                      profile: tripProfile,
                      participants: participants,
                      tracks: tracks,
                      waypoints: waypoints,
                      campNotes: campNotes,
                    );
                    final safeTitle = tripProfile.title.replaceAll(RegExp(r'[^\w\dа-яА-Я_\-]'), '_');
                    await FileSaverService.saveAndShareFile(
                      bytes: pdfBytes,
                      filename: 'Report_$safeTitle.pdf',
                      mimeType: 'application/pdf',
                      subject: 'Итоговый отчет: ${tripProfile.title}',
                    );
                    if (context.mounted && kIsWeb) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Итоговый отчет PDF загружен!'),
                          backgroundColor: OutdoorTheme.tacticalGreen,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Ошибка экспорта отчета: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isGeneratingReport = false);
                  }
                },
                onCopyMarkdown: () {
                  final md = MkkMarkdownGenerator.generatePostTripReportMarkdown(
                    profile: tripProfile,
                    participants: participants,
                    tracks: tracks,
                    waypoints: waypoints,
                    campNotes: campNotes,
                  );
                  Clipboard.setData(ClipboardData(text: md));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('📋 Итоговый отчет скопирован в буфер обмена!'),
                      backgroundColor: OutdoorTheme.tacticalGreen,
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),

              // Document 3: Expedition ZIP Archive
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: OutdoorTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: OutdoorTheme.signalOrange.withValues(alpha: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: OutdoorTheme.signalOrange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.folder_zip, color: OutdoorTheme.signalOrange, size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '🗄️ Экспедиционный ZIP-архив',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: OutdoorTheme.textPrimary,
                                ),
                              ),
                              Text(
                                'Всё в одном файле: PDF-отчеты + GPX + Фото + Markdown',
                                style: TextStyle(fontSize: 11, color: OutdoorTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Упаковывает в единый архив: Маршрутную книжку (PDF), Отчет (PDF), сводку Markdown/HTML, GPX-треки всех ходовых дней и оригиналы фото-меток.',
                      style: TextStyle(fontSize: 12, color: OutdoorTheme.textSecondary, height: 1.3),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isExportingZip
                            ? null
                            : () async {
                                setState(() => _isExportingZip = true);
                                try {
                                  final zipBytes = await ExpeditionArchiveService.createExpeditionZip(
                                    profile: tripProfile,
                                    participants: participants,
                                    calcResult: calcResult,
                                    tracks: tracks,
                                    waypoints: waypoints,
                                    campNotes: campNotes,
                                  );

                                  final safeTitle = tripProfile.title.replaceAll(RegExp(r'[^\w\dа-яА-Я_\-]'), '_');
                                  await FileSaverService.saveAndShareFile(
                                    bytes: zipBytes,
                                    filename: 'Expedition_${safeTitle}_${DateTime.now().millisecondsSinceEpoch}.zip',
                                    mimeType: 'application/zip',
                                    subject: 'Экспедиционный архив: ${tripProfile.title}',
                                  );

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('✅ Экспедиционный ZIP-архив успешно сформирован и сохранен!'),
                                        backgroundColor: OutdoorTheme.tacticalGreen,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Ошибка при сборке архива: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                } finally {
                                  if (mounted) {
                                    setState(() => _isExportingZip = false);
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: OutdoorTheme.signalOrange,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: _isExportingZip
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                              )
                            : const Icon(Icons.download, size: 20),
                        label: Text(
                          _isExportingZip ? 'Сборка архива...' : 'Сформировать и скачать ZIP-архив',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocCard({
    required BuildContext context,
    required bool isLoading,
    required IconData icon,
    required Color badgeColor,
    required String title,
    required String subtitle,
    required VoidCallback onPrint,
    required VoidCallback onShare,
    required VoidCallback onCopyMarkdown,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OutdoorTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OutdoorTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: OutdoorTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: OutdoorTheme.textSecondary, height: 1.3),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isLoading ? null : onPrint,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: OutdoorTheme.signalOrange,
                    side: const BorderSide(color: OutdoorTheme.signalOrange),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: isLoading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: OutdoorTheme.signalOrange),
                        )
                      : const Icon(Icons.print, size: 16),
                  label: const Text('Печать / PDF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isLoading ? null : onShare,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: OutdoorTheme.tacticalGreen,
                    side: const BorderSide(color: OutdoorTheme.tacticalGreen),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.download, size: 16),
                  label: Text(kIsWeb ? 'Скачать PDF' : 'Отправить', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Скопировать текст (Word / Markdown)',
                style: IconButton.styleFrom(
                  backgroundColor: OutdoorTheme.surfaceCardElevated,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.copy, size: 18, color: OutdoorTheme.textPrimary),
                onPressed: onCopyMarkdown,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
