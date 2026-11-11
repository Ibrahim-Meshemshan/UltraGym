import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../branches/presentation/bloc/branch_scope_cubit.dart';
import '../bloc/sell_membership_cubit.dart';
import '../widgets/cash_fields.dart';
import '../widgets/sale_done.dart';
import '../widgets/sale_form_steps.dart';
import '../widgets/sale_steps.dart';
import '../widgets/sale_summary.dart';

/// بيع اشتراك (`SellMembership.html`) على `/memberships/new` (و `?player_id=` من ملف العضو):
/// العضو ← الخطة (+ المدرب) ← التاريخ والخصم ← الدفع، والملخص بجانبها يُسعَّر من الخادم مع كل تغيير.
class SellMembershipScreen extends StatelessWidget {
  const SellMembershipScreen({super.key, this.playerId});

  final int? playerId;

  @override
  Widget build(BuildContext context) {
    final (ready, branchId) = context.select<BranchScopeCubit, (bool, int?)>(
      (c) => (!c.state.branches.isFirstLoad, c.state.branchId),
    );
    if (!ready) return const AppPage(children: [_BackLink(), StatsShimmer(), DetailsShimmer()]);
    return BlocProvider(
      key: ValueKey(branchId),
      create: (_) => sl<SellMembershipCubit>(param1: (playerId: playerId, branchId: branchId))..load(),
      child: BlocBuilder<SellMembershipCubit, SellState>(
        buildWhen: (a, b) => a.result != b.result,
        builder: (context, s) => AppPage(
          children: [
            const _BackLink(),
            if (s.result case final r?) SaleDone(r) else _SaleForm(scoped: branchId != null),
          ],
        ),
      ),
    );
  }
}

/// النموذج كله فوق `AppFormCubit` واحد (يُنشأ من جديد مع كل بيع).
class _SaleForm extends StatelessWidget {
  const _SaleForm({required this.scoped});

  final bool scoped;

  @override
  Widget build(BuildContext context) {
    final isOwner = context.select<AuthBloc, bool>((b) => b.state.session?.isClubOwner ?? false);
    final main = context.read<BranchScopeCubit>().state.active.where((b) => b.isMain).firstOrNull;
    final branch = CashBranch.of(context, fallback: main?.id);
    return BlocProvider(
      create: (_) => AppFormCubit(initial: branch.initial),
      child: LayoutBuilder(
        builder: (context, box) {
          final steps = [
            const SaleMemberStep(),
            SalePlanStep(scoped: scoped),
            SaleDiscountStep(isOwner: isOwner),
            SalePaymentStep(branch: branch),
          ];
          final summary = SaleSummary(branch: branch);
          final split = box.maxWidth >= AppSize.splitMin;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpace.s4,
            children: [
              Text('بيع اشتراك', style: UType.h2(color: context.colors.ink)),
              _CashNotice(branch: branch),
              if (split)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpace.s4,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: AppSpace.s4,
                        children: steps,
                      ),
                    ),
                    Expanded(child: summary),
                  ],
                )
              else ...[
                ...steps,
                summary,
              ],
            ],
          );
        },
      ),
    );
  }
}

/// لا وردية مفتوحة بفرع البيع: تنبيه + "فتح الصندوق" (البيع بلا دفعات يبقى ممكناً، والخادم يحكم).
class _CashNotice extends StatelessWidget {
  const _CashNotice({required this.branch});

  final CashBranch branch;

  @override
  Widget build(BuildContext context) {
    final scope = context.watch<BranchScopeCubit>().state;
    return BlocBuilder<AppFormCubit, AppFormState>(
      buildWhen: (a, b) => a.values[CashBranch.key] != b.values[CashBranch.key],
      builder: (context, _) {
        final id = branch.idOf(context.read<AppFormCubit>()) ?? (scope.isSingle ? scope.active.first.id : null);
        final b = scope.active.where((b) => b.id == id).firstOrNull;
        if (b == null || b.cashSessionOpen) return const SizedBox.shrink();
        final c = context.colors;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.s4, vertical: AppSpace.s3),
          decoration: BoxDecoration(color: c.warningSoft, borderRadius: AppRadius.smAll),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpace.s3,
            runSpacing: AppSpace.s2,
            children: [
              Text('لا توجد وردية صندوق مفتوحة بـ${b.name}.', style: UType.body(color: c.warningInk).weight(600)),
              Text('افتح الصندوق لتسجيل الدفعات.', style: UType.body(color: c.warningInk)),
              UGButton(
                label: 'فتح الصندوق',
                icon: Icons.point_of_sale_rounded,
                kind: UButtonKind.secondary,
                onPressed: () => context.go(Routes.cashSessions),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BackLink extends StatelessWidget {
  const _BackLink();

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: TextButton.icon(
      onPressed: () => context.go(Routes.memberships),
      icon: const Icon(Icons.arrow_back_rounded, size: AppSize.iconSm),
      label: const Text('كل الاشتراكات'),
    ),
  );
}
