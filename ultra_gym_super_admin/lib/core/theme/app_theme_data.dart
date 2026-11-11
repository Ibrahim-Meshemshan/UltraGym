import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ultragym_design/ultragym_design.dart';

import 'app_palette.dart';

/// ثيم Material من أدوار `AppPalette`. نفس بناء `UltraGymTheme` بالحزمة (الخطوط، الأحجام، الزوايا،
/// الحقول والأزرار) لكن الحزمة تبنيه بألوان الهوية فقط (`_build` خاصة)، فهنا يُعاد بالألوان الجديدة.
/// الملف نفسه بالمشاريع الأربعة.
abstract final class AppThemeData {
  static ThemeData get light => build(AppPalette.light.roles, Brightness.light);
  static ThemeData get dark => build(AppPalette.dark.roles, Brightness.dark);

  /// كما بالحزمة: انتظار التلميح وحجم الأيقونة الافتراضي.
  static const _tooltipWait = Duration(milliseconds: 400);
  static const _icon = 20.0;

  static ThemeData build(UGPalette c, Brightness b) {
    final scheme = ColorScheme(
      brightness: b,
      primary: c.primary,
      onPrimary: c.onPrimary,
      secondary: c.accent,
      onSecondary: c.onAccent,
      error: c.danger,
      onError: b == Brightness.dark ? c.onPrimary : AppPalette.onGradient,
      surface: c.surface,
      onSurface: c.ink,
      surfaceContainerHighest: c.surfaceAlt,
      outline: c.lineStrong,
      outlineVariant: c.line,
    );
    final base = UType.body(color: c.ink);
    final field = OutlineInputBorder(
      borderRadius: BorderRadius.circular(URadius.field),
      borderSide: BorderSide(color: c.line),
    );
    final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(URadius.sm));
    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.bg,
      fontFamily: UType.sans,
      extensions: [UGColors(c)],
      textTheme: TextTheme(
        displayLarge: UType.displayXl(color: c.ink),
        displayMedium: UType.displayMd(color: c.ink),
        headlineMedium: UType.h1(color: c.ink),
        titleLarge: UType.h2(color: c.ink),
        titleMedium: UType.h3(color: c.ink),
        bodyLarge: UType.bodyLg(color: c.ink),
        bodyMedium: base,
        labelLarge: UType.label(color: c.ink),
        bodySmall: UType.caption(color: c.inkMuted),
      ),
      dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: c.inkMuted, size: _icon),
      appBarTheme: AppBarTheme(
        backgroundColor: c.bg,
        foregroundColor: c.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: UType.h2(color: c.ink),
        systemOverlayStyle: b == Brightness.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        hintStyle: UType.body(color: c.inkFaint),
        labelStyle: UType.label(color: c.inkMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: USpace.s4, vertical: USpace.s3),
        border: field,
        enabledBorder: field,
        focusedBorder: field.copyWith(borderSide: BorderSide(color: c.primary, width: 2)),
        errorBorder: field.copyWith(borderSide: BorderSide(color: c.danger)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          minimumSize: const Size(0, USize.control),
          textStyle: UType.label().weight(600),
          shape: buttonShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.ink,
          side: BorderSide(color: c.line),
          minimumSize: const Size(0, USize.control),
          textStyle: UType.label().weight(600),
          shape: buttonShape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: c.primaryInk, textStyle: UType.label().weight(600)),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: c.ink, borderRadius: BorderRadius.circular(URadius.xs)),
        textStyle: UType.caption(color: c.bg),
        waitDuration: _tooltipWait,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.ink,
        contentTextStyle: UType.body(color: c.bg),
        behavior: SnackBarBehavior.floating,
        shape: buttonShape,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.primary : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(c.onPrimary),
        side: BorderSide(color: c.lineStrong, width: 1.5),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.onAccent : c.inkFaint),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.accent : c.surfaceAlt),
      ),
    );
  }
}
