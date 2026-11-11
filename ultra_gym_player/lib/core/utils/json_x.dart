/// كائن JSON من الخادم.
typedef Json = Map<String, dynamic>;

/// قراءة آمنة من JSON: غياب حقل أو تغيّر نوعه لا يرمي استثناء.
extension JsonX on Json {
  int intv(String key, [int fallback = 0]) => intOrNull(key) ?? fallback;

  int? intOrNull(String key) => switch (this[key]) {
        final int v => v,
        final num v => v.toInt(),
        final String v => int.tryParse(v) ?? double.tryParse(v)?.toInt(),
        _ => null,
      };

  double dbl(String key, [double fallback = 0]) => dblOrNull(key) ?? fallback;

  double? dblOrNull(String key) => switch (this[key]) {
        final num v => v.toDouble(),
        final String v => double.tryParse(v),
        _ => null,
      };

  String str(String key, [String fallback = '']) => strOrNull(key) ?? fallback;

  String? strOrNull(String key) => switch (this[key]) {
        null => null,
        final String v => v,
        final Object v => v.toString(),
      };

  bool flag(String key, [bool fallback = false]) => switch (this[key]) {
        final bool v => v,
        final num v => v != 0,
        final String v => v == '1' || v.toLowerCase() == 'true',
        _ => fallback,
      };

  /// وقت `*_at` (ISO 8601 UTC). يبقى UTC: التحويل لتوقيت النادي عند العرض بـ `Formatters`.
  DateTime? date(String key) {
    final v = this[key];
    return v is String ? DateTime.tryParse(v)?.toUtc() : null;
  }

  /// يوم `*_on` أو `business_date` (`YYYY-MM-DD`) كما هو بلا تحويل توقيت.
  DateTime? day(String key) {
    final v = this[key];
    if (v is! String || v.length < 10) return null;
    final d = DateTime.tryParse(v.substring(0, 10));
    return d == null ? null : DateTime(d.year, d.month, d.day);
  }

  Json obj(String key) => asJson(this[key]);

  Json? objOrNull(String key) => this[key] is Map ? asJson(this[key]) : null;

  List<String> strList(String key) => switch (this[key]) {
        final List<dynamic> v => [for (final e in v) if (e != null) e.toString()],
        _ => const [],
      };

  List<int> intList(String key) => switch (this[key]) {
        final List<dynamic> v => [for (final e in v) if (e is num) e.toInt() else if (int.tryParse('$e') != null) int.parse('$e')],
        _ => const [],
      };

  List<T> list<T>(String key, T Function(Json json) fromJson) => asList(this[key], fromJson);
}

/// أي قيمة ككائن JSON (أو كائن فارغ).
Json asJson(Object? raw) => raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};

/// أي قيمة كقائمة موديلات؛ العناصر غير الصالحة تُتجاهل.
List<T> asList<T>(Object? raw, T Function(Json json) fromJson) =>
    raw is List ? [for (final e in raw) if (e is Map) fromJson(asJson(e))] : <T>[];
