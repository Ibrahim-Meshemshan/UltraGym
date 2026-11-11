import 'package:flutter/material.dart';
import 'package:ultragym_design/ultragym_design.dart';

/// ألوان التطبيق (منذ 2026-11-11، بطلب صاحب المشروع): ألوان لوحة "Ignara" الدافئة بدل ألوان الهوية.
/// الحزمة لا تُعدَّل: `AppTheme` يبني الثيم من `roles` (أدوار `UGPalette`)، فكل ويدجت يقرأ
/// `context.colors` يأخذها. الحقول الأخرى قيم الديمو كما هي (بعضها شفاف) للعناصر الخاصة: التدرج،
/// التوهج، الظلال، و"البئر". `roles` نسخ معتمة منها (الشفاف مدموج فوق البطاقة) لأن ويدجتس الحزمة
/// تتوقع ألواناً معتمة. الزخارف (`ornaments`) بالبرتقالي والعنبري بدل البرتقالي والأخضر.
/// الملف نفسه بالمشاريع الأربعة: أي تعديل هنا يُنسخ للباقي.
class AppPalette {
  const AppPalette._({
    required this.bg,
    required this.side,
    required this.card,
    required this.card2,
    required this.card3,
    required this.line,
    required this.line2,
    required this.well,
    required this.ink,
    required this.ink2,
    required this.muted,
    required this.data,
    required this.data2,
    required this.accent,
    required this.accentHi,
    required this.accentFrom,
    required this.accentTo,
    required this.accentSoft,
    required this.accentText,
    required this.accentInk,
    required this.accentGlow,
    required this.amber,
    required this.shadow,
    required this.shadowLg,
    required this.roles,
    required this.ornaments,
  });

  final Color bg, side, card, card2, card3, line, line2, well, ink, ink2, muted, data, data2;
  final Color accent, accentHi, accentFrom, accentTo, accentSoft, accentText, accentInk, accentGlow, amber;
  final List<BoxShadow> shadow, shadowLg;

  /// الأدوار بأسماء الهوية (معتمة)، ومنها يُبنى الثيم كله.
  final UGPalette roles;

  /// ألوان الزخارف المرسومة (النمط، الصفيحة، المؤقت، النبض، المسار) على أرضية هذا الوضع.
  final UOrnColors ornaments;

  /// النص والأيقونات فوق التدرج البرتقالي (بالوضعين).
  static const onGradient = Color(0xFFFFFFFF);

  static const light = AppPalette._(
    bg: Color(0xFFE7E6E4),
    side: Color(0xFFF2F1EF),
    card: Color(0xFFF7F6F4),
    card2: Color(0xFFEFEEEB),
    card3: Color(0xFFE3E1DE),
    line: Color(0x14141418),
    line2: Color(0x26141418),
    well: Color(0x0D141418),
    ink: Color(0xFF1D1E21),
    ink2: Color(0xFF3A3B40),
    muted: Color(0xFF65666C),
    data: Color(0xFF9A9CA2),
    data2: Color(0xFFC9CACD),
    accent: Color(0xFFEE5230),
    accentHi: Color(0xFFF4633C),
    accentFrom: Color(0xFFFF7B3A),
    accentTo: Color(0xFFDE3424),
    accentSoft: Color(0x24EE5230),
    accentText: Color(0xFFB5361B),
    accentInk: Color(0xFF1F0A04),
    accentGlow: Color(0x73E43C24),
    amber: Color(0xFFE9952E),
    shadow: [
      BoxShadow(color: Color(0x0D1E1814), blurRadius: 2, offset: Offset(0, 1)),
      BoxShadow(color: Color(0x521E1814), blurRadius: 34, spreadRadius: -22, offset: Offset(0, 16)),
    ],
    shadowLg: [
      BoxShadow(color: Color(0x141E1814), blurRadius: 6, offset: Offset(0, 2)),
      BoxShadow(color: Color(0x661E1814), blurRadius: 60, spreadRadius: -24, offset: Offset(0, 30)),
    ],
    roles: UGPalette(
      bg: Color(0xFFE7E6E4),
      surface: Color(0xFFF7F6F4),
      surfaceAlt: Color(0xFFEFEEEB),
      line: Color(0xFFE5E4E3),
      lineStrong: Color(0xFFD5D4D3),
      ink: Color(0xFF1D1E21),
      inkMuted: Color(0xFF65666C),
      inkFaint: Color(0xFF9A9CA2),
      sidebar: Color(0xFFF2F1EF),
      sidebarInk: Color(0xFF3A3B40),
      hero: Color(0xFF26282C),
      primary: Color(0xFFEE5230),
      primaryHover: Color(0xFFF4633C),
      onPrimary: Color(0xFF1F0A04),
      primaryInk: Color(0xFFB5361B),
      primarySoft: Color(0xFFF6DFD8),
      accent: Color(0xFFE9952E),
      onAccent: Color(0xFF1F0A04),
      accentInk: Color(0xFF8A5807),
      accentSoft: Color(0xFFF4E5D0),
      success: Color(0xFF1E8250),
      successSoft: Color(0xFFDBE7DF),
      successInk: Color(0xFF1D7446),
      warning: Color(0xFFD7961E),
      warningSoft: Color(0xFFF1E5CD),
      warningInk: Color(0xFF8A5807),
      danger: Color(0xFFCD283C),
      dangerSoft: Color(0xFFF2DFE0),
      dangerInk: Color(0xFFB3222F),
      info: Color(0xFF2A5C99),
      infoSoft: Color(0xFFDEE3E9),
      infoInk: Color(0xFF2A5C99),
      focus: Color(0xFF1D1E21),
    ),
    ornaments: UOrnColors(ink: Color(0xFF1D1E21), a: Color(0xFFEE5230), b: Color(0xFFE9952E), m: Color(0xFFC9CACD)),
  );

