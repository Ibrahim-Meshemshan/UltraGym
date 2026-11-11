// مولّد بـ tools/build-flutter.js من studio/engine.js · لا تعدّله يدوياً
// القيم نفسها في tokens/tokens.json
import 'package:flutter/animation.dart';

/// ألوان الهوية بثيم واحد. استخدم UGColors.of(context) بدل هذه القيم مباشرة.
class UGPalette {
  const UGPalette({
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.line,
    required this.lineStrong,
    required this.ink,
    required this.inkMuted,
    required this.inkFaint,
    required this.sidebar,
    required this.sidebarInk,
    required this.hero,
    required this.primary,
    required this.primaryHover,
    required this.onPrimary,
    required this.primaryInk,
    required this.primarySoft,
    required this.accent,
    required this.onAccent,
    required this.accentInk,
    required this.accentSoft,
    required this.success,
    required this.successSoft,
    required this.successInk,
    required this.warning,
    required this.warningSoft,
    required this.warningInk,
    required this.danger,
    required this.dangerSoft,
    required this.dangerInk,
    required this.info,
    required this.infoSoft,
    required this.infoInk,
    required this.focus,
  });

  final Color bg;
  final Color surface;
  final Color surfaceAlt;
  final Color line;
  final Color lineStrong;
  final Color ink;
  final Color inkMuted;
  final Color inkFaint;
  final Color sidebar;
  final Color sidebarInk;
  final Color hero;
  final Color primary;
  final Color primaryHover;
  final Color onPrimary;
  final Color primaryInk;
  final Color primarySoft;
  final Color accent;
  final Color onAccent;
  final Color accentInk;
  final Color accentSoft;
  final Color success;
  final Color successSoft;
  final Color successInk;
  final Color warning;
  final Color warningSoft;
  final Color warningInk;
  final Color danger;
  final Color dangerSoft;
  final Color dangerInk;
  final Color info;
  final Color infoSoft;
  final Color infoInk;
  final Color focus;

  static const light = UGPalette(
    bg: Color(0xFFF5F5F2),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFEDEDE8),
    line: Color(0xFFE0E0DA),
    lineStrong: Color(0xFFC9C9C0),
    ink: Color(0xFF1A1A17),
    inkMuted: Color(0xFF5F5F57),
    inkFaint: Color(0xFF8A8A80),
    sidebar: Color(0xFF1A1A17),
    sidebarInk: Color(0xFFC9C9C0),
    hero: Color(0xFF1A1A17),
    primary: Color(0xFFFF5A1F),
    primaryHover: Color(0xFFF04A0E),
    onPrimary: Color(0xFF1A1A17),
    primaryInk: Color(0xFFB53D0A),
    primarySoft: Color(0xFFFFE8DC),
    accent: Color(0xFFC8F03C),
    onAccent: Color(0xFF1A1A17),
    accentInk: Color(0xFF4F7A00),
    accentSoft: Color(0xFFEEF8D2),
    success: Color(0xFF2E9E6B),
    successSoft: Color(0xFFE3F5EC),
    successInk: Color(0xFF0D7350),
    warning: Color(0xFFE0A21B),
    warningSoft: Color(0xFFFFF1D1),
    warningInk: Color(0xFF8A5800),
    danger: Color(0xFFD6335A),
    dangerSoft: Color(0xFFFDE6EC),
    dangerInk: Color(0xFFB81F45),
    info: Color(0xFF3D6BF2),
    infoSoft: Color(0xFFE6ECFF),
    infoInk: Color(0xFF2A50C8),
    focus: Color(0xFF1A1A17),
  );

  static const dark = UGPalette(
    bg: Color(0xFF121210),
    surface: Color(0xFF1B1B18),
    surfaceAlt: Color(0xFF24241F),
    line: Color(0xFF2E2E29),
    lineStrong: Color(0xFF45453D),
    ink: Color(0xFFF3F3EE),
    inkMuted: Color(0xFFA9A99F),
    inkFaint: Color(0xFF7A7A70),
    sidebar: Color(0xFF0B0B0A),
    sidebarInk: Color(0xFFA9A99F),
    hero: Color(0xFF1B1B18),
    primary: Color(0xFFFF6A30),
    primaryHover: Color(0xFFFF7D4A),
    onPrimary: Color(0xFF1A1A17),
    primaryInk: Color(0xFFFF8E5E),
    primarySoft: Color(0xFF3A1C10),
    accent: Color(0xFFC8F03C),
    onAccent: Color(0xFF1A1A17),
    accentInk: Color(0xFFC8F03C),
    accentSoft: Color(0xFF2C3311),
    success: Color(0xFF3DD68C),
    successSoft: Color(0xFF163126),
    successInk: Color(0xFF3DD68C),
    warning: Color(0xFFF5B642),
    warningSoft: Color(0xFF33280F),
    warningInk: Color(0xFFF5B642),
    danger: Color(0xFFFF7A95),
    dangerSoft: Color(0xFF3A1520),
    dangerInk: Color(0xFFFF7A95),
    info: Color(0xFF8AA9FF),
    infoSoft: Color(0xFF1C2747),
    infoInk: Color(0xFF8AA9FF),
    focus: Color(0xFFC8F03C),
  );
}

