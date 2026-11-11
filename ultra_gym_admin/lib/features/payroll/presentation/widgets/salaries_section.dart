import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../domain/models/payroll_models.dart';
import '../bloc/payroll_cubits.dart';
import 'salary_panel.dart';
import 'staff_list_card.dart';

/// الرواتب الشهرية (`Payroll.html`): الشهر، قائمة الموظفين بحالة راتب الشهر (مصروف / مستحق)، ولوحة الموظف المختار.
class SalariesSection extends StatelessWidget {
  const SalariesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final periods = PayrollTexts.recentPeriods(Formatters.clubTime(sl<ServerClock>().now()));
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ValueCubit<String>(periods.first)),
        BlocProvider(create: (_) => ValueCubit<int?>(null)),
      ],
      child: BlocBuilder<ValueCubit<String>, String>(
        builder: (context, period) => BlocProvider(
          key: ValueKey(period),
          create: (_) => sl<PayrollRosterCubit>(param1: period)..load(),
          child: _Body(periods: periods, period: period),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.periods, required this.period});

  final List<String> periods;
  final String period;

  @override
  Widget build(BuildContext context) {
    final roster = context.watch<PayrollRosterCubit>().state;
    final picked = context.watch<ValueCubit<int?>>().state;
    final staff = roster.data?.staff ?? const <PayrollStaff>[];
    final selected = staff.where((s) => s.id == picked).firstOrNull ?? staff.firstOrNull;
    final list = StaffListCard(
      header: FilterMenu<String>(
        label: 'الشهر',
        value: period,
        options: [for (final p in periods) (value: p, label: PayrollTexts.month(p))],
        onChanged: (v) {
          if (v != null) context.read<ValueCubit<String>>().set(v);
        },
      ),
      slice: roster,
      selectedId: selected?.id,
      onSelect: context.read<ValueCubit<int?>>().set,
      onRetry: context.read<PayrollRosterCubit>().load,
    );
    final panel = selected == null
        ? null
        : SalaryPanel(
            key: ValueKey((selected.id, period)),
            staff: selected,
            period: period,
            paid: roster.data?.paid[selected.id],
            onPaid: context.read<PayrollRosterCubit>().refresh,
          );
    return LayoutBuilder(
      builder: (context, box) => box.maxWidth >= AppSize.profileSplit
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpace.s5,
              children: [
                SizedBox(width: AppSize.staffListWidth, child: list),
                Expanded(child: panel ?? const SizedBox.shrink()),
              ],
            )
          : Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: AppSpace.s5, children: [list, ?panel]),
    );
  }
}
