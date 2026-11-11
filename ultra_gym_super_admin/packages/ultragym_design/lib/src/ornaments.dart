import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'motion.dart';
import 'theme.dart';
import 'tokens.dart';

/// العناصر الحركية: مرسومة بالكود، تتلون بالثيم، وتقف مع "تقليل الحركة".
/// مكانها اللحظات الخاصة فقط: الدخول، البانر، رأس التطبيقات، الحالات الفارغة، النجاح.

/// ألوان الزخرفة على أرضية معينة
class UOrnColors {
  const UOrnColors({required this.ink, required this.a, required this.b, required this.m});
  final Color ink, a, b, m;

  static const light = UOrnColors(ink: Color(0xFF1A1A17), a: Color(0xFFFF5A1F), b: Color(0xFF8DB51A), m: Color(0xFFCFCFC6));
  static const dark = UOrnColors(ink: Color(0xFFF3F3EE), a: Color(0xFFFF6A30), b: Color(0xFFC8F03C), m: Color(0xFF45453D));

  static UOrnColors of(BuildContext context, {bool onDark = false}) => onDark || UGColors.isDark(context) ? dark : light;
}

Path _para(double x, double y, double l, double h, [double sk = .36]) => Path()
  ..moveTo(x, y)
  ..lineTo(x + l, y)
  ..lineTo(x + l - h * sk, y + h)
  ..lineTo(x - h * sk, y + h)
  ..close();

enum UPattern { speed, plates, grid }

class _PatternPainter extends CustomPainter {
  _PatternPainter(this.kind, this.c, this.shift);
  final UPattern kind;
  final UOrnColors c;
  final double shift;

  @override
  void paint(Canvas canvas, Size size) {
    final tile = switch (kind) { UPattern.speed => 120.0, UPattern.plates => 140.0, UPattern.grid => 60.0 };
    final fa = Paint()..color = c.a;
    final fm = Paint()..color = c.m;
    final sm = Paint()
      ..color = c.m
      ..style = PaintingStyle.stroke;
    final dx = -(shift * tile) % tile;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (double y = -tile; y < size.height + tile; y += tile) {
      for (double x = dx - tile; x < size.width + tile; x += tile) {
        canvas.save();
        canvas.translate(x, y);
        switch (kind) {
          case UPattern.speed:
            canvas.drawPath(_para(22, 20, 40, 7), fa);
            canvas.drawPath(_para(74, 20, 20, 7), fm);
            canvas.drawPath(_para(46, 56, 54, 7), fm);
            canvas.drawPath(_para(18, 92, 26, 7), fm);
            canvas.drawPath(_para(58, 92, 34, 7), fa);
          case UPattern.plates:
            for (final (p, hub) in [(const Offset(35, 35), c.a), (const Offset(105, 105), c.b)]) {
              canvas.drawCircle(p, 26, sm..strokeWidth = 3);
              canvas.drawCircle(p, 17, sm..strokeWidth = 1.5);
              canvas.drawCircle(p, 6, Paint()..color = hub);
            }
          case UPattern.grid:
            canvas.drawCircle(const Offset(15, 15), 2, fm);
            canvas.drawCircle(const Offset(45, 45), 2, fm);
        }
        canvas.restore();
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PatternPainter o) => o.shift != shift || o.c != c;
}

/// نقش يزحف ببطء (البانر، رأس التطبيقات، شاشة الدخول)
class OrnamentPattern extends StatefulWidget {
  const OrnamentPattern({super.key, this.kind = UPattern.speed, this.opacity = UOrnament.heroPattern, this.colors, this.period = UMotionValues.speedPattern});
  final UPattern kind;
  final double opacity;
  final UOrnColors? colors;
  final Duration period;

  @override
  State<OrnamentPattern> createState() => _OrnamentPatternState();
}

class _OrnamentPatternState extends State<OrnamentPattern> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.period);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    UMotion.reduced(context) ? _c.stop() : _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors ?? UOrnColors.of(context);
    return IgnorePointer(
      child: Opacity(
        opacity: widget.opacity,
        child: AnimatedBuilder(animation: _c, builder: (_, __) => CustomPaint(painter: _PatternPainter(widget.kind, c, _c.value), size: Size.infinite)),
      ),
    );
  }
}

