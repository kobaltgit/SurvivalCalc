// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<void> downloadFileToDevice({
  required List<int> bytes,
  required String filename,
  required String mimeType,
  required String subject,
}) async {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}

Future<void> openPdfInViewer({
  required List<int> bytes,
  required String filename,
}) async {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank');
}
