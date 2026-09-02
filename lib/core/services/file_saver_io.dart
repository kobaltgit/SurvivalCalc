import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

Future<void> downloadFileToDevice({
  required List<int> bytes,
  required String filename,
  required String mimeType,
  required String subject,
}) async {
  final tempDir = await getTemporaryDirectory();
  final filePath = '${tempDir.path}/$filename';
  final file = File(filePath);
  await file.writeAsBytes(bytes, flush: true);

  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(filePath, mimeType: mimeType)],
      subject: subject,
      text: subject,
    ),
  );
}

Future<void> openPdfInViewer({
  required List<int> bytes,
  required String filename,
}) async {
  await Printing.layoutPdf(
    onLayout: (format) => Uint8List.fromList(bytes),
    name: filename,
  );
}
