import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/core.dart';

/// رسم أعمدة التقرير (`Reports.html` `.bars`): عمود لكل يوم بترتيبه (LTR)، الموجب بلون الفعل والسالب بالخطر،
/// تلميح لكل عمود، وتسمية الأول والأخير وما بينهما بانتظام.
class ReportBars extends StatelessWidget {
  const ReportBars({super.key, required this.title, required this.bars, required this.format});

  final String title;
  final List<({String label, num value})> bars;
  final String Function(num value) format;

  /// عدد التسميات تحت الرسم على الأكثر.
  static const _labels = 6;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final max = bars.fold<num>(0, (m, b) => math.max(m, b.value.abs()));
    final step = math.max(1, (bars.length / _labels).ceil());
    return CutCard(
      padding: const EdgeInsets.all(AppSpace.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.s2,
        children: [
          Semantics(header: true, child: Text(title, style: UType.body(color: c.ink).weight(600))),
          SizedBox(
            height: AppSize.hoursChart,
            child: max == 0
                ? Center(child: Text('لا حركة بهذه الفترة.', style: UType.label(color: c.inkMuted)))
                : ExcludeSemantics(
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (final b in bars)
                            Expanded(
                              child: Tooltip(
                                message: '${b.label} · ${format(b.value)}',
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.s1 / 2),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.bottomCenter,
                                    heightFactor: b.value == 0 ? 0.02 : b.value.abs() / max,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: b.value < 0 ? c.danger : c.primary,
                                        borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(AppRadius.xs),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
          ),
          if (max != 0)
            Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                children: [
                  for (var i = 0; i < bars.length; i++)
                    Expanded(
                      child: i % step == 0 || i == bars.length - 1
                          ? Text(
                              bars[i].label,
                              style: UType.caption(color: c.inkMuted),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.visible,
                              softWrap: false,
                            )
                          : const SizedBox.shrink(),
                    ),
                ],
              ),
            ),
          if (bars.any((b) => b.value < 0)) Text('الأحمر = صافٍ سالب.', style: UType.caption(color: c.inkMuted)),
        ],
      ),
    );
  }
}
