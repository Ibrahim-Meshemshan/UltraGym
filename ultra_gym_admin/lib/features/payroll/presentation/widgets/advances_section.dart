import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../domain/models/payroll_models.dart';
import '../bloc/payroll_cubits.dart';
import 'advances_table.dart';
import 'payroll_actions.dart';

/// السلف (`Advances.html`): الأرقام (المفتوحة، المتبقي للخصم، المسددة)، ملاحظة الخصم، "صرف سلفة"، والجدول.
class AdvancesSection extends StatelessWidget {
  const AdvancesSection({super.key});

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(create: (_) => sl<AdvancesCubit>()..load()),
      BlocProvider(create: (_) => sl<AdvanceStatsCubit>()..load()),
      BlocProvider(create: (_) => sl<PayrollStaffCubit>()..load()),
    ],
    child: const _Body(),
  );
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final staff = context.select<PayrollStaffCubit, List<PayrollStaff>>((s) => s.state.data ?? const []);
    Future<void> add() async {
      if (!await PayrollActions.addAdvance(context, staff) || !context.mounted) return;
      await (
        context.read<AdvancesCubit>().refresh(keepPage: true),
        context.read<AdvanceStatsCubit>().refresh(),
      ).wait;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.s4,
      children: [
        const _Stats(),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpace.s3,
          runSpacing: AppSpace.s3,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppSize.dialog),
              child: Text(
                'السلفة تخرج من الصندوق ولا تُحسب مصروفاً؛ تُخصم من الراتب بالمبلغ الذي تحدده عند الصرف.',
                style: UType.label(color: c.inkMuted),
              ),
            ),
            UGButton(label: 'صرف سلفة', icon: Icons.add_rounded, onPressed: add),
          ],
        ),
        AdvancesTable(staff: staff, onAdd: add),
      ],
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats();

  @override
  Widget build(BuildContext context) {
    final slice = context.watch<AdvanceStatsCubit>().state;
    if (slice.isFirstLoad) return const StatsShimmer();
    final s = slice.data;
    if (s == null) return const SizedBox.shrink();
    return ResponsiveGrid(
      maxColumns: 3,
      children: [
        AppStatCard(icon: Icons.request_quote_outlined, label: 'سلف مفتوحة', value: s.open.toDouble()),
        AppStatCard(
          icon: Icons.hourglass_bottom_rounded,
          label: 'المتبقي للخصم',
          value: s.openRemainingUsd.toDouble(),
          prefix: r'$',
          decimals: 2,
          note: 'من السلف المفتوحة',
        ),
        AppStatCard(icon: Icons.task_alt_rounded, label: 'سلف مسددة', value: s.settled.toDouble()),
      ],
    );
  }
}
