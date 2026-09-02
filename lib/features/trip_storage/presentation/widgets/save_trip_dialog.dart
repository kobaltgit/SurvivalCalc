import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:survival_calc/core/services/file_saver_service.dart';
import 'package:survival_calc/core/theme/outdoor_theme.dart';
import 'package:survival_calc/features/calculator/presentation/providers/calculator_providers.dart';
import 'package:survival_calc/features/tracking/presentation/providers/planned_route_providers.dart';
import 'package:survival_calc/features/trip_storage/presentation/providers/saved_trips_providers.dart';
import 'package:survival_calc/features/web/domain/services/web_url_service.dart';

class SaveTripDialog extends ConsumerStatefulWidget {
  final bool initialIsTemplate;

  const SaveTripDialog({
    super.key,
    this.initialIsTemplate = false,
  });

  static Future<bool?> show(BuildContext context, {bool initialIsTemplate = false}) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => SaveTripDialog(initialIsTemplate: initialIsTemplate),
    );
  }

  @override
  ConsumerState<SaveTripDialog> createState() => _SaveTripDialogState();
}

class _SaveTripDialogState extends ConsumerState<SaveTripDialog> {
  late bool _isTemplate;
  late TextEditingController _titleController;
  late TextEditingController _noteController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _isTemplate = widget.initialIsTemplate;
    final activeTrip = ref.read(activeTripProfileProvider);
    _titleController = TextEditingController(
      text: _isTemplate ? '${activeTrip.title} (Шаблон)' : activeTrip.title,
    );
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.disposeWidget();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeProfile = ref.watch(activeTripProfileProvider);
    final checkedMap = ref.watch(gearCheckedStateProvider);
    final participants = ref.watch(groupParticipantsProvider);
    final customFoods = ref.watch(customFoodProvider);
    final customGear = ref.watch(customGearProvider);
    final plannedRoute = ref.watch(plannedRouteProvider);

