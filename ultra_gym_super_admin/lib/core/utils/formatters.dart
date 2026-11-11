import 'package:intl/intl.dart';
import 'package:timezone/data/latest_10y.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../config/app_config.dart';

/// تنسيق العرض: الأرقام لاتينية دائماً، المبالغ والتواريخ بصيغة ثابتة، والأوقات بتوقيت النادي.
/// النص الناتج LTR: اعرضه داخل `Text(..., textDirection: TextDirection.ltr)` أو `LtrText`.
abstract final class Formatters {
  static tz.Location? _location;

  /// يُستدعى مرة عند التشغيل، ثم مع `tenant.timezone` بعد الدخول.
  static void init([String timezone = AppConfig.defaultTimezone]) {
    if (_location == null) tzdata.initializeTimeZones();
    setTimezone(timezone);
  }

  static void setTimezone(String name) {
    try {
      _location = tz.getLocation(name);
    } on Object {
      _location = tz.getLocation(AppConfig.defaultTimezone);
    }
  }

  static final _usd = NumberFormat('#,##0.00', 'en');
  static final _int = NumberFormat('#,##0', 'en');
  static final _dec = NumberFormat('#,##0.##', 'en');

  /// `$25.00`
  static String usd(num? v) => v == null ? '—' : '\$${_usd.format(v)}';

  /// `325,000 ل.س`
  static String syp(num? v) => v == null ? '—' : '${_int.format(v.round())} ل.س';

  static String money(num? v, String currency) => currency.toUpperCase() == 'SYP' ? syp(v) : usd(v);

  static String number(num? v) => v == null ? '—' : (v is int ? _int.format(v) : _dec.format(v));

  /// وقت `*_at` (UTC) بتوقيت النادي.
  static DateTime clubTime(DateTime utc) {
    final loc = _location;
    return loc == null ? utc.toLocal() : tz.TZDateTime.from(utc.toUtc(), loc);
  }

  /// `2026-10-07` (لأيام `*_on` كما هي، أو لوقت `*_at` بعد تحويله).
  static String date(DateTime? d, {bool fromUtc = false}) {
    if (d == null) return '—';
    final v = fromUtc ? clubTime(d) : d;
    return '${v.year.toString().padLeft(4, '0')}-${_two(v.month)}-${_two(v.day)}';
  }

  /// `14:05` بتوقيت النادي.
  static String time(DateTime? utc) {
    if (utc == null) return '—';
    final v = clubTime(utc);
    return '${_two(v.hour)}:${_two(v.minute)}';
  }

  /// `2026-10-07 14:05` بتوقيت النادي.
  static String dateTime(DateTime? utc) => utc == null ? '—' : '${date(utc, fromUtc: true)} ${time(utc)}';

  /// "قبل 5 دقائق" من وقت الخادم الحالي.
  static String relative(DateTime? utc, {required DateTime now}) {
    if (utc == null) return '—';
    final d = now.difference(utc);
    if (d.inMinutes < 1) return 'الآن';
    if (d.inHours < 1) return 'قبل ${_count(d.inMinutes, 'دقيقة', 'دقيقتين', 'دقائق')}';
    if (d.inDays < 1) return 'قبل ${_count(d.inHours, 'ساعة', 'ساعتين', 'ساعات')}';
    if (d.inDays < 30) return 'قبل ${_count(d.inDays, 'يوم', 'يومين', 'أيام')}';
    return date(utc, fromUtc: true);
  }

  /// "يوم" / "يومين" / "3 أيام" / "11 يوماً" (عدد بالأرقام اللاتينية).
  static String days(int n) => _count(n, 'يوم', 'يومين', 'أيام', many: 'يوماً');

  /// التحية حسب وقت النادي: صباح الخير / مساء الخير.
  static String greeting(DateTime utc) => clubTime(utc).hour < 12 ? 'صباح الخير' : 'مساء الخير';

  static String _count(int n, String one, String two, String few, {String? many}) => switch (n) {
        1 => one,
        2 => two,
        >= 3 && <= 10 => '$n $few',
        _ => '$n ${many ?? one}',
      };

  static String _two(int n) => n.toString().padLeft(2, '0');
}
