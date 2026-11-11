import 'package:flutter/material.dart';
import 'package:ultragym_design/ultragym_design.dart';

/// الثيمان من حزمة الهوية. أي تخصيص للمشروع يُضاف هنا بـ `copyWith` وليس بالشاشات.
abstract final class AppTheme {
  static ThemeData get light => UltraGymTheme.light;
  static ThemeData get dark => UltraGymTheme.dark;
}
