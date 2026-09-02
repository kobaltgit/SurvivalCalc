import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:survival_calc/core/enums/trip_enums.dart';
import 'package:survival_calc/core/services/media_storage_service.dart';
import 'package:survival_calc/core/theme/outdoor_theme.dart';
import 'package:survival_calc/features/calculator/presentation/providers/calculator_providers.dart';
import 'package:survival_calc/features/tracking/domain/models/way_point.dart';

class AddWaypointDialog extends ConsumerStatefulWidget {
  final Function({
    required String title,
    required WayPointType type,
    String? note,
    String? photoPath,
    String? authorName,
    TripRole? authorRole,
  }) onAdd;

  const AddWaypointDialog({
    super.key,
    required this.onAdd,
  });

  @override
  ConsumerState<AddWaypointDialog> createState() => _AddWaypointDialogState();
}

class _AddWaypointDialogState extends ConsumerState<AddWaypointDialog> {
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  final _mediaService = MediaStorageService();

  WayPointType _selectedType = WayPointType.water;
  String? _photoPath;
  Uint8List? _photoBytes;
  bool _isProcessingImage = false;

  String? _selectedAuthorName;
  TripRole? _selectedAuthorRole;

  @override
  void initState() {
    super.initState();
    _titleController.text = _selectedType.displayNameRu;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_selectedAuthorName == null) {
      final participants = ref.read(groupParticipantsProvider);
      if (participants.isNotEmpty) {
        // Default to leader, or navigator, or first member
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
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    setState(() => _isProcessingImage = true);
    final tripId = ref.read(activeTripProfileProvider).id;
    final path = await _mediaService.pickAndSaveImage(
      source: source,
      tripId: tripId,
      prefix: 'wp',
    );

    if (path != null) {
      final bytes = await MediaStorageService.getImageBytes(path);
      setState(() {
        _photoPath = path;
        _photoBytes = bytes;
        _isProcessingImage = false;
      });
    } else {
      setState(() => _isProcessingImage = false);
    }
  }

  Future<void> _deletePhoto() async {
    if (_photoPath != null) {
      await _mediaService.deleteImage(_photoPath!);
    }
    setState(() {
      _photoPath = null;
      _photoBytes = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final participants = ref.watch(groupParticipantsProvider);

    return AlertDialog(
      backgroundColor: OutdoorTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: OutdoorTheme.signalOrange, width: 1.2),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: OutdoorTheme.signalOrange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.add_location_alt,
              color: OutdoorTheme.signalOrange,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Добавить метку',
              style: TextStyle(
                color: OutdoorTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Author selection chips
              if (participants.isNotEmpty) ...[
                const Text(
                  '👤 Автор метки:',
                  style: TextStyle(
                    color: OutdoorTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: participants.map((p) {
                      final isSelected = p.name == _selectedAuthorName;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          avatar: Text(p.role.emoji, style: const TextStyle(fontSize: 14)),
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
                const SizedBox(height: 12),
              ],

              // 2. Waypoint Type chips
              const Text(
                '📍 Тип точки:',
                style: TextStyle(
                  color: OutdoorTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: WayPointType.values.map((type) {
                  final isSelected = type == _selectedType;
                  return ChoiceChip(
                    label: Text(type.displayNameRu),
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
                          _selectedType = type;
                          _titleController.text = type.displayNameRu;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // 3. Title field
              TextField(
                controller: _titleController,
                style: const TextStyle(color: OutdoorTheme.textPrimary, fontSize: 14),
                decoration: const InputDecoration(
                  labelText: 'Название метки',
                  labelStyle: TextStyle(color: OutdoorTheme.textSecondary, fontSize: 13),
                  filled: true,
                  fillColor: OutdoorTheme.surfaceCardElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 10),

              // 4. Note field
              TextField(
                controller: _noteController,
                style: const TextStyle(color: OutdoorTheme.textPrimary, fontSize: 13),
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Полевая заметка / Описание',
                  labelStyle: TextStyle(color: OutdoorTheme.textSecondary, fontSize: 12),
                  hintText: 'Например: родник чистый, стоянка на 3 палатки, брод по колено',
                  hintStyle: TextStyle(color: OutdoorTheme.textMuted, fontSize: 11),
                  filled: true,
                  fillColor: OutdoorTheme.surfaceCardElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  contentPadding: EdgeInsets.all(10),
                ),
              ),
              const SizedBox(height: 14),

              // 5. Photo section (1 photo per waypoint with retake & delete)
              const Text(
                '📷 Фотография места:',
                style: TextStyle(
                  color: OutdoorTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),

              if (_isProcessingImage)
                Container(
                  height: 110,
                  decoration: BoxDecoration(
                    color: OutdoorTheme.surfaceCardElevated,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(color: OutdoorTheme.signalOrange),
                  ),
                )
              else if (_photoBytes != null)
                Container(
                  decoration: BoxDecoration(
                    color: OutdoorTheme.surfaceCardElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: OutdoorTheme.signalOrange.withValues(alpha: 0.5)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.topRight,
                        children: [
                          Image.memory(
                            _photoBytes!,
                            height: 140,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                          Container(
                            margin: const EdgeInsets.all(6),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle, color: Colors.greenAccent, size: 12),
                                SizedBox(width: 4),
                                Text(
                                  '1 снимок сохранен',
                                  style: TextStyle(color: Colors.white, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            TextButton.icon(
                              onPressed: () => _pickPhoto(ImageSource.camera),
                              icon: const Icon(Icons.refresh, size: 16, color: OutdoorTheme.signalOrange),
                              label: const Text('Переснять', style: TextStyle(fontSize: 12, color: OutdoorTheme.signalOrange)),
                            ),
                            TextButton.icon(
                              onPressed: _deletePhoto,
                              icon: const Icon(Icons.delete_outline, size: 16, color: OutdoorTheme.alertRed),
                              label: const Text('Удалить', style: TextStyle(fontSize: 12, color: OutdoorTheme.alertRed)),
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
                        icon: const Icon(Icons.camera_alt, size: 18, color: OutdoorTheme.signalOrange),
                        label: const Text('С камеры', style: TextStyle(fontSize: 12, color: OutdoorTheme.textPrimary)),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: OutdoorTheme.surfaceCardElevated,
                          side: const BorderSide(color: OutdoorTheme.borderSubtle),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickPhoto(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library, size: 18, color: Colors.cyanAccent),
                        label: const Text('Из галереи', style: TextStyle(fontSize: 12, color: OutdoorTheme.textPrimary)),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: OutdoorTheme.surfaceCardElevated,
                          side: const BorderSide(color: OutdoorTheme.borderSubtle),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена', style: TextStyle(color: OutdoorTheme.textSecondary)),
        ),
        ElevatedButton(
          onPressed: () {
            final title = _titleController.text.trim();
            if (title.isNotEmpty) {
              widget.onAdd(
                title: title,
                type: _selectedType,
                note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
                photoPath: _photoPath,
                authorName: _selectedAuthorName,
                authorRole: _selectedAuthorRole,
              );
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: OutdoorTheme.signalOrange,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          ),
          child: const Text('Сохранить метку', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
