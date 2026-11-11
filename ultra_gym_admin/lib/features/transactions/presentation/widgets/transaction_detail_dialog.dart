import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/models/transaction_models.dart';
import '../bloc/transactions_cubit.dart';
import 'ledger_cells.dart';
import 'transaction_actions.dart';

/// تفاصيل حركة (`GET transactions/{id}`): المبلغ وسعر الصرف وما يعادله، الفرع والوردية والتصنيف ومن سجّلها،
/// الوصف، وإيصال العكس للمعكوسة. الأفعال: الإيصال، فتح الاشتراك، و "عكس الحركة" للمالك.
/// ترجع true إن عُكست لتحديث الدفتر.
abstract final class TransactionDetailDialog {
  static Future<bool> show(BuildContext context, int id) async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => BlocProvider(
        create: (_) => sl<LedgerEntryCubit>(param1: id)..load(),
        child: const _Body(),
      ),
    );
    return changed ?? false;
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final cubit = context.watch<LedgerEntryCubit>();
    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpace.s4),
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(AppRadius.hero))),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSize.dialog),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpace.s6),
          child: SliceView<LedgerEntry>(
            slice: cubit.state,
            loading: const DetailsShimmer(),
            onRetry: cubit.load,
            builder: (context, e) => _Content(e),
          ),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content(this.e);

  final LedgerEntry e;

  Future<void> _reverse(BuildContext context) async {
    if (await TransactionActions.reverse(context, e) == null || !context.mounted) return;
    Navigator.of(context).pop(true);
  }

  void _go(BuildContext context, String route) {
    Navigator.of(context).pop(false);
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final owner = context.select<AuthBloc, bool>((b) => b.state.session?.isClubOwner ?? false);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.s4,
      children: [
        Row(
          spacing: AppSpace.s3,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpace.s1,
                children: [ReceiptNumber(e), TransactionTypeBadge(e)],
              ),
            ),
            LedgerAmount(e),
          ],
        ),
        if (e.isReversed)
          Container(
            padding: const EdgeInsets.all(AppSpace.s3),
            decoration: BoxDecoration(color: c.surfaceAlt, borderRadius: AppRadius.fieldAll),
            child: Text(
              [
                'معكوسة',
                if (e.reversedAt != null) Formatters.ltr(Formatters.dateTime(e.reversedAt)),
                if (e.reversedByReceipt case final r?) 'بالإيصال ${Formatters.ltr(r)}',
              ].join(' · '),
              style: UType.label(color: c.inkMuted),
            ),
          ),
        Wrap(
          spacing: AppSpace.s6,
          runSpacing: AppSpace.s3,
          children: [
            _Fact('بالدولار', Formatters.usd(e.amountUsd), ltr: true),
            if (e.amountSypEquivalent case final syp?) _Fact('ما يعادله', Formatters.syp(syp), ltr: true),
            if (e.exchangeRate case final rate?)
              _Fact('سعر الصرف', '1 USD = ${Formatters.number(rate)} SYP', ltr: true),
            _Fact('الفرع', e.branchName ?? '—'),
            if (e.cashSessionId case final id?) _Fact('الوردية', '#$id', ltr: true),
            if (e.categoryName case final cat?) _Fact('التصنيف', cat),
            if (e.playerName ?? e.staffName case final who?) _Fact(e.playerName != null ? 'العضو' : 'الموظف', who),
            _Fact('يوم العمل', Formatters.date(e.businessDate), ltr: true),
            _Fact('الوقت', Formatters.time(e.occurredAt), ltr: true),
            _Fact('المنفّذ', e.createdBy ?? '—'),
          ],
        ),
        if (e.description case final d?) Text(d, style: UType.body(color: c.ink)),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: AppSpace.s2,
          runSpacing: AppSpace.s2,
          children: [
            if (owner && e.canReverse)
              UGButton(
                label: 'عكس الحركة',
                icon: Icons.undo_rounded,
                kind: UButtonKind.danger,
                onPressed: () => _reverse(context),
              ),
            if (e.membershipId case final id?)
              UGButton(
                label: 'فتح الاشتراك',
                kind: UButtonKind.secondary,
                onPressed: () => _go(context, Routes.child(Routes.memberships, id)),
              ),
            UGButton(
              label: 'طباعة الإيصال',
              icon: Icons.receipt_long_rounded,
              kind: UButtonKind.secondary,
              onPressed: () => TransactionActions.receipt(e.id),
            ),
            UGButton(label: 'إغلاق', kind: UButtonKind.secondary, onPressed: () => Navigator.of(context).pop(false)),
          ],
        ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value, {this.ltr = false});

  final String label, value;
  final bool ltr;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = UType.body(color: c.ink).weight(600);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: UType.caption(color: c.inkMuted)),
        if (ltr) LtrText(value, style: style) else Text(value, style: style),
      ],
    );
  }
}
