import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

// أسلوب لوحة "Ignara" على الرئيسية (2026-11-11): الألوان صارت ألوان التطبيق كله (`AppPalette`)،
// وهنا ما بقي خاصاً بالرئيسية من شكلها: الزوايا الدائرية والمنحنى وأحجام الرسم.
/// زوايا التجربة ومنحناها (`--r-*`، `--ease`) ومدة "التنفس" الدائمة البطيئة.
abstract final class DemoShape {
  static const sm = 10.0, md = 14.0, lg = 20.0, xl = 26.0;
  static const lgAll = BorderRadius.all(Radius.circular(lg));
  static const mdAll = BorderRadius.all(Radius.circular(md));
  static const smAll = BorderRadius.all(Radius.circular(sm));
  static const ease = Cubic(.22, 1, .36, 1);
  static const breathe = Duration(milliseconds: 2200);

  /// عدد أنفاس حلقة "اليوم" ثم تسكن (حركة دائمة تشتّت وتُبقي الصفحة ترسم بلا توقف).
  static const breaths = 8;

  /// ارتفاع شريط التقدم بالبطاقة الرئيسية، ورسم الإيراد، وقطر رأس العمود.
  static const meter = 6.0;
  static const chart = 220.0;
  static const bead = 12.0;
}
