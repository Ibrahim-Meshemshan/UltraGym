import '../bloc/app_form_cubit.dart';

/// تحقق محلي برسائل تقول المطلوب مباشرة. الخادم يتحقق دائماً (422).
abstract final class Validators {
  static FieldValidator required([String message = 'هذا الحقل مطلوب.']) =>
      (v) => (v == null || v.trim().isEmpty) ? message : null;

  static FieldValidator email({String message = 'اكتب بريداً إلكترونياً صحيحاً.', bool optional = true}) => (v) {
        final s = v?.trim() ?? '';
        if (s.isEmpty) return optional ? null : message;
        return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s) ? null : message;
      };

  /// موبايل بأي صيغة (`0944123456` أو `+963944123456`).
  static FieldValidator phone({String message = 'اكتب رقم موبايل صحيحاً.', bool optional = false}) => (v) {
        final s = (v ?? '').replaceAll(RegExp(r'[\s\-()]'), '');
        if (s.isEmpty) return optional ? null : 'اكتب رقم الموبايل.';
        return RegExp(r'^\+?\d{9,15}$').hasMatch(s) ? null : message;
      };

  static FieldValidator minLength(int n, [String? message]) =>
      (v) => (v ?? '').trim().length < n ? (message ?? 'اكتب $n أحرف على الأقل.') : null;

  /// كلمة سر جديدة بشرط الخادم: `minLength` أحرف على الأقل (افتراضياً 8، إعداد المنصة `password_min_length`)
  /// وفيها حرف ورقم.
  static FieldValidator newPassword({int minLength = 8}) => (v) {
        final s = v ?? '';
        if (s.isEmpty) return 'اكتب كلمة السر الجديدة.';
        if (s.length < minLength) return 'كلمة السر $minLength أحرف على الأقل.';
        if (!_letter.hasMatch(s) || !_digit.hasMatch(s)) return 'كلمة السر تحتاج حرفاً ورقماً على الأقل.';
        return null;
      };

  static final _letter = RegExp(r'\p{L}', unicode: true);
  static final _digit = RegExp(r'\d');

  /// تأكيد مطابق لحقل آخر: `Validators.matches(() => form.text('new_password').text)`.
  static FieldValidator matches(String Function() other, [String message = 'كلمتا السر غير متطابقتين.']) =>
      (v) => v == other() ? null : message;

  /// رقم موجب (مبلغ، عدد).
  static FieldValidator amount({String message = 'اكتب مبلغاً صحيحاً.', bool optional = false}) => (v) {
        final s = (v ?? '').replaceAll(',', '').trim();
        if (s.isEmpty) return optional ? null : 'اكتب المبلغ.';
        final n = num.tryParse(s);
        return (n == null || n < 0) ? message : null;
      };

  /// أول خطأ من عدة شروط.
  static FieldValidator all(List<FieldValidator> checks) => (v) {
        for (final c in checks) {
          final e = c(v);
          if (e != null) return e;
        }
        return null;
      };
}
