import 'package:web/web.dart' as web;

import 'session_storage.dart';

/// جلسة الدعم: لوحة المنصة تفتح `{dashboard_url}#token={token}` (التوكن بعد # فلا يصل لسجلات الخوادم).
/// يُقرأ التوكن قبل تشغيل الراوتر، يُحفظ بـ sessionStorage فقط، ويُمسح من الرابط.
abstract final class Impersonation {
  static final _token = RegExp(r'^#token=([^&]+)');

  static Future<void> consume(SessionStorage session) async {
    final m = _token.firstMatch(web.window.location.hash);
    if (m == null) return;
    await session.save(Uri.decodeComponent(m[1]!));
    final loc = web.window.location;
    web.window.history.replaceState(null, '', '${loc.pathname}${loc.search}');
  }
}
