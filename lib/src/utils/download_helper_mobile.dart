import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

/// Mobile implementation of DownloadHelper using path_provider and open_filex.
class DownloadHelper {
  static Future<void> descargarArchivo(Uint8List bytes, String filename) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$filename');
    await file.writeAsBytes(bytes);
    await OpenFilex.open(file.path);
  }
}
