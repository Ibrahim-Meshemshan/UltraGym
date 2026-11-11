/// يترجم رسائل التحقق الافتراضية الإنجليزية من لارافيل إلى عربية. الرسائل العربية تمر كما هي.
abstract final class ValidationTranslator {
  static final _arabic = RegExp(r'[؀-ۿ]');

  static final _rules = <(RegExp, String Function(Match))>[
    (RegExp(r'field is required|is required\.?$', caseSensitive: false), (_) => 'هذا الحقل مطلوب.'),
    (RegExp(r'must be a valid email', caseSensitive: false), (_) => 'اكتب بريداً إلكترونياً صحيحاً.'),
    (RegExp(r'has already been taken', caseSensitive: false), (_) => 'هذه القيمة مستخدمة مسبقاً. جرّب قيمة أخرى.'),
    (RegExp(r'confirmation does not match', caseSensitive: false), (_) => 'التأكيد غير مطابق.'),
    (RegExp(r'must be at least (\d+) characters', caseSensitive: false), (m) => 'يجب ألا يقل عن ${m[1]} أحرف.'),
    (
      RegExp(r'(?:may|must) not be greater than (\d+) characters', caseSensitive: false),
      (m) => 'يجب ألا يزيد عن ${m[1]} حرفاً.',
    ),
    (
      RegExp(r'(?:may|must) not be greater than (\d+) kilobytes', caseSensitive: false),
      (_) => 'حجم الملف أكبر من المسموح.',
    ),
    (RegExp(r'must be at least (\d+(?:\.\d+)?)\.?$', caseSensitive: false), (m) => 'يجب ألا تقل القيمة عن ${m[1]}.'),
    (RegExp(r'must be (?:a number|an integer|numeric)', caseSensitive: false), (_) => 'اكتب رقماً صحيحاً.'),
    (RegExp(r'(?:is not|must be) a valid date', caseSensitive: false), (_) => 'اكتب تاريخاً صحيحاً.'),
    (RegExp(r'must be an image|must be a file of type', caseSensitive: false), (_) => 'نوع الملف غير مسموح.'),
    (RegExp(r'selected .* is invalid', caseSensitive: false), (_) => 'القيمة المختارة غير صالحة.'),
    (RegExp(r'format is invalid', caseSensitive: false), (_) => 'الصيغة غير صحيحة.'),
  ];

  static String translate(String message) {
    if (_arabic.hasMatch(message)) return message;
    for (final (pattern, build) in _rules) {
      final m = pattern.firstMatch(message);
      if (m != null) return build(m);
    }
    return 'القيمة غير صالحة.';
  }
}
