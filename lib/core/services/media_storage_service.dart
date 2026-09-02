import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class MediaStorageService {
  final ImagePicker _picker = ImagePicker();

  /// In-memory cache for Web sessions
  static final Map<String, Uint8List> _webImageCache = {};

  /// Capture or pick an image with automatic compression (1600x1200, 80% quality)
  Future<String?> pickAndSaveImage({
    required ImageSource source,
    required String tripId,
    String? prefix,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1200,
        imageQuality: 80,
      );

      if (pickedFile == null) return null;

      final filename =
          '${prefix ?? 'photo'}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        final virtualPath = 'web_media://$tripId/$filename';
        _webImageCache[virtualPath] = bytes;
        return virtualPath;
      } else {
        final docDir = await getApplicationDocumentsDirectory();
        final cleanTripId = tripId.isEmpty ? 'default' : tripId;
        final tripPhotosDir =
            Directory('${docDir.path}/trips/$cleanTripId/photos');
        if (!await tripPhotosDir.exists()) {
          await tripPhotosDir.create(recursive: true);
        }

        final targetFile = File('${tripPhotosDir.path}/$filename');
        final bytes = await pickedFile.readAsBytes();
        await targetFile.writeAsBytes(bytes);
        return targetFile.path;
      }
    } catch (e) {
      debugPrint('MediaStorageService: Error picking/saving image: $e');
      return null;
    }
  }

  /// Get bytes of an image by path (works for both local file paths and Web virtual paths)
  static Future<Uint8List?> getImageBytes(String path) async {
    try {
      if (kIsWeb) {
        return _webImageCache[path];
      }
      final file = File(path);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
      return null;
    } catch (e) {
      debugPrint('MediaStorageService: Error reading image bytes: $e');
      return null;
    }
  }

  /// Delete a saved photo file from disk or web cache
  Future<void> deleteImage(String path) async {
    try {
      if (kIsWeb) {
        _webImageCache.remove(path);
      } else {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      debugPrint('MediaStorageService: Error deleting image: $e');
    }
  }
}
