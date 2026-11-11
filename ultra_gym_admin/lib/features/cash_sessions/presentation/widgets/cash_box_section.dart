import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../branches/presentation/bloc/branch_scope_cubit.dart';
import '../../../notifications/presentation/bloc/unread_count_cubit.dart';
import '../../../transactions/presentation/widgets/transaction_actions.dart';
import '../../domain/models/cash_session_models.dart';
import '../bloc/cash_sessions_cubit.dart';
import 'cash_session_card.dart';
import 'cash_session_dialogs.dart';

/// صندوق فرع واحد: الوردية المفتوحة ببطاقتها، أو "الصندوق مغلق" مع "فتح الصندوق".
/// بعد الفتح أو الإغلاق: تحديث الصندوق وشارة الشريط العلوي والجرس، ثم `onChanged` (سجل الورديات).
class CashBoxSection extends StatelessWidget {
  const CashBoxSection({super.key, required this.branchId, this.showBranch = false, this.onChanged});

  final int branchId;
  final bool showBranch;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) => BlocProvider(
    key: ValueKey(branchId),
    create: (_) => sl<CashBoxCubit>(param1: branchId)..load(),
    child: _BoxView(showBranch: showBranch, onChanged: onChanged),
  );
}

class _BoxView extends StatelessWidget {
  const _BoxView({required this.showBranch, this.onChanged});

  final bool showBranch;
  final VoidCallback? onChanged;

  Future<void> _after(BuildContext context) async {
    final box = context.read<CashBoxCubit>();
    final scope = context.read<BranchScopeCubit?>();
    final unread = context.read<UnreadCountCubit?>();
    onChanged?.call();
    unawaited(scope?.refresh());
    unawaited(unread?.refresh());
    await box.refresh();
  }

  Future<void> _open(BuildContext context, CashBox b) async {
    if (await CashSessionActions.open(context, b) != null && context.mounted) await _after(context);
  }

  /// مصروف أو إيراد بصندوق هذه الوردية: الأرصدة الحية والسجل تتغير.
  Future<void> _record(BuildContext context, CashSession s) async {
    if (await TransactionActions.record(context, branchId: s.branchId) != null && context.mounted) {
      await _after(context);
    }
  }

  Future<void> _close(BuildContext context, CashSession s) async {
    if (await CashSessionActions.close(context, s) != null && context.mounted) await _after(context);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<CashBoxCubit>();
    return SliceView<CashBox>(
      slice: cubit.state,
      loading: const _BoxShimmer(),
      onRetry: cubit.load,
      builder: (context, b) => switch (b.session) {
        final s? => CashSessionCard(
          session: s,
          showBranch: showBranch,
          onReport: () => CashSessionActions.report(s.id),
          onRecord: () => _record(context, s),
          onClose: () => _close(context, s),
        ),
        null => _ClosedBox(b, onOpen: () => _open(context, b)),
      },
    );
  }
}

/// لا وردية مفتوحة: أي قبض أو صرف بهذا الفرع يُرفض حتى يُفتح الصندوق.
class _ClosedBox extends StatelessWidget {
  const _ClosedBox(this.b, {required this.onOpen});

  final CashBox b;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = CashSessionLabels.status('closed');
    final hasSuggestion = b.suggestedUsd > 0 || b.suggestedSyp > 0;
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpace.s1,
      children: [
        Wrap(
          spacing: AppSpace.s2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Semantics(
              header: true,
              child: Text('الصندوق · ${b.branchName ?? '—'}', style: UType.h3(color: c.ink)),
            ),
            StatusBadge(l.text, tone: l.tone),
          ],
        ),
        Text('لا توجد وردية مفتوحة بهذا الفرع. افتح الصندوق قبل أي قبض أو صرف.', style: UType.label(color: c.inkMuted)),
        if (hasSuggestion)
          Text(
            'الافتتاحي المقترح من آخر جرد: '
            '${Formatters.ltr(Formatters.usd(b.suggestedUsd))} · ${Formatters.ltr(Formatters.syp(b.suggestedSyp))}',
            style: UType.caption(color: c.inkMuted),
          ),
      ],
    );
    final button = UGButton(label: 'فتح الصندوق', icon: Icons.point_of_sale_rounded, onPressed: onOpen);
    return CutCard(
      child: LayoutBuilder(
        builder: (context, box) => box.maxWidth >= AppSize.splitMin
            ? Row(
                spacing: AppSpace.s4,
                children: [
                  Expanded(child: text),
                  button,
                ],
              )
            : Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: AppSpace.s3, children: [text, button]),
      ),
    );
  }
}

class _BoxShimmer extends StatelessWidget {
  const _BoxShimmer();

  @override
  Widget build(BuildContext context) => AppShimmer(
    child: ShimmerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpace.s3,
        children: [
          const ShimmerBox(width: AppSpace.s16 * 3, height: AppSpace.s6),
          const ShimmerBox(width: AppSpace.s16 * 4),
          ResponsiveGrid(
            maxColumns: 3,
            children: [for (var i = 0; i < 3; i++) const ShimmerBox(height: AppSpace.s16 * 2)],
          ),
        ],
      ),
    ),
  );
}
