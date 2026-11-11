import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tokens.dart';

/// ألوان الهوية للثيم الحالي: `UGColors.of(context).primary`
class UGColors extends ThemeExtension<UGColors> {
  const UGColors(this.p);
  final UGPalette p;

  static UGPalette of(BuildContext context) => (Theme.of(context).extension<UGColors>() ?? const UGColors(UGPalette.light)).p;
  static bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

  @override
  UGColors copyWith({UGPalette? p}) => UGColors(p ?? this.p);

  @override
  UGColors lerp(ThemeExtension<UGColors>? other, double t) => (other is UGColors && t >= .5) ? other : this;
}

/// نغمات الحالة: كل شارة = خلفية هادئة + نص، وليست لوناً وحده
enum UTone { success, warning, danger, info, accent, primary, neutral }

extension UToneColors on UTone {
  (Color bg, Color fg) colors(UGPalette c) => switch (this) {
        UTone.success => (c.successSoft, c.successInk),
        UTone.warning => (c.warningSoft, c.warningInk),
        UTone.danger => (c.dangerSoft, c.dangerInk),
        UTone.info => (c.infoSoft, c.infoInk),
        UTone.accent => (c.accentSoft, c.accentInk),
        UTone.primary => (c.primarySoft, c.primaryInk),
        UTone.neutral => (c.surfaceAlt, c.inkMuted),
      };
}

/// الأنماط النصية. Changa للعرض والأرقام، Readex Pro لكل الواجهة.
abstract final class UType {
  static const String display = 'Changa';
  static const String sans = 'ReadexPro';
  static const String package = 'ultragym_design';

  static TextStyle _s(String family, double size, double lh, double w, Color? color) => TextStyle(
        fontFamily: family,
        package: package,
        fontSize: size,
        height: lh / size,
        fontWeight: _weight(w),
        fontVariations: [FontVariation('wght', w)],
        color: color,
      );

  static FontWeight _weight(double w) => FontWeight.values[((w / 100).round() - 1).clamp(0, 8)];

  static TextStyle displayXl({Color? color}) => _s(display, 48, 56, 800, color);
  static TextStyle displayMd({Color? color}) => _s(display, 32, 42, 700, color);
  static TextStyle h1({Color? color}) => _s(sans, 24, 36, 600, color);
  static TextStyle h2({Color? color}) => _s(sans, 19, 30, 600, color);
  static TextStyle h3({Color? color}) => _s(sans, 16, 26, 600, color);
  static TextStyle stat({Color? color}) => _s(display, 30, 36, 700, color);
  static TextStyle bodyLg({Color? color}) => _s(sans, 15, 26, 400, color);
  static TextStyle body({Color? color}) => _s(sans, 14, 24, 400, color);
  static TextStyle label({Color? color}) => _s(sans, 12.5, 20, 500, color);
  static TextStyle caption({Color? color}) => _s(sans, 11.5, 18, 400, color);

  /// وزن مخصص لخط متغيّر: `UType.body().weight(600)`
  static TextStyle withWeight(TextStyle s, double w) => s.copyWith(fontWeight: _weight(w), fontVariations: [FontVariation('wght', w)]);
}

extension UTypeWeight on TextStyle {
  TextStyle weight(double w) => UType.withWeight(this, w);
}

/// الثيمان الكاملان
abstract final class UltraGymTheme {
  static ThemeData get light => _build(UGPalette.light, Brightness.light);
  static ThemeData get dark => _build(UGPalette.dark, Brightness.dark);

  static ThemeData _build(UGPalette c, Brightness b) {
    final scheme = ColorScheme(
      brightness: b,
      primary: c.primary,
      onPrimary: c.onPrimary,
      secondary: c.accent,
      onSecondary: c.onAccent,
      error: c.danger,
      onError: Colors.white,
      surface: c.surface,
      onSurface: c.ink,
      surfaceContainerHighest: c.surfaceAlt,
      outline: c.lineStrong,
      outlineVariant: c.line,
    );
    final base = UType.body(color: c.ink);
    final field = OutlineInputBorder(borderRadius: BorderRadius.circular(URadius.field), borderSide: BorderSide(color: c.line));
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
      iconTheme: IconThemeData(color: c.inkMuted, size: 20),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(URadius.sm)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.ink,
          side: BorderSide(color: c.line),
          minimumSize: const Size(0, USize.control),
          textStyle: UType.label().weight(600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(URadius.sm)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: c.primaryInk, textStyle: UType.label().weight(600))),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: c.ink, borderRadius: BorderRadius.circular(URadius.xs)),
        textStyle: UType.caption(color: c.bg),
        waitDuration: const Duration(milliseconds: 400),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.ink,
        contentTextStyle: UType.body(color: c.bg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(URadius.sm)),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.primary : Colors.transparent),
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
