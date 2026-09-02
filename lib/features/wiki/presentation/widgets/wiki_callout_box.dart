import 'package:flutter/material.dart';

enum CalloutType { tip, warning, formula, physiology, outdoor }

class WikiCalloutBox extends StatelessWidget {
  final String title;
  final String content;
  final CalloutType type;

  const WikiCalloutBox({
    super.key,
    required this.title,
    required this.content,
    this.type = CalloutType.tip,
  });

  Color _getColor() {
    switch (type) {
      case CalloutType.tip:
        return const Color(0xFF4CAF50);
      case CalloutType.warning:
        return const Color(0xFFFF5722);
      case CalloutType.formula:
        return const Color(0xFF00BCD4);
      case CalloutType.physiology:
        return const Color(0xFFFF9800);
      case CalloutType.outdoor:
        return const Color(0xFF9C27B0);
    }
  }

  IconData _getIcon() {
    switch (type) {
      case CalloutType.tip:
        return Icons.lightbulb_rounded;
      case CalloutType.warning:
        return Icons.warning_amber_rounded;
      case CalloutType.formula:
        return Icons.functions_rounded;
      case CalloutType.physiology:
        return Icons.favorite_rounded;
      case CalloutType.outdoor:
        return Icons.terrain_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getIcon(), color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13.5,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
