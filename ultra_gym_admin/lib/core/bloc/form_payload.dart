import '../utils/json_x.dart';

/// تحويل قيم النموذج (بمفاتيح لارافيل المنقّطة) لجسم الطلب المتداخل.
abstract final class FormPayload {
  /// `{'owner.phone': x, 'payments.0.amount': 5}` ← `{'owner': {'phone': x}, 'payments': [{'amount': 5}]}`.
  static Json nest(Json flat) {
    final root = <String, dynamic>{};
    for (final e in flat.entries) {
      final parts = e.key.split('.');
      var node = root;
      for (var i = 0; i < parts.length - 1; i++) {
        node = (node[parts[i]] ??= <String, dynamic>{}) as Map<String, dynamic>;
      }
      node[parts.last] = e.value;
    }
    return _lists(root) as Json;
  }

  /// كائن كل مفاتيحه أرقام يصبح قائمة مرتبة.
  static Object? _lists(Object? v) {
    if (v is! Map<String, dynamic>) return v;
    final mapped = {for (final e in v.entries) e.key: _lists(e.value)};
    final numeric = mapped.isNotEmpty && mapped.keys.every((k) => int.tryParse(k) != null);
    if (!numeric) return mapped;
    final keys = mapped.keys.map(int.parse).toList()..sort();
    return [for (final k in keys) mapped['$k']];
  }

  /// قيمة حقل جاهزة للإرسال: التواريخ `2026-10-07` (أو ISO كامل لحقول `dateTimes`)، والنص الفارغ = null.
  static Object? encode(String name, Object? value, Set<String> dateTimes) => switch (value) {
    final DateTime d when dateTimes.contains(name) => d.toUtc().toIso8601String(),
    final DateTime d => '${d.year.toString().padLeft(4, '0')}-${_two(d.month)}-${_two(d.day)}',
    final String s when s.trim().isEmpty => null,
    final String s => s.trim(),
    _ => value,
  };

  static String _two(int n) => n.toString().padLeft(2, '0');
}
