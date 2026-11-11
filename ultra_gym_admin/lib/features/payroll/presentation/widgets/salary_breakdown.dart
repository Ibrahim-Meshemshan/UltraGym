import 'package:flutter/material.dart';

import '../../../../core/core.dart';

/// سطر بتفصيل الراتب: `sign` = '+' أو '−' أو '' (الأساسي).
typedef SalaryLine = ({String label, num usd, String sign});

/// تفصيل الراتب (`Payroll.html` `.breakdown`): الأسطر بإشاراتها ثم الصافي بخط أعرض.
class SalaryBreakdown extends StatelessWidget {
  const SalaryBreakdown({super.key, required this.lines, required this.netLabel, required this.net, this.note});

  final List<SalaryLine> lines;
  final String netLabel;
  final num net;

  /// تحت الصافي (مثلاً ما يعادله بالليرة).
  final String? note;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(color: c.surfaceAlt, borderRadius: AppRadius.fieldAll),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpace.s2,
          children: [
            for (final l in lines)
              _Row(
                l.label,
                '${l.sign.isEmpty ? '' : '${l.sign} '}${Formatters.usd(l.usd)}',
                color: l.sign == '−' && l.usd > 0 ? c.dangerInk : c.ink,
              ),
            Divider(height: 1, color: c.lineStrong),
            _Row(netLabel, Formatters.usd(net), color: net < 0 ? c.dangerInk : c.ink, strong: true),
            if (note != null)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Text(note!, style: UType.caption(color: c.inkMuted)),
              ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {required this.color, this.strong = false});

  final String label, value;
  final Color color;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      spacing: AppSpace.s3,
      children: [
        Expanded(
          child: Text(
            label,
            style: strong ? UType.body(color: c.ink).weight(700) : UType.label(color: c.inkMuted),
          ),
        ),
        LtrText(value, style: strong ? UType.h3(color: color) : UType.body(color: color).weight(600)),
      ],
    );
  }
}

/// بطاقة رقم صغيرة (`.tile`): التسمية فوق المبلغ.
class SalaryTile extends StatelessWidget {
  const SalaryTile({super.key, required this.label, required this.usd, this.tone});

  final String label;
  final num usd;

  /// `warning` للسلف المفتوحة.
  final UTone? tone;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.fieldAll,
        border: Border.all(color: c.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.s3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpace.s1,
          children: [
            Text(label, style: UType.caption(color: c.inkMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
            LtrText(
              Formatters.usd(usd),
              style: UType.h3(color: tone == UTone.warning && usd > 0 ? c.warningInk : c.ink),
            ),
          ],
        ),
      ),
    );
  }
}
