import 'package:flutter/services.dart';

void downloadFileImpl({
  required String content,
  required String fileName,
  String mimeType = 'text/csv',
}) {
  // On non-web/IO platforms, copy to clipboard as a fallback
  Clipboard.setData(ClipboardData(text: content));
}
