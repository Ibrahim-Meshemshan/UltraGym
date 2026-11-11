import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import 'demo_shape.dart';

typedef DayValue = ({DateTime date, double usd});

/// رسم "الخرز" بالتجربة: لكل يوم ساق تتلاشى نحو الأسفل ورأس دائري، واليوم الأخير بالتدرج البرتقالي
/// وحلقة "تتنفس". المرور أو الضغط على يوم يظلّل عموده ويرسم خطاً متقطعاً عند قيمته مع حبة القيمة على الطرف،
/// وبلا مرور يبقى الخط على اليوم الأخير. الساق تنمو من الأسفل عند الدخول. السالب (استرجاع) يُرسم صفراً.
/// `StatefulWidget` لدورة حياة الحركة فقط؛ اليوم المختار بـ `ValueCubit`.
class LollipopChart extends StatefulWidget {
  const LollipopChart({super.key, required this.days});

  final List<DayValue> days;

  @override
  State<LollipopChart> createState() => _LollipopChartState();
}

class _LollipopChartState extends State<LollipopChart> with TickerProviderStateMixin {
  late final _grow = AnimationController(vsync: this, duration: AppMotion.entrance);
  late final _breathe = AnimationController(vsync: this, duration: DemoShape.breathe);
  final _picked = ValueCubit<int?>(null);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduced(context)) {
      _grow.value = 1;
      _breathe.stop();
    } else {
      if (_grow.value == 0) _grow.forward();
      if (!_breathe.isAnimating) _breathe.repeat(reverse: true, count: DemoShape.breaths);
    }
  }

  @override
  void didUpdateWidget(LollipopChart old) {
    super.didUpdateWidget(old);
    if (old.days.length != widget.days.length && !AppMotion.reduced(context)) _grow.forward(from: 0);
  }

  @override
  void dispose() {
    _grow.dispose();
    _breathe.dispose();
    _picked.close();
    super.dispose();
  }

  int? _indexAt(double dx, double width, TextDirection dir) {
    final n = widget.days.length;
    final plot = width - _ChartPainter.gutter;
    if (plot <= 0 || n == 0) return null;
    final fromStart = dir == TextDirection.rtl ? width - dx : dx;
    final i = ((fromStart - _ChartPainter.gutter) / (plot / n)).floor();
    return i < 0 || i >= n ? null : i;
  }

  @override
  Widget build(BuildContext context) {
    final d = AppPalette.of(context);
    final days = widget.days;
    final values = [for (final v in days) math.max(0, v.usd).toDouble()];
    if (values.every((v) => v == 0)) {
      return Text('لا إيراد مسجّل بهذه الفترة.', style: UType.body(color: d.muted));
    }
    final dir = Directionality.of(context);
    final short = context.isMobile || days.length > 7;
    return Semantics(
      label:
          'إيراد آخر ${Formatters.count(days.length, 'يوم واحد', 'يومين', 'أيام', many: 'يوماً')} بالدولار، اليوم ${Formatters.usd(days.last.usd)}',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: DemoShape.chart,
              child: LayoutBuilder(
                builder: (context, box) => MouseRegion(
                  onHover: (e) => _picked.set(_indexAt(e.localPosition.dx, box.maxWidth, dir)),
                  onExit: (_) => _picked.set(null),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (e) => _picked.set(_indexAt(e.localPosition.dx, box.maxWidth, dir)),
                    child: BlocBuilder<ValueCubit<int?>, int?>(
                      bloc: _picked,
                      builder: (context, picked) => AnimatedBuilder(
                        animation: Listenable.merge([_grow, _breathe]),
                        builder: (context, _) => CustomPaint(
                          size: Size.infinite,
                          painter: _ChartPainter(
                            values: values,
                            picked: picked,
                            grow: DemoShape.ease.transform(_grow.value),
                            breathe: _breathe.value,
                            palette: d,
                            dir: dir,
                            label: UType.caption(color: d.muted),
                            chip: UType.caption(color: d.accentInk).weight(700),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            AppSpace.gap2,
            Padding(
              padding: const EdgeInsetsDirectional.only(start: _ChartPainter.gutter),
              child: Row(
                children: [
                  for (var i = 0; i < days.length; i++)
                    Expanded(
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            i == days.length - 1
                                ? 'اليوم'
                                : (short ? '${days[i].date.day}' : Formatters.weekday(days[i].date)),
                            maxLines: 1,
                            style: UType.caption(color: i == days.length - 1 ? d.accentText : d.muted),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.values,
    required this.picked,
    required this.grow,
    required this.breathe,
    required this.palette,
    required this.dir,
    required this.label,
    required this.chip,
  });

  /// عرض عمود القيم على طرف البداية، والمسافة فوق أعلى قيمة.
  static const gutter = 48.0;
  static const _top = 10.0;

  final List<double> values;
  final int? picked;
  final double grow, breathe;
  final AppPalette palette;
  final TextDirection dir;
  final TextStyle label, chip;

  double _x(double fromStart, Size s) => dir == TextDirection.rtl ? s.width - fromStart : fromStart;

  /// سقف لطيف للمحور (1، 2، 2.5، 5 × 10^n) بأربعة خطوط.
  static double niceStep(double max) {
    final raw = max / 4;
    final p = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    final f = raw / p;
    return (f <= 1
            ? 1
            : f <= 2
            ? 2
            : f <= 2.5
            ? 2.5
            : f <= 5
            ? 5
            : 10) *
        p;
  }

  static String axis(double v) => v >= 1000 ? '\$${Formatters.number(v / 1000)}k' : '\$${Formatters.number(v)}';

  @override
  void paint(Canvas canvas, Size s) {
    final d = palette;
    final step = niceStep(values.reduce(math.max));
    final top = step * 4;
    final h = s.height;
    double y(double v) => h - (h - _top) * (v / top);

    // الخطوط الأفقية وقيمها
    final grid = Paint()
      ..color = d.line2
      ..strokeWidth = 1;
    for (var k = 0; k <= 4; k++) {
      final gy = y(step * k);
      _dashed(canvas, Offset(_x(gutter, s), gy), Offset(_x(s.width, s), gy), grid, dash: 2, gap: 4);
      _text(canvas, axis(step * k), label, Offset(_x(0, s), gy));
    }

    final n = values.length;
    final col = (s.width - gutter) / n;
    final active = picked ?? n - 1;

    // تظليل العمود المختار
    final hx = gutter + col * active;
    final well = Rect.fromLTRB(
      math.min(_x(hx, s), _x(hx + col, s)) + 2,
      0,
      math.max(_x(hx, s), _x(hx + col, s)) - 2,
      h,
    );
    if (picked != null) {
      canvas.drawRRect(RRect.fromRectAndRadius(well, const Radius.circular(DemoShape.sm)), Paint()..color = d.well);
    }

    for (var i = 0; i < n; i++) {
      final cx = _x(gutter + col * (i + .5), s);
      final cy = y(values[i] * grow);
      final hot = i == n - 1 || i == picked;
      final stem = Rect.fromLTRB(cx - 1.5, cy, cx + 1.5, h);
      final shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: hot
            ? [d.accentTo.withValues(alpha: 0), d.accentTo, d.accentFrom]
            : [d.data.withValues(alpha: 0), d.data],
        stops: hot ? const [0, .35, 1] : const [0, .4],
      ).createShader(stem);
      canvas.drawRRect(RRect.fromRectAndRadius(stem, const Radius.circular(2)), Paint()..shader = shader);

      const r = DemoShape.bead / 2;
      if (i == n - 1) {
        canvas.drawCircle(
          Offset(cx, cy),
          r + 4 + 2 * breathe,
          Paint()..color = d.accent.withValues(alpha: .15 + .25 * breathe),
        );
      }
      canvas.drawCircle(Offset(cx, cy), r, Paint()..color = hot ? d.accent : d.data);
      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = d.card,
      );
    }

    // خط القيمة المختارة وحبتها على طرف البداية
    final ay = y(values[active] * grow);
    _dashed(
      canvas,
      Offset(_x(gutter, s), ay),
      Offset(_x(s.width, s), ay),
      Paint()
        ..color = d.accent
        ..strokeWidth = 1.2,
      dash: 5,
      gap: 4,
    );
    final tp = TextPainter(
      text: TextSpan(text: Formatters.usd(values[active]), style: chip),
      textDirection: TextDirection.ltr,
    )..layout();
    final cw = tp.width + 12, ch = tp.height + 6;
    final left = dir == TextDirection.rtl ? s.width - cw : 0.0;
    final rect = Rect.fromLTWH(left, ay - ch / 2, cw, ch);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), Paint()..color = d.accent);
    tp.paint(canvas, Offset(rect.left + 6, rect.top + 3));
  }

  void _text(Canvas canvas, String t, TextStyle style, Offset at) {
    final tp = TextPainter(
      text: TextSpan(text: t, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final x = dir == TextDirection.rtl ? at.dx - tp.width : at.dx;
    tp.paint(canvas, Offset(x, at.dy - tp.height - 2));
  }

  void _dashed(Canvas canvas, Offset a, Offset b, Paint p, {required double dash, required double gap}) {
    final len = (b - a).distance;
    if (len == 0) return;
    final u = (b - a) / len;
    for (var t = 0.0; t < len; t += dash + gap) {
      canvas.drawLine(a + u * t, a + u * math.min(t + dash, len), p);
    }
  }

  /// يُبنى من جديد فقط مع الحركة أو تغيّر اليوم المختار أو البيانات، فكل بناء يستحق الرسم.
  @override
  bool shouldRepaint(_ChartPainter old) => true;
}
