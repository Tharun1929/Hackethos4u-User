import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class DownloadAPI {
  static Future<void> downloadFile(String url, String fileName) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/$fileName';

      await Dio().download(
        url,
        filePath,
        options: Options(
          headers: {
            'Content-Type': 'application/octet-stream',
          },
        ),
        onReceiveProgress: (received, total) {
          if (total != -1) {
            // print('Download progress: ${(received / total * 100).toStringAsFixed(0)}%');
          }
        },
      );

      // print('File downloaded to: $filePath');
      OpenFile.open(filePath);
    } catch (e) {
      // print('Download failed: $e');
      throw Exception('Download failed: $e');
    }
  }
}
