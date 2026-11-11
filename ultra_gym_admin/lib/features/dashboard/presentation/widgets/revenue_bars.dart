import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/core.dart';

/// إيراد آخر 7 أيام (`Dashboard.html`): قيمة كل يوم فوق عموده دائماً، رأس العمود مائل، واليوم بالبرتقالي.
/// بدل `RepBarChart` من الحزمة لأنه يخفي القيم حتى المرور ويحجز 44 فقط لسطرين بارتفاع 18
/// (فأطول عمود يفيض 4px). هنا العمود يأخذ ما يبقى بعد القيمة والاسم، فلا فيض بأي خط أو مقاس.
/// أيام بلا إيراد كلها ← سطر بدل رسم فارغ، والقيم السالبة (استرجاع) تُرسم صفراً.
class RevenueBars extends StatelessWidget {
  const RevenueBars({super.key, required this.daily});

  final List<({DateTime date, double usd})> daily;

  static const days = 7;

  @override
  Widget build(BuildContext context) {
    final week = daily.length > days ? daily.sublist(daily.length - days) : daily;
    final values = [for (final d in week) math.max(0, d.usd).toDouble()];
    if (values.every((v) => v == 0)) {
      return Text('لا إيراد مسجّل بآخر 7 أيام.', style: UType.body(color: context.colors.inkMuted));
    }
    final top = values.reduce(math.max);
    final short = context.isMobile;
    return Semantics(
      label: 'إيراد آخر 7 أيام بالدولار، اليوم ${Formatters.usd(week.last.usd)}',
      child: ExcludeSemantics(
        child: SizedBox(
          height: AppSize.barChart,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: AppMotion.of(context, AppMotion.entrance),
            curve: AppMotion.curve,
            builder: (context, t, _) => Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < week.length; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpace.s1),
                      child: _Bar(
                        value: values[i],
                        fraction: values[i] / top * t,
                        label: i == week.length - 1
                            ? 'اليوم'
                            : (short ? '${week[i].date.day}' : Formatters.weekday(week[i].date)),
                        today: i == week.length - 1,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.value, required this.fraction, required this.label, required this.today});

  final double value, fraction;
  final String label;
  final bool today;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: LtrText(Formatters.usd(value), style: UType.caption(color: c.inkMuted)),
              ),
              AppSpace.gap1,
              Flexible(
                child: FractionallySizedBox(
                  heightFactor: fraction,
                  widthFactor: 1,
                  child: ClipPath(
                    clipper: const _SlantTop(),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: today ? c.primary : c.line,
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppRadius.xs)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        AppSpace.gap2,
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label, maxLines: 1, style: UType.caption(color: today ? c.ink : c.inkMuted)),
        ),
      ],
    );
  }
}

/// رأس مائل (`clip-path: polygon(0 0, 100% 8px, …)`): الحافة اليسرى أعلى بـ 8.
class _SlantTop extends CustomClipper<Path> {
  const _SlantTop();

  @override
  Path getClip(Size s) {
    final d = math.min(AppSpace.s2, s.height);
    return Path()
      ..moveTo(0, 0)
      ..lineTo(s.width, d)
      ..lineTo(s.width, s.height)
      ..lineTo(0, s.height)
      ..close();
  }

  @override
  bool shouldReclip(_SlantTop old) => false;
}