  static const dark = AppPalette._(
    bg: Color(0xFF26282C),
    side: Color(0xFF1F2124),
    card: Color(0xFF2F3135),
    card2: Color(0xFF36383D),
    card3: Color(0xFF3F4147),
    line: Color(0x0FFFFFFF),
    line2: Color(0x1FFFFFFF),
    well: Color(0x0AFFFFFF),
    ink: Color(0xFFF3F1ED),
    ink2: Color(0xFFD4D2CE),
    muted: Color(0xFFA4A4A9),
    data: Color(0xFF707379),
    data2: Color(0xFF55585E),
    accent: Color(0xFFF0552F),
    accentHi: Color(0xFFF66A40),
    accentFrom: Color(0xFFFF7C3C),
    accentTo: Color(0xFFE2372A),
    accentSoft: Color(0x2BF0552F),
    accentText: Color(0xFFFF8C62),
    accentInk: Color(0xFF1F0A04),
    accentGlow: Color(0x6BF04628),
    amber: Color(0xFFF0A040),
    shadow: [
      BoxShadow(color: Color(0x40000000), blurRadius: 1, offset: Offset(0, 1)),
      BoxShadow(color: Color(0xBF000000), blurRadius: 40, spreadRadius: -22, offset: Offset(0, 22)),
    ],
    shadowLg: [
      BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 2)),
      BoxShadow(color: Color(0xE6000000), blurRadius: 70, spreadRadius: -24, offset: Offset(0, 34)),
    ],
    roles: UGPalette(
      bg: Color(0xFF26282C),
      surface: Color(0xFF2F3135),
      surfaceAlt: Color(0xFF36383D),
      line: Color(0xFF3B3D41),
      lineStrong: Color(0xFF484A4E),
      ink: Color(0xFFF3F1ED),
      inkMuted: Color(0xFFA4A4A9),
      inkFaint: Color(0xFF707379),
      sidebar: Color(0xFF1F2124),
      sidebarInk: Color(0xFFD4D2CE),
      hero: Color(0xFF1F2124),
      primary: Color(0xFFF0552F),
      primaryHover: Color(0xFFF66A40),
      onPrimary: Color(0xFF1F0A04),
      primaryInk: Color(0xFFFF8C62),
      primarySoft: Color(0xFF503734),
      accent: Color(0xFFF0A040),
      onAccent: Color(0xFF1F0A04),
      accentInk: Color(0xFFF0A040),
      accentSoft: Color(0xFF4C4237),
      success: Color(0xFF74D6A0),
      successSoft: Color(0xFF384643),
      successInk: Color(0xFF74D6A0),
      warning: Color(0xFFF4C46E),
      warningSoft: Color(0xFF4B463D),
      warningInk: Color(0xFFF4C46E),
      danger: Color(0xFFFF8A92),
      dangerSoft: Color(0xFF4A3D41),
      dangerInk: Color(0xFFFF8A92),
      info: Color(0xFF94BCF2),
      infoSoft: Color(0xFF3C434D),
      infoInk: Color(0xFF94BCF2),
      focus: Color(0xFFF3F1ED),
    ),
    ornaments: UOrnColors(ink: Color(0xFFF3F1ED), a: Color(0xFFF0552F), b: Color(0xFFF0A040), m: Color(0xFF55585E)),
  );

  static AppPalette of(BuildContext context) => UGColors.isDark(context) ? dark : light;

  /// التدرج البرتقالي (`linear-gradient(140deg, from, accent 50%, to)`) للبطاقة الرئيسية والزر الأساسي.
  LinearGradient get gradient =>
      LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [accentFrom, accent, accentTo]);

  /// توهج تحت ما عليه التدرج (`0 12px 24px -12px glow`).
  List<BoxShadow> get glow => [
    BoxShadow(color: accentGlow, blurRadius: 24, spreadRadius: -12, offset: const Offset(0, 12)),
  ];
}
