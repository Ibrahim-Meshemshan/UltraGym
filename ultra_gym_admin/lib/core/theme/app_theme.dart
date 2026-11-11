import 'package:flutter/material.dart';
import 'package:ultragym_design/ultragym_design.dart';

/// الثيمان من حزمة الهوية. أي تخصيص للمشروع يُضاف هنا بـ `copyWith` وليس بالشاشات.
abstract final class AppTheme {
  static ThemeData get light => _withPackageFonts(UltraGymTheme.light);
  static ThemeData get dark => _withPackageFonts(UltraGymTheme.dark);

  /// اسم خط الواجهة كما سجّلته الحزمة (`packages/ultragym_design/ReadexPro`).
  static final String _sans = UType.body().fontFamily!;

  /// الحزمة تضبط `fontFamily: 'ReadexPro'` بلا بادئة الحزمة، فأنماط Material التي لا تعرّفها
  /// (`headlineLarge` و `titleSmall` برأس منتقي التاريخ مثلاً) تطلب خطاً غير مسجّل فيظهر العربي مربعات بالويب.
  /// هنا يأخذ كل نمط بلا خط من الحزمة خط الواجهة المسجّل؛ أنماط الحزمة نفسها لا تتغير.
  static ThemeData _withPackageFonts(ThemeData t) {
    TextStyle? fix(TextStyle? s) =>
        s == null || (s.fontFamily?.startsWith('packages/') ?? false) ? s : s.copyWith(fontFamily: _sans);
    TextTheme all(TextTheme tt) => TextTheme(
      displayLarge: fix(tt.displayLarge),
      displayMedium: fix(tt.displayMedium),
      displaySmall: fix(tt.displaySmall),
      headlineLarge: fix(tt.headlineLarge),
      headlineMedium: fix(tt.headlineMedium),
      headlineSmall: fix(tt.headlineSmall),
      titleLarge: fix(tt.titleLarge),
      titleMedium: fix(tt.titleMedium),
      titleSmall: fix(tt.titleSmall),
      bodyLarge: fix(tt.bodyLarge),
      bodyMedium: fix(tt.bodyMedium),
      bodySmall: fix(tt.bodySmall),
      labelLarge: fix(tt.labelLarge),
      labelMedium: fix(tt.labelMedium),
      labelSmall: fix(tt.labelSmall),
    );
    return t.copyWith(
      textTheme: all(t.textTheme),
      primaryTextTheme: all(t.primaryTextTheme),
      // رأس منتقي التاريخ بـ headlineLarge (32) يقطع "١٠ نوفمبر" بالوضع العرضي لأن Readex أعرض من Roboto.
      datePickerTheme: t.datePickerTheme.copyWith(headerHeadlineStyle: UType.h1()),
    );
  }
}
