import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../widgets/advances_section.dart';
import '../widgets/salaries_section.dart';

/// الرواتب والسلف (`Payroll.html` و `Advances.html`، للمالك بميزة `advanced_finance`):
/// تبويبا الرواتب الشهرية والسلف.
class PayrollScreen extends StatelessWidget {
  const PayrollScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(create: (_) => ValueCubit<int>(0), child: const _Body());
}

class _Body extends StatelessWidget {
  const _Body();

  static const _tabs = [(label: 'الرواتب الشهرية', count: null), (label: 'السلف', count: null)];

  @override
  Widget build(BuildContext context) {
    final tab = context.watch<ValueCubit<int>>().state;
    return AppPage(
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: AppTabs(tabs: _tabs, selected: tab, onSelect: context.read<ValueCubit<int>>().set),
          ),
        ),
        if (tab == 1) const AdvancesSection() else const SalariesSection(),
      ],
    );
  }
}
