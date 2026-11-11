import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../domain/models/transaction_models.dart';

/// شارة النوع كما يسمّيه الخادم (`type_label`)، ولونه حسب النوع.
class TransactionTypeBadge extends StatelessWidget {
  const TransactionTypeBadge(this.e, {super.key});

  final LedgerEntry e;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: StatusBadge(e.typeLabel, tone: TransactionLabels.tone(e.type)),
    ),
  );
}

/// رقم الإيصال LTR، مشطوب للحركة المعكوسة.
class ReceiptNumber extends StatelessWidget {
  const ReceiptNumber(this.e, {super.key, this.strong = true});

  final LedgerEntry e;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = UType.label(color: e.isReversed ? c.inkMuted : c.ink).weight(strong ? 600 : 500);
    return LtrText(
      e.receiptNumber,
      style: e.isReversed ? style.copyWith(decoration: TextDecoration.lineThrough) : style,
    );
  }
}

/// المبلغ بعملته وإشارته: الداخل أخضر "+"، الخارج أحمر "−"، والمعكوسة باهتة مشطوبة.
class LedgerAmount extends StatelessWidget {
  const LedgerAmount(this.e, {super.key});

  final LedgerEntry e;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = e.isReversed ? c.inkMuted : (e.isIn ? c.successInk : c.dangerInk);
    final style = UType.body(color: color).weight(700);
    // سطر واحد: المبلغ بالليرة أطول، فيصغر إن ضاق العمود بدل أن ينكسر.
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: LtrText(
        '${e.isIn ? '+' : '−'}${Formatters.money(e.amount, e.currency)}',
        style: e.isReversed ? style.copyWith(decoration: TextDecoration.lineThrough) : style,
      ),
    );
  }
}

/// "مرتبطة بـ": العضو (يفتح ملفه)، أو الموظف، أو الوردية (تفتح صفحتها).
class LedgerLink extends StatelessWidget {
  const LedgerLink(this.e, {super.key});

  final LedgerEntry e;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (label, route) = switch (e) {
      LedgerEntry(:final playerName?, :final playerId?) => (playerName, Routes.child(Routes.members, playerId)),
      LedgerEntry(:final staffName?) => (staffName, null),
      LedgerEntry(:final cashSessionId?) => (
        'وردية ${Formatters.ltr('#$cashSessionId')}',
        Routes.child(Routes.cashSessions, cashSessionId),
      ),
      _ => ('—', null),
    };
    final text = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: UType.label(color: route == null ? c.inkMuted : c.primaryInk).weight(route == null ? 400 : 600),
    );
    if (route == null) return text;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: InkWell(
        borderRadius: AppRadius.smAll,
        onTap: () => context.go(route),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.s1),
          child: text,
        ),
      ),
    );
  }
}

/// إجراءات الصف: الإيصال، ثم "عكس" (للمالك على ما يُعكس) أو شارة "معكوسة".
class LedgerRowActions extends StatelessWidget {
  const LedgerRowActions(this.e, {super.key, required this.owner, required this.onReceipt, this.onReverse});

  final LedgerEntry e;
  final bool owner;
  final VoidCallback onReceipt;
  final VoidCallback? onReverse;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpace.s1,
      children: [
        IconButton(
          tooltip: 'إيصال ${e.receiptNumber}',
          onPressed: onReceipt,
          icon: const Icon(Icons.receipt_long_rounded),
        ),
        if (e.isReversed)
          const StatusBadge('معكوسة', tone: UTone.neutral)
        else if (owner && e.canReverse && onReverse != null)
          TextButton(
            onPressed: onReverse,
            style: TextButton.styleFrom(foregroundColor: c.dangerInk),
            child: const Text('عكس'),
          ),
      ],
    );
  }
}

/// ملخص الحركة بنافذة العكس، وما سيحدث.
class ReverseSummary extends StatelessWidget {
  const ReverseSummary(this.e, {super.key});

  final LedgerEntry e;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget line(String label, Widget value) => Row(
      children: [
        Expanded(
          child: Text(label, style: UType.label(color: c.inkMuted)),
        ),
        AppSpace.gap2,
        Flexible(child: value),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.s3,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpace.s3),
          decoration: BoxDecoration(color: c.surfaceAlt, borderRadius: AppRadius.fieldAll),
          child: Column(
            spacing: AppSpace.s2,
            children: [
              line('الإيصال', ReceiptNumber(e)),
              line('النوع', Text(e.typeLabel, style: UType.label(color: c.ink).weight(600))),
              line('المبلغ', LedgerAmount(e)),
              if (e.description case final d?)
                line(
                  'الوصف',
                  Text(
                    d,
                    style: UType.label(color: c.ink),
                    textAlign: TextAlign.end,
                  ),
                ),
            ],
          ),
        ),
        Text(
          'تُسجَّل حركة معاكسة بنفس المبلغ على الوردية المفتوحة بإيصال جديد، ويُعكس أثرها '
          '(المدفوع على الاشتراك، الراتب، السلفة). الحركة الأصلية تبقى ظاهرة مشطوبة.',
          style: UType.label(color: c.inkMuted),
        ),
      ],
    );
  }
}
