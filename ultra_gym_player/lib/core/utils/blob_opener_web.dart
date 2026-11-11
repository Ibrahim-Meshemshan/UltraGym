import 'dart:js_interop';

import 'package:web/web.dart' as web;

import '../networking/api_client.dart';

/// الويب: الملف المحمي يُنزَّل كـ blob (الطلب بـ `?as=base64` داخل `ApiClient.getBytes`).
/// صفحات `html-printable` تُفتح بتبويب جديد للطباعة.
abstract final class BlobOpener {
  static Future<void> open(FileBlob file) async {
    final blob = web.Blob([file.bytes.toJS].toJS, web.BlobPropertyBag(type: file.isHtml ? 'text/html' : file.contentType));
    final url = web.URL.createObjectURL(blob);
    if (file.isHtml) {
      web.window.open(url, '_blank');
    } else {
      final a = web.HTMLAnchorElement()
        ..href = url
        ..download = file.filename;
      web.document.body?.append(a);
      a.click();
      a.remove();
    }
    Future<void>.delayed(const Duration(minutes: 1), () => web.URL.revokeObjectURL(url));
  }
}
