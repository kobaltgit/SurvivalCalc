import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:survival_calc/features/tracking/data/repositories/offline_tile_repository.dart';
import 'package:survival_calc/features/tracking/domain/services/tile_math_utils.dart';

class DownloadProgress {
  final int downloaded;
  final int total;
  final int failed;
  final bool isDone;
  final bool isCancelled;
  final String? errorMessage;

  const DownloadProgress({
    required this.downloaded,
    required this.total,
    this.failed = 0,
    this.isDone = false,
    this.isCancelled = false,
    this.errorMessage,
  });

  double get percent => total > 0 ? (downloaded / total).clamp(0.0, 1.0) : 0.0;
}

class OfflineTileDownloader {
  static const String _tileServerUrl = 'https://tile.openstreetmap.org';
  static const int _concurrency = 5;

  bool _isCancelled = false;

  void cancel() {
    _isCancelled = true;
  }

  Stream<DownloadProgress> downloadTiles(
    Set<TileCoord> tiles, {
    String? regionName,
    double? centerLat,
    double? centerLon,
    double? radiusKm,
  }) async* {
    _isCancelled = false;
    final total = tiles.length;
    int downloaded = 0;
    int failed = 0;

    if (total == 0) {
      yield const DownloadProgress(downloaded: 0, total: 0, isDone: true);
      return;
    }

    yield DownloadProgress(downloaded: 0, total: total);

    final client = http.Client();
    final tileList = tiles.toList();
    int currentIndex = 0;

    final controller = StreamController<DownloadProgress>();

    Future<void> worker() async {
      while (true) {
        if (_isCancelled) break;
        int idx = -1;
        if (currentIndex < tileList.length) {
          idx = currentIndex++;
        }

        if (idx == -1 || idx >= tileList.length) break;

        final tile = tileList[idx];

        // Check if already cached
        final alreadyExists = await OfflineTileRepository.hasTile(tile.z, tile.x, tile.y);
        if (alreadyExists) {
          downloaded++;
          controller.add(DownloadProgress(downloaded: downloaded, total: total, failed: failed));
          continue;
        }

        try {
          final url = Uri.parse('$_tileServerUrl/${tile.z}/${tile.x}/${tile.y}.png');
          final response = await client.get(
            url,
            headers: {'User-Agent': 'SurvivalCalc/1.0 (offline expedition calculator)'},
          ).timeout(const Duration(seconds: 10));

          if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
            await OfflineTileRepository.saveTile(tile.z, tile.x, tile.y, response.bodyBytes);
            downloaded++;
          } else {
            failed++;
          }
        } catch (e) {
          failed++;
        }

        if (!_isCancelled) {
          controller.add(DownloadProgress(
            downloaded: downloaded + failed,
            total: total,
            failed: failed,
          ));
        }

        // Small throttle delay between requests to be gentle to OSM servers
        await Future.delayed(const Duration(milliseconds: 25));
      }
    }

    // Launch worker pool
    final workers = List.generate(_concurrency, (_) => worker());
    unawaited(Future.wait(workers).then((_) async {
      client.close();

      if (!_isCancelled && downloaded > 0) {
        final region = OfflineRegion(
          id: 'region_${DateTime.now().millisecondsSinceEpoch}',
          name: regionName ?? 'Район (${tiles.length} тайлов)',
          tileCount: downloaded,
          sizeMb: TileMathUtils.estimateSizeMb(downloaded),
          createdAt: DateTime.now(),
          centerLat: centerLat,
          centerLon: centerLon,
          radiusKm: radiusKm,
        );
        await OfflineTileRepository.saveRegion(region);
      }

      controller.add(DownloadProgress(
        downloaded: downloaded + failed,
        total: total,
        failed: failed,
        isDone: !_isCancelled,
        isCancelled: _isCancelled,
      ));
      await controller.close();
    }));

    yield* controller.stream;
  }

  void synchronized(Object lock, VoidCallback action) {
    action();
  }
}
