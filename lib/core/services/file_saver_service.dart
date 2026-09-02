import 'file_saver_stub.dart'
    if (dart.library.html) 'file_saver_web.dart'
    if (dart.library.io) 'file_saver_io.dart' as impl;

class FileSaverService {
  static Future<void> saveAndShareFile({
    required List<int> bytes,
    required String filename,
    required String mimeType,
    required String subject,
  }) async {
    await impl.downloadFileToDevice(
      bytes: bytes,
      filename: filename,
      mimeType: mimeType,
      subject: subject,
    );
  }
}
