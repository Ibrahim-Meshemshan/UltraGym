import 'package:url_launcher/url_launcher.dart';

/// فتح الروابط الخارجية: متصفح، اتصال، واتساب.
abstract final class Launcher {
  static Future<bool> url(String link) async {
    final uri = Uri.tryParse(link);
    if (uri == null) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<bool> phone(String number) => launchUrl(Uri(scheme: 'tel', path: number));

  /// رسالة واتساب جاهزة (مثل كلمة السر المؤقتة مع رسالة الخادم).
  static Future<bool> whatsapp(String phone, {String? text}) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.https('wa.me', '/$digits', {if (text != null && text.isNotEmpty) 'text': text});
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