/// ألوان العلامة الثابتة (للشعار والزخارف والسوشال)
abstract final class UGBrand {
  static const orange = Color(0xFFFF5A1F);
  static const orangeHi = Color(0xFFFF6A30);
  static const orangeDeep = Color(0xFFB53D0A);
  static const charcoal = Color(0xFF1A1A17);
  static const carbon = Color(0xFF121210);
  static const bone = Color(0xFFF5F5F2);
  static const volt = Color(0xFFC8F03C);
  static const moss = Color(0xFF4F7A00);
  static const white = Color(0xFFFFFFFF);
  static const chalk = Color(0xFFF3F3EE);
}

/// المسافات على شبكة 4
abstract final class USpace {
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s8 = 32;
  static const double s10 = 40;
  static const double s12 = 48;
  static const double s16 = 64;
}

/// الزوايا. البطاقة: زوايا 16 مع زاوية علوية مشطوفة 18 (CutCardBorder)
abstract final class URadius {
  static const double xs = 6;
  static const double sm = 10;
  static const double field = 12;
  static const double card = 16;
  static const double cut = 18;
  static const double hero = 22;
  static const double full = 999;

  /// ميلان الهوية: الشارات والزر الأساسي وأعمدة الرسوم مائلة للأمام
  static const double slantDeg = 10;
}

/// مقاسات العناصر الثابتة
abstract final class USize {
  static const double controlSm = 34;
  static const double control = 42;
  static const double controlLg = 50;
  static const double topBar = 64;
  static const double sidebar = 264;
  static const double sidebarCollapsed = 76;
  static const double bottomNav = 68;
}

abstract final class UBreakpoints {
  static const double mobile = 600;
  static const double tablet = 1024;
  static const double desktop = 1320;
}

/// شفافيات الزخارف بأماكنها
abstract final class UOrnament {
  static const double heroPattern = 0.1;
  static const double heroPlate = 0.3;
  static const double loginPattern = 0.12;
  static const double loginPlate = 0.32;
  static const double emptyDial = 1;
  static const double appHeaderPattern = 0.1;
}

/// مدد ومنحنيات الحركة
abstract final class UMotionValues {
  static const Curve standard = Cubic(0.25, 1, 0.3, 1);
  static const Curve emphasized = Cubic(0.7, 0, 0.2, 1);
  static const Curve exit = Cubic(0.4, 0, 1, 1);
  static const Duration press = Duration(milliseconds: 90);
  static const Duration fast = Duration(milliseconds: 140);
  static const Duration base = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 380);
  static const Duration long = Duration(milliseconds: 460);
  static const Duration entrance = Duration(milliseconds: 520);
  static const Duration entranceStep = Duration(milliseconds: 60);
  static const Duration countUp = Duration(milliseconds: 900);
  static const Duration bars = Duration(milliseconds: 800);
  static const Duration barStep = Duration(milliseconds: 70);
  static const Duration shine = Duration(milliseconds: 700);
  static const Duration ping = Duration(milliseconds: 1600);
  static const Duration speedPattern = Duration(milliseconds: 30000);
  static const Duration plateSpin = Duration(milliseconds: 40000);
  static const Duration dialSweep = Duration(milliseconds: 8000);
  static const Duration pulse = Duration(milliseconds: 1600);
}
