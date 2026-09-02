import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:survival_calc/core/enums/trip_enums.dart';
import 'package:survival_calc/core/services/media_storage_service.dart';
import 'package:survival_calc/core/theme/outdoor_theme.dart';
import 'package:survival_calc/features/calculator/presentation/providers/calculator_providers.dart';
import 'package:survival_calc/features/tracking/domain/models/camp_debrief.dart';
import 'package:survival_calc/features/tracking/domain/models/daily_camp_note.dart';
import 'package:survival_calc/features/tracking/domain/models/daily_track.dart';
import 'package:survival_calc/features/tracking/domain/services/gpx_exporter.dart';
import 'package:survival_calc/features/tracking/presentation/providers/tracking_providers.dart';

class CampDebriefSheet extends ConsumerStatefulWidget {
  final CampDebrief debrief;
  final DailyTrack? track;

  const CampDebriefSheet({
    super.key,
    required this.debrief,
    this.track,
  });

  @override
  ConsumerState<CampDebriefSheet> createState() => _CampDebriefSheetState();
}

class _CampDebriefSheetState extends ConsumerState<CampDebriefSheet> {
  late List<DailyCampNote> _notes;
  final _textController = TextEditingController();
  final _mediaService = MediaStorageService();

  String _selectedWeather = '☀️ Ясно';
  String? _notePhotoPath;
  Uint8List? _notePhotoBytes;
  bool _isProcessingPhoto = false;

  String? _selectedAuthorName;
  TripRole? _selectedAuthorRole;

  final List<String> _weatherOptions = [
    '☀️ Ясно',
    '⛅ Переменная',
    '🌧️ Дождь',
    '🌫️ Туман',
    '❄️ Снег',
    '💨 Шторм/Ветер',
  ];

  @override
  void initState() {
    super.initState();
    _notes = List.from(widget.debrief.notes);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_selectedAuthorName == null) {
      final participants = ref.read(groupParticipantsProvider);
      if (participants.isNotEmpty) {
        final leader = participants.firstWhere(
          (p) => p.role == TripRole.leader,
          orElse: () => participants.first,
        );
        _selectedAuthorName = leader.name;
        _selectedAuthorRole = leader.role;
      } else {
        _selectedAuthorName = 'Руководитель';
        _selectedAuthorRole = TripRole.leader;
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    setState(() => _isProcessingPhoto = true);
    final tripId = ref.read(activeTripProfileProvider).id;
    final path = await _mediaService.pickAndSaveImage(
      source: source,
      tripId: tripId,
      prefix: 'camp_note_day${widget.debrief.dayIndex}',
    );

    if (path != null) {
      final bytes = await MediaStorageService.getImageBytes(path);
      setState(() {
        _notePhotoPath = path;
        _notePhotoBytes = bytes;
        _isProcessingPhoto = false;
      });
    } else {
      setState(() => _isProcessingPhoto = false);
    }
  }

  Future<void> _deletePhoto() async {
    if (_notePhotoPath != null) {
      await _mediaService.deleteImage(_notePhotoPath!);
    }
    setState(() {
      _notePhotoPath = null;
      _notePhotoBytes = null;
    });
  }

  Future<void> _addNote() async {
    final text = _textController.text.trim();
    if (text.isEmpty && _notePhotoPath == null) return;

    final tripId = ref.read(activeTripProfileProvider).id;
    final newNote = DailyCampNote(
      id: 'camp_${DateTime.now().millisecondsSinceEpoch}',
      tripId: tripId,
      dayNumber: widget.debrief.dayIndex,
      authorName: _selectedAuthorName ?? 'Участник',
      authorRole: _selectedAuthorRole,
      text: text.isEmpty ? 'Фотография дня' : text,
      weather: _selectedWeather,
      photoPath: _notePhotoPath,
      createdAt: DateTime.now(),
    );

    setState(() {
      _notes.add(newNote);
      _textController.clear();
      _notePhotoPath = null;
      _notePhotoBytes = null;
    });

    // Save to active track or repository
    await ref.read(trackingProvider.notifier).addCampNoteToActiveTrack(newNote);

    if (widget.track != null) {
      final updatedTrack = widget.track!.copyWith(
        debrief: widget.debrief.copyWith(notes: _notes),
      );
      await ref.read(trackStorageRepositoryProvider).saveCompletedTrack(updatedTrack);
    }
  }

  String _formatDuration(int seconds) {
    final int hours = seconds ~/ 3600;
    final int minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return '$hoursч $minutesм';
    }
    return '$minutes мин';
  }

