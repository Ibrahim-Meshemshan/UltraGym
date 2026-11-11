import 'package:flutter/material.dart';
import 'package:ultragym_design/ultragym_design.dart';

/// الوصول للألوان بالأدوار: `context.colors.primary`، وما يدخل بالـ ColorScheme بـ `context.scheme`.
/// لا `Color(0x...)` داخل أي واجهة.
extension AppColorsX on BuildContext {
  UGPalette get colors => UGColors.of(this);
  ColorScheme get scheme => Theme.of(this).colorScheme;
  bool get isDark => UGColors.isDark(this);
}