    return AlertDialog(
      backgroundColor: OutdoorTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: OutdoorTheme.signalOrange.withValues(alpha: 0.3),
          width: 1.2,
        ),
      ),
      title: Row(
        children: [
          Icon(
            _isTemplate ? Icons.bookmark_add_outlined : Icons.save_outlined,
            color: OutdoorTheme.signalOrange,
          ),
          const SizedBox(width: 8),
          Text(
            _isTemplate ? 'Сохранить как шаблон' : 'Сохранить поход',
            style: const TextStyle(fontSize: 18, color: OutdoorTheme.textPrimary),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mode selector: Real Trip vs Template
            Container(
              decoration: BoxDecoration(
                color: OutdoorTheme.darkBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                      onTap: () {
                        setState(() {
                          _isTemplate = false;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: !_isTemplate
                              ? OutdoorTheme.signalOrange.withValues(alpha: 0.25)
                              : Colors.transparent,
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                          border: !_isTemplate
                              ? Border.all(color: OutdoorTheme.signalOrange, width: 1.2)
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.terrain_outlined,
                              size: 16,
                              color: !_isTemplate ? OutdoorTheme.signalOrange : OutdoorTheme.textMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Мой поход',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: !_isTemplate ? FontWeight.bold : FontWeight.normal,
                                color: !_isTemplate ? OutdoorTheme.textPrimary : OutdoorTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
                      onTap: () {
                        setState(() {
                          _isTemplate = true;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _isTemplate
                              ? OutdoorTheme.signalOrange.withValues(alpha: 0.25)
                              : Colors.transparent,
                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
                          border: _isTemplate
                              ? Border.all(color: OutdoorTheme.signalOrange, width: 1.2)
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.content_copy_outlined,
                              size: 16,
                              color: _isTemplate ? OutdoorTheme.signalOrange : OutdoorTheme.textMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Шаблон',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: _isTemplate ? FontWeight.bold : FontWeight.normal,
                                color: _isTemplate ? OutdoorTheme.textPrimary : OutdoorTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Explanatory note
            Text(
              _isTemplate
                  ? '📋 Шаблон сохраняет сценарий похода для быстрого старта новых походов. Чек-лист сборов при создании нового похода будет чистым.'
                  : '⛺ «Мой поход» сохраняет текущий реальный прогресс сборов в чек-листе, состав участников и их рюкзаки.',
              style: const TextStyle(fontSize: 12, color: OutdoorTheme.textSecondary),
            ),
            const SizedBox(height: 14),

            // Title input
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: _isTemplate ? 'Название шаблона' : 'Название похода',
                prefixIcon: const Icon(Icons.title, color: OutdoorTheme.signalOrange),
              ),
            ),
            const SizedBox(height: 10),

            // Note input
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Заметка / Комментарий (необязательно)',
                prefixIcon: Icon(Icons.notes, color: OutdoorTheme.signalOrange),
              ),
            ),

            // Web-only backup warning and Key exporter
            if (kIsWeb) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: OutdoorTheme.darkBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: OutdoorTheme.signalOrange.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: OutdoorTheme.signalOrange, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Хранение на ПК (в браузере):',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: OutdoorTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Данные сохраняются во временном хранилище браузера. При очистке кэша они могут удалиться. Сохраните Ключ похода, чтобы открыть его в любой момент:',
                      style: TextStyle(fontSize: 11, color: OutdoorTheme.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: OutdoorTheme.signalOrange,
                              side: const BorderSide(color: OutdoorTheme.signalOrange),
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                            ),
                            onPressed: () {
                              final title = _titleController.text.trim().isNotEmpty
                                  ? _titleController.text.trim()
                                  : activeProfile.title;
                              final shareUrl = WebUrlService.buildShareUrl(
                                activeProfile.copyWith(title: title),
                                participants: participants,
                                plannedRoute: plannedRoute,
                              );
                              Clipboard.setData(ClipboardData(text: shareUrl));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('📋 Ключ-ссылка похода скопирована в буфер обмена!'),
                                  backgroundColor: OutdoorTheme.tacticalGreen,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy, size: 14),
                            label: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('Скопировать ключ', style: TextStyle(fontSize: 12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white38),
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                            ),
                            onPressed: () {
                              final title = _titleController.text.trim().isNotEmpty
                                  ? _titleController.text.trim()
                                  : activeProfile.title;
                              final shareUrl = WebUrlService.buildShareUrl(
                                activeProfile.copyWith(title: title),
                                participants: participants,
                                plannedRoute: plannedRoute,
                              );
                              final content = 'SURVIVALCALC — КЛЮЧ ПОХОДА\n'
                                  'Название: $title\n'
                                  'Дней: ${activeProfile.durationDays}, Участников: ${activeProfile.groupSize}\n'
                                  'Дистанция: ${activeProfile.totalDistanceKm} км, Набор: +${activeProfile.totalAscentMeters.toInt()} м\n'
                                  'Дата сохранения: ${DateTime.now().toLocal()}\n\n'
                                  'ССЫЛКА ДЛЯ ВОССТАНОВЛЕНИЯ ПОХОДА:\n'
                                  '$shareUrl\n';
                              final safeName = title.replaceAll(RegExp(r'[^\w\sа-яА-ЯёЁ-]'), '_').replaceAll(' ', '_');
                              FileSaverService.saveAndShareFile(
                                bytes: utf8.encode(content),
                                filename: '${safeName}_ключ.txt',
                                mimeType: 'text/plain',
                                subject: 'Ключ похода $title',
                              );
                            },
                            icon: const Icon(Icons.download, size: 14),
                            label: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('Скачать в .txt', style: TextStyle(fontSize: 12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Отмена'),
        ),
        ElevatedButton.icon(
          onPressed: _isSaving
              ? null
              : () async {
                  setState(() => _isSaving = true);
                  await ref.read(savedTripsProvider.notifier).saveCurrent(
                        title: _titleController.text,
                        isTemplate: _isTemplate,
                        profile: activeProfile,
                        checkedGearMap: checkedMap,
                        participants: participants,
                        customFoods: customFoods,
                        customGear: customGear,
                        plannedRoute: plannedRoute,
                        note: _noteController.text,
                      );
                  if (context.mounted) {
                    Navigator.of(context).pop(true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _isTemplate
                              ? 'Шаблон «${_titleController.text}» успешно сохранен!'
                              : 'Поход «${_titleController.text}» сохранен в Мои походы!',
                        ),
                        backgroundColor: OutdoorTheme.tacticalGreen,
                      ),
                    );
                  }
                },
          icon: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                )
              : const Icon(Icons.check, size: 18),
          label: Text(_isTemplate ? 'Сохранить шаблон' : 'Сохранить поход'),
        ),
      ],
    );
  }
}

extension on TextEditingController {
  void disposeWidget() {
    dispose();
  }
}
