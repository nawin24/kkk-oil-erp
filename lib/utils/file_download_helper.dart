import 'file_download_stub.dart'
    if (dart.library.html) 'file_download_web.dart';

class FileDownloadHelper {
  static void downloadFile({
    required String content,
    required String fileName,
    String mimeType = 'text/csv',
  }) {
    downloadFileImpl(content: content, fileName: fileName, mimeType: mimeType);
  }
}
