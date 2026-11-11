import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_gym_admin/core/theme/app_theme.dart';

void main() {
  test('every text style uses a font registered by the design package (no tofu on web)', () {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      for (final tt in [theme.textTheme, theme.primaryTextTheme]) {
        final styles = <String, TextStyle?>{
          'displayLarge': tt.displayLarge,
          'displaySmall': tt.displaySmall,
          'headlineLarge': tt.headlineLarge,
          'headlineSmall': tt.headlineSmall,
          'titleSmall': tt.titleSmall,
          'bodyMedium': tt.bodyMedium,
          'labelMedium': tt.labelMedium,
          'labelSmall': tt.labelSmall,
        };
        for (final e in styles.entries) {
          expect(e.value?.fontFamily, startsWith('packages/ultragym_design/'), reason: e.key);
        }
      }
      // أنماط الحزمة نفسها كما هي: العرض بـ Changa والباقي بـ Readex.
      expect(theme.textTheme.displayLarge!.fontFamily, 'packages/ultragym_design/Changa');
      expect(theme.textTheme.headlineLarge!.fontFamily, 'packages/ultragym_design/ReadexPro');
      expect(theme.datePickerTheme.headerHeadlineStyle!.fontFamily, 'packages/ultragym_design/ReadexPro');
      expect(theme.datePickerTheme.headerHeadlineStyle!.fontSize, 24);
    }
  });
}
