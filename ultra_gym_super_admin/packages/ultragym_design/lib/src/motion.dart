import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'tokens.dart';

/// الحركة: كل شيء سريع وواضح، والحركة الدائمة بطيئة جداً، و"تقليل الحركة" يوقف الكل.
abstract final class UMotion {
  static bool reduced(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}

/// دخول العنصر عند فتح الشاشة: شفافية + صعود 14px، بتتابع حسب index
class Entrance extends StatefulWidget {
  const Entrance({super.key, required this.child, this.index = 0});
  final Widget child;
  final int index;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: UMotionValues.entrance);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (UMotion.reduced(context)) {
      _c.value = 1;
    } else if (_c.value == 0 && !_c.isAnimating) {
      Future.delayed(UMotionValues.entranceStep * widget.index, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = CurvedAnimation(parent: _c, curve: UMotionValues.standard);
    return AnimatedBuilder(
      animation: a,
      builder: (_, child) => Opacity(opacity: a.value, child: Transform.translate(offset: Offset(0, 14 * (1 - a.value)), child: child)),
      child: widget.child,
    );
  }
}

/// عدّ الرقم من 0 للقيمة. الأرقام دائماً LTR
class CountUp extends StatelessWidget {
  const CountUp(this.value, {super.key, this.style, this.prefix = '', this.suffix = '', this.decimals = 0});
  final double value;
  final TextStyle? style;
  final String prefix, suffix;
  final int decimals;

  static String format(double v, int decimals) {
    final s = v.toStringAsFixed(decimals);
    final parts = s.split('.');
    final whole = parts[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
    return parts.length > 1 ? '$whole.${parts[1]}' : whole;
  }

  @override
  Widget build(BuildContext context) {
    final reduced = UMotion.reduced(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduced ? value : 0, end: value),
      duration: reduced ? Duration.zero : UMotionValues.countUp,
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text('$prefix${format(v, decimals)}$suffix', style: style, textDirection: TextDirection.ltr),
    );
  }
}

/// صعود البطاقة عند المرور: 3px + حد برتقالي + ظل خفيف
class HoverLift extends StatefulWidget {
  const HoverLift({super.key, required this.builder});
  final Widget Function(BuildContext context, bool hover) builder;

  @override
  State<HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<HoverLift> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: AnimatedSlide(
        offset: Offset(0, _h && !UMotion.reduced(context) ? -0.015 : 0),
        duration: UMotionValues.base,
        curve: UMotionValues.standard,
        child: widget.builder(context, _h),
      ),
    );
  }
}

/// تصغير 0.97 لحظة الضغط (مبني بالأزرار والبطاقات)
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _down = true),
      onTapUp: widget.onTap == null ? null : (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(scale: _down ? .97 : 1, duration: UMotionValues.press, curve: UMotionValues.standard, child: widget.child),
    );
  }
}

/// لمعة مائلة تعبر الزر الأساسي عند المرور
class Shine extends StatefulWidget {
  const Shine({super.key, required this.child, required this.active, this.radius = URadius.sm});
  final Widget child;
  final bool active;
  final double radius;

  @override
  State<Shine> createState() => _ShineState();
}

class _ShineState extends State<Shine> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: UMotionValues.shine);

  @override
  void didUpdateWidget(Shine old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active && !UMotion.reduced(context)) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: Stack(children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, __) => _c.value == 0 || _c.value == 1
                  ? const SizedBox()
                  : FractionalTranslation(
                      translation: Offset(-1.2 + 2.4 * Curves.easeInOut.transform(_c.value), 0),
                      child: Transform(
                        transform: Matrix4.skewX(-.35),
                        child: Container(
                          width: 46,
                          decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.white.withValues(alpha: 0), Colors.white.withValues(alpha: .45), Colors.white.withValues(alpha: 0)])),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ]),
    );
  }
}

/// نقطة إشعار بحلقة تتوسع وتختفي
class PingDot extends StatefulWidget {
  const PingDot({super.key, required this.color, this.size = 8});
  final Color color;
  final double size;

  @override
  State<PingDot> createState() => _PingDotState();
}

class _PingDotState extends State<PingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: UMotionValues.ping);

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
    return SizedBox.square(
      dimension: widget.size * 2.6,
      child: AnimatedBuilder(animation: _c, builder: (_, __) => CustomPaint(painter: _PingPainter(widget.color, widget.size, _c.value))),
    );
  }
}

class _PingPainter extends CustomPainter {
  _PingPainter(this.color, this.dot, this.t);
  final Color color;
  final double dot, t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    canvas.drawCircle(c, dot / 2 + dot * .8 * t, Paint()..color = color.withValues(alpha: (1 - t) * .5));
    canvas.drawCircle(c, dot / 2, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_PingPainter o) => o.t != t;
}

/// دوران بطيء دائم (قرص الأوزان)
class SlowSpin extends StatefulWidget {
  const SlowSpin({super.key, required this.child, this.period = UMotionValues.plateSpin});
  final Widget child;
  final Duration period;

  @override
  State<SlowSpin> createState() => _SlowSpinState();
}

class _SlowSpinState extends State<SlowSpin> with SingleTickerProviderStateMixin {
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
  Widget build(BuildContext context) => RotationTransition(turns: _c, child: widget.child);
}

/// تنفّس: شفافية 0.45 ↔ 1
class Breathe extends StatefulWidget {
  const Breathe({super.key, required this.child, this.delay = Duration.zero});
  final Widget child;
  final Duration delay;

  @override
  State<Breathe> createState() => _BreatheState();
}

class _BreatheState extends State<Breathe> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: UMotionValues.pulse);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (UMotion.reduced(context)) {
      _c.value = 1;
      _c.stop();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _c.repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, child) => Opacity(opacity: .45 + .55 * (0.5 - 0.5 * math.cos(_c.value * math.pi)), child: child),
        child: widget.child,
      );
}
