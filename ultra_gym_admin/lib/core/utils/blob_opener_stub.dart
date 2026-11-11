import '../networking/api_client.dart';

/// خارج المتصفح (اختبارات VM فقط لهذه الواجهة): فتح الملفات غير مدعوم.
abstract final class BlobOpener {
  static Future<void> open(FileBlob file) => throw UnsupportedError('BlobOpener يعمل بالمتصفح فقط بهذه الواجهة.');
}