void _ticks(Canvas canvas, Offset c, int n, double r1, double r2, Paint p, {int every = 0, double r1b = 0, Paint? pb}) {
  for (var i = 0; i < n; i++) {
    final big = every > 0 && i % every == 0;
    final a = i / n * 2 * math.pi - math.pi / 2;
    final ra = big ? r1b : r1;
    canvas.drawLine(c + Offset(math.cos(a), math.sin(a)) * ra, c + Offset(math.cos(a), math.sin(a)) * r2, big ? (pb ?? p) : p);
  }
}

class _PlatePainter extends CustomPainter {
  _PlatePainter(this.c);
  final UOrnColors c;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / 240;
    canvas.scale(s);
    const o = Offset(120, 120);
    Paint st(Color col, double w) => Paint()
      ..color = col
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(o, 114, st(c.ink, 3));
    _ticks(canvas, o, 72, 104, 110, st(c.m, 1.6), every: 6, r1b: 98, pb: st(c.a, 2.6));
    canvas.drawCircle(o, 94, st(c.m, 1.5));
    for (var i = 0; i < 8; i++) {
      final a = i / 8 * 2 * math.pi + math.pi / 8;
      canvas.drawCircle(o + Offset(math.cos(a), math.sin(a)) * 76, 7, st(c.m, 2));
    }
    canvas.drawCircle(o, 52, st(c.ink, 2.4));
    canvas.drawCircle(o, 40, Paint()..color = c.a.withValues(alpha: .16));
    canvas.drawCircle(o, 18, Paint()..color = c.a);
    canvas.drawCircle(o, 7.5, st(c.ink, 2));
  }

  @override
  bool shouldRepaint(_PlatePainter o) => o.c != c;
}

/// قرص الأوزان: يدور ببطء (البانر، الدخول، رأس التطبيقات)
class PlateRing extends StatelessWidget {
  const PlateRing({super.key, this.size = 240, this.colors, this.spin = true});
  final double size;
  final UOrnColors? colors;
  final bool spin;

  @override
  Widget build(BuildContext context) {
    final w = SizedBox.square(dimension: size, child: CustomPaint(painter: _PlatePainter(colors ?? UOrnColors.of(context))));
    return IgnorePointer(child: spin ? SlowSpin(child: w) : w);
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter(this.c, this.t);
  final UOrnColors c;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / 252;
    canvas.scale(s);
    const o = Offset(120, 132);
    Paint st(Color col, double w) => Paint()
      ..color = col
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round;
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(110, 0, 20, 10), const Radius.circular(3)), Paint()..color = c.ink);
    canvas.drawRect(const Rect.fromLTWH(116, 8, 8, 8), Paint()..color = c.ink);
    canvas.drawCircle(o, 112, st(c.m, 2));
    _ticks(canvas, o, 60, 98, 106, st(c.m, 1.5), every: 5, r1b: 90, pb: st(c.ink, 2.6));
    final sweep = (0.25 + 0.7 * t) * 2 * math.pi;
    canvas.drawArc(Rect.fromCircle(center: o, radius: 76), -math.pi / 2, sweep, false, st(c.b, 12));
    final a = -math.pi / 2 + sweep;
    canvas.drawLine(o, o + Offset(math.cos(a), math.sin(a)) * 56, st(c.ink, 3.5));
    canvas.drawCircle(o, 8, Paint()..color = c.a);
  }

  @override
  bool shouldRepaint(_DialPainter o) => o.t != t || o.c != c;
}

/// المؤقت: قوس يتقدم ببطء (الحالات الفارغة، نوافذ النجاح)
class TimerDial extends StatefulWidget {
  const TimerDial({super.key, this.size = 160, this.colors});
  final double size;
  final UOrnColors? colors;

  @override
  State<TimerDial> createState() => _TimerDialState();
}

class _TimerDialState extends State<TimerDial> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: UMotionValues.dialSweep, value: .6);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    UMotion.reduced(context) ? _c.stop() : _c.repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: widget.size,
        height: widget.size * 252 / 240,
        child: AnimatedBuilder(
          animation: CurvedAnimation(parent: _c, curve: Curves.easeInOut),
          builder: (_, __) => CustomPaint(painter: _DialPainter(widget.colors ?? UOrnColors.of(context), Curves.easeInOut.transform(_c.value))),
        ),
      );
}

