import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void downloadFileImpl({
  required String content,
  required String fileName,
  String mimeType = 'text/csv',
}) {
  final bytes = utf8.encode(content);
  final blob = html.Blob([bytes], '$mimeType;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}
