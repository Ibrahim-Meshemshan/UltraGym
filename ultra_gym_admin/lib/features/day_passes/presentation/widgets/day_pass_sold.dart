import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../members/domain/models/member_history_models.dart';
import '../../../memberships/presentation/widgets/membership_actions.dart';
import '../../domain/models/day_pass_models.dart';

/// بعد البيع داخل النافذة: الاسم والسعر، "سُجّل دخوله" للعضو، إيصال لكل دفعة، ثم "إغلاق" أو "بيع آخر".
class DayPassSold extends StatelessWidget {
  const DayPassSold({super.key, required this.pass, required this.onAgain, required this.onClose});

  final DayPass pass;
  final VoidCallback onAgain, onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.s4,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpace.s4),
          decoration: BoxDecoration(color: c.successSoft, borderRadius: AppRadius.cardAll),
          child: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: c.successInk),
              AppSpace.gap3,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpace.s1,
                  children: [
                    Text('تم بيع الدخول اليومي', style: UType.body(color: c.successInk).weight(600)),
                    Text(
                      [
                        '${DayPassLabels.kind(pass.kind)}: ${pass.name}',
                        if (pass.branchName != null) pass.branchName!,
                        if (!pass.isVisitor) 'سُجّل دخوله تلقائياً',
                      ].join(' · '),
                      style: UType.label(color: c.successInk),
                    ),
                  ],
                ),
              ),
              if (pass.isFree)
                Text('مجاني', style: UType.h3(color: c.successInk))
              else
                LtrText(Formatters.usd(pass.priceUsd), style: UType.h3(color: c.successInk)),
            ],
          ),
        ),
        if (pass.transactions.isNotEmpty) DayPassReceipts(pass.transactions),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: AppSpace.s2,
          runSpacing: AppSpace.s2,
          children: [
            UGButton(label: 'إغلاق', kind: UButtonKind.ghost, onPressed: onClose),
            UGButton(label: 'بيع آخر', icon: Icons.add_rounded, onPressed: onAgain),
          ],
        ),
      ],
    );
  }
}

/// دفعات الدخول اليومي: رقم الإيصال والمبلغ و "طباعة الإيصال"، والمعكوسة مشطوبة.
class DayPassReceipts extends StatelessWidget {
  const DayPassReceipts(this.payments, {super.key});

  final List<PaymentEntry> payments;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('الدفعات', style: UType.label(color: c.inkMuted).weight(600)),
        for (final p in payments)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.s1),
            child: Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: AppSpace.s2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      LtrText(
                        Formatters.money(p.direction == 'out' ? -p.amount : p.amount, p.currency),
                        style: UType.body(
                          color: p.isReversed ? c.inkMuted : c.ink,
                        ).weight(600).copyWith(decoration: p.isReversed ? TextDecoration.lineThrough : null),
                      ),
                      if (p.receiptNumber case final n?) LtrText(n, style: UType.caption(color: c.inkMuted)),
                      if (p.direction == 'out') Text(p.typeLabel, style: UType.caption(color: c.inkMuted)),
                      if (p.isReversed) const StatusBadge('معكوسة', tone: UTone.neutral),
                    ],
                  ),
                ),
                TextButton(onPressed: () => openReceipt(p.id), child: const Text('طباعة الإيصال')),
              ],
            ),
          ),
      ],
    );
  }
}
