import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../domain/models/membership_detail_models.dart';

/// الحساب (`aside` بالنموذج): السعر، الخصم، الصافي، المدفوع، والدين بالعملتين. كل الأرقام من الخادم.
class MembershipAccountCard extends StatelessWidget {
  const MembershipAccountCard(this.detail, {super.key});

  final MembershipDetail detail;

  @override
  Widget build(BuildContext context) {
    final d = detail;
    final m = d.membership;
    final c = context.colors;
    return SectionCard(
      title: 'الحساب',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Line('السعر', Formatters.usd(d.priceUsd)),
          _Line(d.couponCode == null ? 'الخصم' : 'الخصم (${d.couponCode})', Formatters.usd(d.discountUsd)),
          _Line('الصافي', Formatters.usd(m.netUsd), strong: true, divider: true),
          _Line('المدفوع', Formatters.usd(m.paidUsd), color: c.successInk),
          AppSpace.gap2,
          if (d.hasDebt)
            Container(
              padding: const EdgeInsets.all(AppSpace.s3),
              decoration: BoxDecoration(color: c.warningSoft, borderRadius: AppRadius.smAll),
              child: Row(
                children: [
                  Expanded(
                    child: Text('الدين', style: UType.body(color: c.warningInk).weight(600)),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      LtrText(Formatters.usd(m.dueUsd), style: UType.body(color: c.warningInk).weight(700)),
                      LtrText(Formatters.syp(d.dueSyp), style: UType.caption(color: c.warningInk)),
                    ],
                  ),
                ],
              ),
            )
          else
            _Line('الدين', d.isCancelled ? '—' : 'مدفوع بالكامل', color: c.successInk, ltrValue: false),
          if (d.notes case final n? when n.trim().isNotEmpty) ...[
            AppSpace.gap4,
            Text('ملاحظات', style: UType.caption(color: c.inkMuted)),
            Text(n, style: UType.body(color: c.ink)),
          ],
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value, {this.strong = false, this.divider = false, this.color, this.ltrValue = true});

  final String label, value;
  final bool strong, divider, ltrValue;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    var style = UType.body(color: color ?? c.ink);
    if (strong) style = style.weight(600);
    final labelStyle = strong ? UType.body(color: c.ink).weight(600) : UType.body(color: c.inkMuted);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.s2),
      decoration: divider
          ? BoxDecoration(
              border: Border(top: BorderSide(color: c.line)),
            )
          : null,
      child: Row(
        children: [
          Expanded(child: Text(label, style: labelStyle)),
          if (ltrValue) LtrText(value, style: style) else Text(value, style: style),
        ],
      ),
    );
  }
}
