import 'package:flutter/material.dart';
import 'package:survival_calc/core/theme/outdoor_theme.dart';
import 'package:survival_calc/features/tracking/domain/models/way_point.dart';

class AddWaypointDialog extends StatefulWidget {
  final Function(String title, WayPointType type, String? note) onAdd;

  const AddWaypointDialog({
    super.key,
    required this.onAdd,
  });

  @override
  State<AddWaypointDialog> createState() => _AddWaypointDialogState();
}

class _AddWaypointDialogState extends State<AddWaypointDialog> {
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  WayPointType _selectedType = WayPointType.water;

  @override
  void initState() {
    super.initState();
    _titleController.text = _selectedType.displayNameRu;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: OutdoorTheme.surfaceCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
          const Text(
            'Добавить метку',
            style: TextStyle(
              color: OutdoorTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Тип точки:',
              style: TextStyle(
                color: OutdoorTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
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
                    fontSize: 12,
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
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              style: const TextStyle(color: OutdoorTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Название',
                labelStyle: TextStyle(color: OutdoorTheme.textSecondary),
                filled: true,
                fillColor: OutdoorTheme.surfaceCardElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              style: const TextStyle(color: OutdoorTheme.textPrimary),
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Заметка (опционально)',
                labelStyle: TextStyle(color: OutdoorTheme.textSecondary),
                hintText: 'Например: родник чистый, стоянка на 3 палатки',
                hintStyle: TextStyle(color: OutdoorTheme.textMuted, fontSize: 12),
                filled: true,
                fillColor: OutdoorTheme.surfaceCardElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
            ),
          ],
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
                title,
                _selectedType,
                _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
              );
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: OutdoorTheme.signalOrange,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Сохранить', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