class _PulsePainter extends CustomPainter {
  _PulsePainter(this.c, this.chevrons);
  final UOrnColors c;
  final bool chevrons;

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2, cx = size.width / 2;
    final line = Paint()
      ..color = c.m
      ..strokeWidth = 1.6;
    canvas.drawLine(Offset(0, cy), Offset(cx - 52, cy), line);
    canvas.drawLine(Offset(cx + 52, cy), Offset(size.width, cy), line);
    final p = Paint()
      ..color = c.a
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    if (chevrons) {
      for (var i = 0; i < 3; i++) {
        final x = cx - 30 + i * 22.0;
        canvas.drawPath(Path()..moveTo(x + 10, cy - 9)..lineTo(x, cy)..lineTo(x + 10, cy + 9), p..color = c.a.withValues(alpha: 1 - i * .3));
      }
    } else {
      canvas.drawPath(
          Path()
            ..moveTo(cx - 40, cy)
            ..lineTo(cx - 24, cy)
            ..lineTo(cx - 15, cy - 12)
            ..lineTo(cx - 2, cy + 12)
            ..lineTo(cx + 9, cy - 8)
            ..lineTo(cx + 16, cy)
            ..lineTo(cx + 40, cy),
          p);
    }
    canvas.drawCircle(Offset(cx - 48, cy), 2.6, Paint()..color = c.b);
    canvas.drawCircle(Offset(cx + 48, cy), 2.6, Paint()..color = c.b);
  }

  @override
  bool shouldRepaint(_PulsePainter o) => o.c != c;
}

/// فاصل النبض: يتنفس (تحت عنوان الدخول، داخل الحالة الفارغة)
class PulseDivider extends StatelessWidget {
  const PulseDivider({super.key, this.width = 220, this.colors});
  final double width;
  final UOrnColors? colors;

  @override
  Widget build(BuildContext context) =>
      Breathe(child: SizedBox(width: width, height: 26, child: CustomPaint(painter: _PulsePainter(colors ?? UOrnColors.of(context), false))));
}

/// فاصل الأسهم: ثابت (الشهادات ونوافذ النجاح)
class ChevronDivider extends StatelessWidget {
  const ChevronDivider({super.key, this.width = 220, this.colors});
  final double width;
  final UOrnColors? colors;

  @override
  Widget build(BuildContext context) => SizedBox(width: width, height: 26, child: CustomPaint(painter: _PulsePainter(colors ?? UOrnColors.of(context), true)));
}

class _TrackPainter extends CustomPainter {
  _TrackPainter(this.c);
  final UOrnColors c;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.height / 48;
    final line = Paint()
      ..color = c.m
      ..strokeWidth = 2 * k;
    canvas.drawLine(Offset(0, 4 * k), Offset(size.width, 4 * k), line);
    canvas.drawLine(Offset(0, 44 * k), Offset(size.width, 44 * k), line);
    for (double x = 0; x < size.width; x += 160 * k) {
      final dash = Paint()..color = c.ink.withValues(alpha: .45);
      canvas.drawRect(Rect.fromLTWH(x + 8 * k, 22.75 * k, 44 * k, 2.5 * k), dash);
      canvas.drawRect(Rect.fromLTWH(x + 88 * k, 22.75 * k, 44 * k, 2.5 * k), dash);
      canvas.save();
      canvas.scale(k);
      canvas.drawPath(_para(x / k + 66, 10, 8, 28), Paint()..color = c.a);
      canvas.drawPath(_para(x / k + 146, 10, 8, 28), Paint()..color = c.b);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_TrackPainter o) => o.c != c;
}

/// شريط المضمار: الحافة السفلية لشاشة الدخول والبدء
class TrackBand extends StatelessWidget {
  const TrackBand({super.key, this.height = 36, this.colors});
  final double height;
  final UOrnColors? colors;

  @override
  Widget build(BuildContext context) => SizedBox(height: height, width: double.infinity, child: CustomPaint(painter: _TrackPainter(colors ?? UOrnColors.of(context))));
}