  void _shareGpx(BuildContext context) async {
    if (widget.track == null || widget.track!.points.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нет точек трека для экспорта')),
      );
      return;
    }

    const exporter = GpxExporter();
    final String gpxContent = exporter.exportTrackToGpx(widget.track!);
    final String fileName = 'track_day_${widget.track!.dayIndex}.gpx';

    try {
      final xFile = XFile.fromData(
        utf8.encode(gpxContent),
        name: fileName,
        mimeType: 'application/gpx+xml',
      );
      await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          subject: 'GPX трек: ${widget.track!.title}',
        ),
      );
    } catch (_) {
      try {
        await SharePlus.instance.share(
          ShareParams(
            text: gpxContent,
            subject: 'GPX трек: ${widget.track!.title}',
          ),
        );
      } catch (_) {
        await Clipboard.setData(ClipboardData(text: gpxContent));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('GPX XML скопирован в буфер обмена')),
          );
        }
      }
    }
  }

  void _showFullscreenPhoto(BuildContext context, Uint8List bytes) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              minScale: 0.8,
              maxScale: 4.0,
              child: Center(child: Image.memory(bytes, fit: BoxFit.contain)),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final debrief = widget.debrief;
    final track = widget.track;

    return Container(
      decoration: const BoxDecoration(
        color: OutdoorTheme.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: OutdoorTheme.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: OutdoorTheme.signalOrange.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cabin,
                      color: OutdoorTheme.signalOrange,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          debrief.dayTitle,
                          style: const TextStyle(
                            color: OutdoorTheme.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Вечерний дебрифинг & Метаболический баланс',
                          style: TextStyle(
                            color: OutdoorTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Key physical metrics comparison
              _buildPhysicalMetricsGrid(),
              const SizedBox(height: 20),

              // Elevation Chart Profile
              if (track != null && track.points.length >= 2) ...[
                _buildElevationChart(),
                const SizedBox(height: 20),
              ],

              // 📝 NEW: Camp Journal Section (Photos & Daily Reflections)
              _buildCampJournalSection(context),
              const SizedBox(height: 20),

              // Metabolic & Energy Section
              _buildMetabolicBalanceCard(),
              const SizedBox(height: 16),

              // Nutrition Recommendations
              _buildNutritionRecommendationsCard(),
              const SizedBox(height: 16),

              // Hydration & Electrolytes
              _buildHydrationCard(),
              const SizedBox(height: 16),

              // Backpack Weight Melt Card
              _buildBackpackMeltCard(),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  if (track != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _shareGpx(context),
                        icon: const Icon(Icons.share, color: OutdoorTheme.signalOrange),
                        label: const Text(
                          'GPX Экспорт',
                          style: TextStyle(
                            color: OutdoorTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: OutdoorTheme.signalOrange),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  if (track != null) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: OutdoorTheme.signalOrange,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Принять и закрыть',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCampJournalSection(BuildContext context) {
    final participants = ref.watch(groupParticipantsProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OutdoorTheme.surfaceCardElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OutdoorTheme.signalOrange.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.menu_book, color: OutdoorTheme.signalOrange, size: 20),
              SizedBox(width: 8),
              Text(
                '📝 ДНЕВНИК ВЕЧЕРНЕГО ЛАГЕРЯ',
                style: TextStyle(
                  color: OutdoorTheme.signalOrange,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Заметки участников, погода и памятные фото вечера:',
            style: TextStyle(color: OutdoorTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),

          // Existing notes list
          if (_notes.isNotEmpty) ...[
            ..._notes.map((note) => _buildNoteCard(context, note)),
            const SizedBox(height: 12),
          ],

          // Form to add a new note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: OutdoorTheme.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: OutdoorTheme.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author chips
                if (participants.isNotEmpty) ...[
                  const Text(
                    '👤 Кто пишет заметку:',
                    style: TextStyle(color: OutdoorTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: participants.map((p) {
                        final isSelected = p.name == _selectedAuthorName;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            avatar: Text(p.role.emoji, style: const TextStyle(fontSize: 13)),
                            label: Text(p.name),
                            selected: isSelected,
                            selectedColor: OutdoorTheme.signalOrange,
                            backgroundColor: OutdoorTheme.surfaceCardElevated,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.black : OutdoorTheme.textPrimary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 11,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedAuthorName = p.name;
                                  _selectedAuthorRole = p.role;
                                });
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // Weather selection
                const Text(
                  '🌤️ Погода за день:',
                  style: TextStyle(color: OutdoorTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _weatherOptions.map((w) {
                      final isSelected = w == _selectedWeather;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(w),
                          selected: isSelected,
                          selectedColor: Colors.amber,
                          backgroundColor: OutdoorTheme.surfaceCardElevated,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.black : OutdoorTheme.textPrimary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 11,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedWeather = w);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 10),

                // Note text field
                TextField(
                  controller: _textController,
                  maxLines: 2,
                  style: const TextStyle(color: OutdoorTheme.textPrimary, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Впечатления о переходе, стоянка, примечания...',
                    hintStyle: TextStyle(color: OutdoorTheme.textMuted, fontSize: 12),
                    filled: true,
                    fillColor: OutdoorTheme.surfaceCardElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    contentPadding: EdgeInsets.all(10),
                  ),
                ),
                const SizedBox(height: 10),

                // Photo preview or photo buttons
                if (_isProcessingPhoto)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(color: OutdoorTheme.signalOrange),
                    ),
                  )
                else if (_notePhotoBytes != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: OutdoorTheme.signalOrange.withValues(alpha: 0.5)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        Image.memory(
                          _notePhotoBytes!,
                          height: 110,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              TextButton.icon(
                                onPressed: () => _pickPhoto(ImageSource.camera),
                                icon: const Icon(Icons.refresh, size: 14, color: OutdoorTheme.signalOrange),
                                label: const Text('Переснять', style: TextStyle(fontSize: 11, color: OutdoorTheme.signalOrange)),
                              ),
                              TextButton.icon(
                                onPressed: _deletePhoto,
                                icon: const Icon(Icons.delete_outline, size: 14, color: OutdoorTheme.alertRed),
                                label: const Text('Удалить', style: TextStyle(fontSize: 11, color: OutdoorTheme.alertRed)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickPhoto(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt, size: 16, color: OutdoorTheme.signalOrange),
                          label: const Text('Фото лагеря', style: TextStyle(fontSize: 11, color: OutdoorTheme.textPrimary)),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: OutdoorTheme.surfaceCardElevated,
                            side: const BorderSide(color: OutdoorTheme.borderSubtle),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickPhoto(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library, size: 16, color: Colors.cyanAccent),
                          label: const Text('Из галереи', style: TextStyle(fontSize: 11, color: OutdoorTheme.textPrimary)),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: OutdoorTheme.surfaceCardElevated,
                            side: const BorderSide(color: OutdoorTheme.borderSubtle),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 10),

                // Save Note Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _addNote,
                    icon: const Icon(Icons.post_add, size: 18),
                    label: const Text('Добавить в летопись похода', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: OutdoorTheme.signalOrange,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(BuildContext context, DailyCampNote note) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: OutdoorTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: OutdoorTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    note.authorRole?.emoji ?? '👤',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    note.authorName,
                    style: const TextStyle(
                      color: OutdoorTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              if (note.weather != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: OutdoorTheme.surfaceCardElevated,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    note.weather!,
                    style: const TextStyle(color: Colors.amber, fontSize: 11),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            note.text,
            style: const TextStyle(color: OutdoorTheme.textSecondary, fontSize: 12, height: 1.3),
          ),
          if (note.photoPath != null) ...[
            const SizedBox(height: 6),
            FutureBuilder<Uint8List?>(
              future: MediaStorageService.getImageBytes(note.photoPath!),
              builder: (ctx, snap) {
                final bytes = snap.data;
                if (bytes == null) return const SizedBox.shrink();
                return GestureDetector(
                  onTap: () => _showFullscreenPhoto(context, bytes),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      bytes,
                      height: 90,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhysicalMetricsGrid() {
    final debrief = widget.debrief;
    final track = widget.track;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OutdoorTheme.surfaceCardElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OutdoorTheme.borderSubtle.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricTile(
                'Дистанция',
                '${debrief.actualDistanceKm.toStringAsFixed(1)} км',
                'План: ${debrief.plannedDistanceKm.toStringAsFixed(1)} км',
                Icons.straighten,
                OutdoorTheme.signalOrange,
              ),
              _buildMetricTile(
                'Набор высоты',
                '+${debrief.actualAscentMeters.toStringAsFixed(0)} м',
                'План: +${debrief.plannedAscentMeters.toStringAsFixed(0)} м',
                Icons.arrow_upward,
                Colors.greenAccent,
              ),
            ],
          ),
          const Divider(height: 24, color: OutdoorTheme.borderSubtle),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricTile(
                'Время в движении',
                _formatDuration(debrief.movingDurationSeconds),
                'Паузы: ${_formatDuration(debrief.pauseDurationSeconds)}',
                Icons.timer,
                Colors.lightBlueAccent,
              ),
              _buildMetricTile(
                'Ср. скорость ходьбы',
                '${debrief.avgMovingSpeedKmh.toStringAsFixed(1)} км/ч',
                'Макс: ${track?.maxSpeedKmh.toStringAsFixed(1) ?? '0.0'} км/ч',
                Icons.speed,
                Colors.purpleAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(
    String title,
    String mainVal,
    String subVal,
    IconData icon,
    Color accentColor,
  ) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accentColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: OutdoorTheme.textMuted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  mainVal,
                  style: const TextStyle(
                    color: OutdoorTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  subVal,
                  style: const TextStyle(
                    color: OutdoorTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElevationChart() {
    final track = widget.track!;
    final points = track.points;
    final List<FlSpot> spots = [];

    double runningDist = 0.0;
    spots.add(FlSpot(0.0, points.first.altitude));

    for (int i = 1; i < points.length; i++) {
      runningDist += (points[i].speedKmh * 0.001) + 0.01;
      spots.add(FlSpot(runningDist, points[i].altitude));
    }

    final double minAlt = points.map((p) => p.altitude).reduce((a, b) => a < b ? a : b);
    final double maxAlt = points.map((p) => p.altitude).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OutdoorTheme.surfaceCardElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OutdoorTheme.borderSubtle.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ПРОФИЛЬ ВЫСОТЫ ЗА ДЕНЬ',
                style: TextStyle(
                  color: OutdoorTheme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              Icon(Icons.terrain, color: OutdoorTheme.signalOrange, size: 18),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                minY: (minAlt - 50).clamp(0.0, 9000.0),
                maxY: maxAlt + 50,
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: OutdoorTheme.signalOrange,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: OutdoorTheme.signalOrange.withValues(alpha: 0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Мин: ${minAlt.toStringAsFixed(0)} м',
                style: const TextStyle(color: OutdoorTheme.textSecondary, fontSize: 11),
              ),
              Text(
                'Макс: ${maxAlt.toStringAsFixed(0)} м',
                style: const TextStyle(color: OutdoorTheme.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetabolicBalanceCard() {
    final debrief = widget.debrief;
    final bool isDeficit = debrief.calorieDelta > 150;
    final bool isSurplus = debrief.calorieDelta < -150;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OutdoorTheme.surfaceCardElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDeficit
              ? OutdoorTheme.alertRed.withValues(alpha: 0.6)
              : (isSurplus ? Colors.green.withValues(alpha: 0.6) : OutdoorTheme.borderSubtle),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ЭНЕРГОЗАТРАТЫ И КАЛОРАЖ',
                style: TextStyle(
                  color: OutdoorTheme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDeficit
                      ? OutdoorTheme.alertRed.withValues(alpha: 0.2)
                      : (isSurplus ? Colors.green.withValues(alpha: 0.2) : OutdoorTheme.signalOrange.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isDeficit
                      ? '⚠️ Дефицит +${debrief.calorieDelta.toStringAsFixed(0)} ккал'
                      : (isSurplus
                          ? '✅ Запас ${debrief.calorieDelta.abs().toStringAsFixed(0)} ккал'
                          : '⚖️ В норме плана'),
                  style: TextStyle(
                    color: isDeficit
                        ? OutdoorTheme.alertRed
                        : (isSurplus ? Colors.greenAccent : OutdoorTheme.signalOrange),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Заложено в меню', style: TextStyle(color: OutdoorTheme.textSecondary, fontSize: 12)),
                  Text(
                    '${debrief.plannedDailyCalories.toStringAsFixed(0)} ккал',
                    style: const TextStyle(color: OutdoorTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              const Icon(Icons.arrow_forward, color: OutdoorTheme.textMuted, size: 18),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Фактический расход', style: TextStyle(color: OutdoorTheme.textSecondary, fontSize: 12)),
                  Text(
                    '${debrief.actualCaloriesBurned.toStringAsFixed(0)} ккал',
                    style: TextStyle(
                      color: isDeficit ? OutdoorTheme.alertRed : OutdoorTheme.signalOrange,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionRecommendationsCard() {
    final debrief = widget.debrief;
    if (debrief.nutritionRecommendations.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OutdoorTheme.surfaceCardElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OutdoorTheme.borderSubtle.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.restaurant, color: OutdoorTheme.signalOrange, size: 18),
              SizedBox(width: 8),
              Text(
                'КОРРЕКЦИЯ РАЦИОНА НА ВЕЧЕР',
                style: TextStyle(
                  color: OutdoorTheme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...debrief.nutritionRecommendations.map(
            (rec) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: OutdoorTheme.signalOrange, fontSize: 14)),
                  Expanded(
                    child: Text(
                      rec,
                      style: const TextStyle(
                        color: OutdoorTheme.textPrimary,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHydrationCard() {
    final debrief = widget.debrief;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OutdoorTheme.surfaceCardElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OutdoorTheme.borderSubtle.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.water_drop, color: Colors.lightBlueAccent, size: 18),
              SizedBox(width: 8),
              Text(
                'ГИДРАТАЦИЯ И ЭЛЕКТРОЛИТЫ',
                style: TextStyle(
                  color: OutdoorTheme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Восполнить жидкости до сна:',
                style: TextStyle(color: OutdoorTheme.textSecondary, fontSize: 13),
              ),
              Text(
                '≥ ${debrief.eveningWaterCompensationLiters.toStringAsFixed(1)} л',
                style: const TextStyle(
                  color: Colors.lightBlueAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            debrief.electrolyteAdvice,
            style: const TextStyle(
              color: OutdoorTheme.textPrimary,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackpackMeltCard() {
    final debrief = widget.debrief;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OutdoorTheme.surfaceCardElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OutdoorTheme.borderSubtle.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.backpack, color: OutdoorTheme.signalOrange, size: 18),
              SizedBox(width: 8),
              Text(
                'ТАЯНИЕ ВЕСА РЮКЗАКА',
                style: TextStyle(
                  color: OutdoorTheme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Съедено за день', style: TextStyle(color: OutdoorTheme.textSecondary, fontSize: 12)),
                  Text(
                    '-${debrief.dailyFoodWeightConsumedG.toStringAsFixed(0)} г еды',
                    style: const TextStyle(color: OutdoorTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Сожжено топлива', style: TextStyle(color: OutdoorTheme.textSecondary, fontSize: 12)),
                  Text(
                    '-${debrief.dailyGasConsumedG.toStringAsFixed(0)} г газа',
                    style: const TextStyle(color: OutdoorTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Вес на завтра', style: TextStyle(color: OutdoorTheme.textSecondary, fontSize: 12)),
                  Text(
                    '~${debrief.estimatedMorningPackWeightKg.toStringAsFixed(1)} кг',
                    style: const TextStyle(
                      color: OutdoorTheme.signalOrange,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
