import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:survival_calc/features/tracking/data/repositories/offline_tile_repository.dart';

class CachedTileProvider extends TileProvider {
  final String fallbackUrlTemplate;

  CachedTileProvider({
    this.fallbackUrlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    super.headers,
  });

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final z = coordinates.z;
    final x = coordinates.x;
    final y = coordinates.y;

    if (!kIsWeb) {
      final basePath = OfflineTileRepository.tilesBasePathSync;
      if (basePath != null) {
        final localFile = File('$basePath/$z/$x/$y.png');
        if (localFile.existsSync()) {
          return FileImage(localFile);
        }
      }
    }

    final url = getTileUrl(coordinates, options);
    return NetworkImage(url, headers: headers);
  }

  @override
  String getTileUrl(TileCoordinates coordinates, TileLayer options) {
    final template = options.urlTemplate ?? fallbackUrlTemplate;
    return template
        .replaceAll('{z}', coordinates.z.toString())
        .replaceAll('{x}', coordinates.x.toString())
        .replaceAll('{y}', coordinates.y.toString());
  }
}