class _CornerPainter extends CustomPainter {
  _CornerPainter(this.c);
  final UOrnColors c;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 120);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(Path()..moveTo(6, 114)..lineTo(6, 30)..lineTo(30, 6)..lineTo(114, 6), p..color = c.ink..strokeWidth = 3);
    canvas.drawPath(Path()..moveTo(18, 114)..lineTo(18, 36)..lineTo(36, 18)..lineTo(114, 18), p..color = c.a..strokeWidth = 1.6);
    canvas.drawRect(const Rect.fromLTWH(104, 2, 9, 9), Paint()..color = c.a);
    canvas.drawRect(const Rect.fromLTWH(2, 104, 9, 9), Paint()..color = c.a);
  }

  @override
  bool shouldRepaint(_CornerPainter o) => o.c != c;
}

/// الزاوية المشطوفة: الشهادات والمطبوعات ونوافذ النجاح فقط
class CornerBracket extends StatelessWidget {
  const CornerBracket({super.key, this.size = 60, this.colors, this.quarterTurns = 0});
  final double size;
  final UOrnColors? colors;
  final int quarterTurns;

  @override
  Widget build(BuildContext context) =>
      RotatedBox(quarterTurns: quarterTurns, child: SizedBox.square(dimension: size, child: CustomPaint(painter: _CornerPainter(colors ?? UOrnColors.of(context)))));
}

/// شكل البطاقة: زوايا مستديرة مع زاوية علوية مشطوفة (بجهة البداية في RTL = اليمين)
class CutCardBorder extends OutlinedBorder {
  const CutCardBorder({super.side, this.radius = URadius.card, this.cut = URadius.cut});
  final double radius, cut;

  Path _path(Rect r, TextDirection? dir) {
    final rtl = dir != TextDirection.ltr;
    final rr = radius;
    final p = Path();
    if (rtl) {
      p.moveTo(r.left + rr, r.top);
      p.lineTo(r.right - cut, r.top);
      p.lineTo(r.right, r.top + cut);
      p.lineTo(r.right, r.bottom - rr);
      p.arcToPoint(Offset(r.right - rr, r.bottom), radius: Radius.circular(rr));
      p.lineTo(r.left + rr, r.bottom);
      p.arcToPoint(Offset(r.left, r.bottom - rr), radius: Radius.circular(rr));
      p.lineTo(r.left, r.top + rr);
      p.arcToPoint(Offset(r.left + rr, r.top), radius: Radius.circular(rr));
    } else {
      p.moveTo(r.left + cut, r.top);
      p.lineTo(r.right - rr, r.top);
      p.arcToPoint(Offset(r.right, r.top + rr), radius: Radius.circular(rr));
      p.lineTo(r.right, r.bottom - rr);
      p.arcToPoint(Offset(r.right - rr, r.bottom), radius: Radius.circular(rr));
      p.lineTo(r.left + rr, r.bottom);
      p.arcToPoint(Offset(r.left, r.bottom - rr), radius: Radius.circular(rr));
      p.lineTo(r.left, r.top + cut);
    }
    return p..close();
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => _path(rect, textDirection);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => _path(rect.deflate(side.strokeInset), textDirection);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none) return;
    canvas.drawPath(_path(rect.deflate(side.width / 2), textDirection), side.toPaint());
  }

  @override
  CutCardBorder copyWith({BorderSide? side}) => CutCardBorder(side: side ?? this.side, radius: radius, cut: cut);

  @override
  ShapeBorder scale(double t) => CutCardBorder(side: side.scale(t), radius: radius * t, cut: cut * t);

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);
}

/// الإطار المائل: بطاقة الدخول ونوافذ النجاح والشهادات (زاويتان مشطوفتان متقابلتان)
class SlantFrameBorder extends OutlinedBorder {
  const SlantFrameBorder({super.side, this.cut = 36});
  final double cut;

  Path _path(Rect r) => Path()
    ..moveTo(r.left + cut, r.top)
    ..lineTo(r.right, r.top)
    ..lineTo(r.right, r.bottom - cut)
    ..lineTo(r.right - cut, r.bottom)
    ..lineTo(r.left, r.bottom)
    ..lineTo(r.left, r.top + cut)
    ..close();

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => _path(rect);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => _path(rect.deflate(side.strokeInset));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none) return;
    canvas.drawPath(_path(rect.deflate(side.width / 2)), side.toPaint());
  }

  @override
  SlantFrameBorder copyWith({BorderSide? side}) => SlantFrameBorder(side: side ?? this.side, cut: cut);

  @override
  ShapeBorder scale(double t) => SlantFrameBorder(side: side.scale(t), cut: cut * t);

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);
}
