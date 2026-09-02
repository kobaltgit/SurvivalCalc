import 'package:flutter/material.dart';
import 'package:survival_calc/core/theme/outdoor_theme.dart';
import 'package:survival_calc/features/tracking/domain/models/map_layer_type.dart';

class MapLayerSelectorSheet extends StatelessWidget {
  final MapLayerType currentLayer;
  final ValueChanged<MapLayerType> onSelected;

  const MapLayerSelectorSheet({
    super.key,
    required this.currentLayer,
    required this.onSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required MapLayerType currentLayer,
    required ValueChanged<MapLayerType> onSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: OutdoorTheme.surfaceCardElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => MapLayerSelectorSheet(
        currentLayer: currentLayer,
        onSelected: (layer) {
          Navigator.pop(ctx);
          onSelected(layer);
        },
      ),
    );
  }

  IconData _getLayerIcon(MapLayerType type) {
    switch (type) {
      case MapLayerType.osm:
        return Icons.map;
      case MapLayerType.arcgisTopo:
        return Icons.terrain;
      case MapLayerType.openTopo:
        return Icons.landscape;
      case MapLayerType.satellite:
        return Icons.satellite_alt;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.layers, color: OutdoorTheme.signalOrange, size: 22),
                    SizedBox(width: 10),
                    Text(
                      'Слои карты',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: OutdoorTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: OutdoorTheme.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...MapLayerType.values.map((layer) {
              final isSelected = layer == currentLayer;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? OutdoorTheme.signalOrange.withValues(alpha: 0.15)
                      : OutdoorTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? OutdoorTheme.signalOrange
                        : OutdoorTheme.borderSubtle,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? OutdoorTheme.signalOrange
                          : OutdoorTheme.surfaceCardElevated,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getLayerIcon(layer),
                      color: isSelected ? Colors.black : OutdoorTheme.signalOrange,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    layer.name,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? OutdoorTheme.signalOrange : OutdoorTheme.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    layer.subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: OutdoorTheme.textSecondary,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: OutdoorTheme.signalOrange)
                      : null,
                  onTap: () => onSelected(layer),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
