import 'package:flutter/widgets.dart';
import 'package:ultragym_design/ultragym_design.dart';

/// الخطوط: Changa للعرض والأرقام الكبيرة فقط، و Readex Pro لكل الواجهة. الأنماط من `UType`.
abstract final class AppFonts {
  static const display = UType.display;
  static const sans = UType.sans;
  static const package = UType.package;
}

/// المسافات على شبكة 4 (من حزمة الهوية). لا أرقام مسافات عشوائية بالواجهة.
abstract final class AppSpace {
  static const s1 = USpace.s1;
  static const s2 = USpace.s2;
  static const s3 = USpace.s3;
  static const s4 = USpace.s4;
  static const s5 = USpace.s5;
  static const s6 = USpace.s6;
  static const s8 = USpace.s8;
  static const s10 = USpace.s10;
  static const s12 = USpace.s12;
  static const s16 = USpace.s16;

  /// فراغات جاهزة تعمل داخل Row و Column.
  static const gap1 = SizedBox(width: USpace.s1, height: USpace.s1);
  static const gap2 = SizedBox(width: USpace.s2, height: USpace.s2);
  static const gap3 = SizedBox(width: USpace.s3, height: USpace.s3);
  static const gap4 = SizedBox(width: USpace.s4, height: USpace.s4);
  static const gap5 = SizedBox(width: USpace.s5, height: USpace.s5);
  static const gap6 = SizedBox(width: USpace.s6, height: USpace.s6);
  static const gap8 = SizedBox(width: USpace.s8, height: USpace.s8);
}

/// الزوايا. البطاقة شكلها توقيعي (`CutCard` / `CutCardBorder`)، لا تصنع زوايا بطاقة يدوياً.
abstract final class AppRadius {
  static const xs = URadius.xs;
  static const sm = URadius.sm;
  static const field = URadius.field;
  static const card = URadius.card;
  static const hero = URadius.hero;
  static const full = URadius.full;

  static const smAll = BorderRadius.all(Radius.circular(URadius.sm));
  static const fieldAll = BorderRadius.all(Radius.circular(URadius.field));
  static const cardAll = BorderRadius.all(Radius.circular(URadius.card));
  static const fullAll = BorderRadius.all(Radius.circular(URadius.full));
}

/// المقاسات الثابتة.
abstract final class AppSize {
  static const controlSm = USize.controlSm;
  static const control = USize.control;
  static const controlLg = USize.controlLg;
  static const topBar = USize.topBar;
  static const sidebar = USize.sidebar;
  static const sidebarCollapsed = USize.sidebarCollapsed;
  static const bottomNav = USize.bottomNav;
  static const tableRow = 52.0;
  static const maxContent = UBreakpoints.desktop;

  /// أصغر هدف ضغط باللمس.
  static const minTap = 48.0;

  /// عرض العمود بشبكة البطاقات (الأعمدة = العرض ÷ 230).
  static const gridItem = 230.0;
}

/// مدد الحركة ومنحنياتها. كل حركة تفحص `AppMotion.reduced(context)`.
abstract final class AppMotion {
  static const instant = UMotionValues.press;
  static const fast = UMotionValues.fast;
  static const normal = UMotionValues.base;
  static const slow = UMotionValues.slow;
  static const entrance = UMotionValues.entrance;
  static const entranceStep = UMotionValues.entranceStep;

  static const curve = UMotionValues.standard;
  static const emphasized = UMotionValues.emphasized;
  static const exit = UMotionValues.exit;

  /// "تقليل الحركة" من إعدادات النظام.
  static bool reduced(BuildContext context) => UMotion.reduced(context);

  /// المدة نفسها، أو صفر مع "تقليل الحركة".
  static Duration of(BuildContext context, Duration d) => reduced(context) ? Duration.zero : d;
}
