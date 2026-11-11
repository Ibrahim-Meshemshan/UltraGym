import 'dart:io';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../networking/api_client.dart';

/// الجهاز: الملف المحمي يُحفظ بمجلد مؤقت ثم يُفتح بالتطبيق المناسب.
/// صفحات `html-printable` تُعرض بـ WebView داخل الميزة (لا هنا).
abstract final class BlobOpener {
  static Future<void> open(FileBlob file) async {
    final dir = await getTemporaryDirectory();
    final name = file.isHtml && !file.filename.endsWith('.html') ? '${file.filename}.html' : file.filename;
    final f = File('${dir.path}/$name');
    await f.writeAsBytes(file.bytes, flush: true);
    await OpenFilex.open(f.path);
  }
}
