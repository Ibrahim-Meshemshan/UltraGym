import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../domain/models/training_models.dart';

/// بطاقات آخر قيمة لأهم القياسات ومؤشر كتلة الجسم، وتحت كل منها الفرق منذ أول قياس (`meta.progress` من الخادم).
/// لون الفرق حسب "الأفضل" للحقل (الوزن والدهون والخصر نقصها أفضل، والعضل زيادته)، والطول محايد.
class MeasurementValues extends StatelessWidget {
  const MeasurementValues({super.key, required this.page});

  final MeasurementsPage page;

  @override
  Widget build(BuildContext context) {
    double? latest(double? Function(BodyMeasurement m) of) => page.items.map(of).nonNulls.firstOrNull;
    return ResponsiveGrid(
      minItemWidth: AppSize.measureTileMin,
      maxColumns: MeasureField.headline.length + 1,
      children: [
        for (final f in MeasureField.headline)
          _Tile(
            label: f.label,
            value: TrainingTexts.value(latest((m) => m[f]), f.unit),
            delta: page.progress?[f],
            better: f.better,
          ),
        _Tile(label: 'مؤشر كتلة الجسم', value: TrainingTexts.value(latest((m) => m.bmi), '')),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.value, this.delta, this.better = 0});

  final String label, value;
  final double? delta;
  final int better;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final d = delta;
    final color = switch (d) {
      null => c.inkFaint,
      _ when d == 0 || better == 0 => c.inkMuted,
      _ => d.sign == better ? c.successInk : c.warningInk,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: c.line),
        borderRadius: AppRadius.fieldAll,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.s4, vertical: AppSpace.s3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: UType.caption(color: c.inkMuted),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                value,
                textDirection: TextDirection.ltr,
                style: UType.stat(color: c.ink),
              ),
            ),
            Text(
              d == null ? '—' : '${TrainingTexts.delta(d)} منذ البداية',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: UType.caption(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

/// "الوزن عبر الزمن": خط LTR من أقدم وزن بالصفحة إلى أحدثه، والمسافات حسب الأيام. يظهر بوزنين على الأقل.
/// مرسوم بـ `CustomPaint`: `fl_chart` 1.1 لا يُبنى على Flutter 3.32 (يحتاج vector_math أحدث).
class WeightTrend extends StatelessWidget {
  const WeightTrend({super.key, required this.items});

  final List<BodyMeasurement> items;

  /// الأوزان من الأقدم (القائمة من الخادم الأحدث أولاً).
  static List<(DateTime, double)> pointsOf(List<BodyMeasurement> items) => [
    for (final m in items.reversed)
      if (m[MeasureField.weight] case final w?) (m.measuredOn, w),
  ];

  @override
  Widget build(BuildContext context) {
    final points = pointsOf(items);
    if (points.length < 2) return const SizedBox.shrink();
    final c = context.colors;
    final first = points.first, last = points.last;
    String kg(double v) => TrainingTexts.value(v, 'kg');
    final label =
        'الوزن من ${kg(first.$2)} إلى ${kg(last.$2)} بين ${Formatters.date(first.$1)} و ${Formatters.date(last.$1)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.s2,
      children: [
        Text('الوزن عبر الزمن', style: UType.h3(color: c.ink)),
        Semantics(
          label: label,
          image: true,
          child: SizedBox(
            height: AppSize.trendChart,
            child: CustomPaint(
              painter: _TrendPainter(points: points, line: c.primary, grid: c.line),
              size: Size.infinite,
            ),
          ),
        ),
        ExcludeSemantics(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${Formatters.date(first.$1)} · ${kg(first.$2)}', style: UType.caption(color: c.inkFaint)),
                Text('${Formatters.date(last.$1)} · ${kg(last.$2)}', style: UType.caption(color: c.inkMuted)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// ثلاثة خطوط أفقية ثم الوزن خطاً بعرض 3 ونقطة على آخر قياس. الرسم من اليسار (التاريخ يتقدم يميناً).
class _TrendPainter extends CustomPainter {
  _TrendPainter({required this.points, required this.line, required this.grid});

  final List<(DateTime, double)> points;
  final Color line, grid;

  static const _inset = 8.0, _stroke = 3.0, _dot = 5.0;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (final f in const [0.0, 0.5, 1.0]) {
      final y = _inset + (size.height - 2 * _inset) * f;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    final days = points.last.$1.difference(points.first.$1).inDays;
    final weights = points.map((p) => p.$2);
    final lo = weights.reduce((a, b) => a < b ? a : b), hi = weights.reduce((a, b) => a > b ? a : b);
    final span = hi == lo ? 1.0 : hi - lo;
    // قياسات باليوم نفسه كلها: مسافات متساوية بدل خط عمودي.
    Offset at((DateTime, double) p) {
      final x = days == 0 ? points.indexOf(p) / (points.length - 1) : p.$1.difference(points.first.$1).inDays / days;
      final y = hi == lo ? 0.5 : (hi - p.$2) / span;
      return Offset(_inset + (size.width - 2 * _inset) * x, _inset * 2 + (size.height - 4 * _inset) * y);
    }

    final path = Path()..moveTo(at(points.first).dx, at(points.first).dy);
    for (final p in points.skip(1)) {
      path.lineTo(at(p).dx, at(p).dy);
    }
    canvas
      ..drawPath(
        path,
        Paint()
          ..color = line
          ..style = PaintingStyle.stroke
          ..strokeWidth = _stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      )
      ..drawCircle(at(points.last), _dot, Paint()..color = line);
  }

  @override
  bool shouldRepaint(_TrendPainter old) => old.points != points || old.line != line || old.grid != grid;
}
