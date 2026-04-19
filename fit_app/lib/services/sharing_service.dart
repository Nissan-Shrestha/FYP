import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class SharingService {
  static Future<void> shareImageBytes(Uint8List bytes, String filename, {String? text}) async {
    final directory = await getTemporaryDirectory();
    final file = await File('${directory.path}/$filename').create();
    await file.writeAsBytes(bytes);

    // Don't await the share sheet if you want the app to resume instantly
    Share.shareXFiles(
      [XFile(file.path)],
      text: text,
    );
  }
}
