import 'package:flutter/material.dart';

import 'app_theme_data.dart';

/// الثيمان بألوان `AppPalette` (`AppThemeData`، بناء الحزمة نفسه). أي تخصيص للمشروع يُضاف هنا بـ `copyWith` وليس بالشاشات.
abstract final class AppTheme {
  static ThemeData get light => AppThemeData.light;
  static ThemeData get dark => AppThemeData.dark;
}
