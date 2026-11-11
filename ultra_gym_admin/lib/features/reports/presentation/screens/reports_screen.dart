import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../branches/presentation/bloc/branch_scope_cubit.dart';
import '../../domain/models/reports_models.dart';
import '../bloc/reports_cubits.dart';
import '../widgets/report_list.dart';
import '../widgets/report_view.dart';

/// التقارير (`Reports.html`): قائمة التقارير المتاحة (من `GET reports`، فالاستقبال يرى غير المالية فقط) بجانب
/// عارض واحد يرسم أي تقرير، مع الفترة والفرع والتصدير PDF / Excel (ميزة `reports_export`).
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(create: (_) => sl<ReportCatalogCubit>()..load()),
      BlocProvider(create: (_) => ValueCubit<ReportQuery?>(null)),
    ],
    child: const _Body(),
  );
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<ReportCatalogCubit>();
    final ready = context.select<BranchScopeCubit, bool>((c) => !c.state.branches.isFirstLoad);
    return AppPage(
      children: [
        SliceView<ReportCatalog>(
          slice: catalog.state,
          onRetry: catalog.load,
          loading: const Column(spacing: AppSpace.s4, children: [StatsShimmer(), TableShimmer(columns: 4)]),
          isEmpty: (c) => c.reports.isEmpty,
          empty: const EmptyState(
            icon: Icons.bar_chart_rounded,
            title: 'لا تقارير متاحة لك',
            message: 'التقارير المالية للمالك. اطلب من مالك النادي ما تحتاجه.',
          ),
          builder: (context, c) => ready ? _Layout(c) : const TableShimmer(columns: 4),
        ),
      ],
    );
  }
}

class _Layout extends StatelessWidget {
  const _Layout(this.catalog);

  final ReportCatalog catalog;

  @override
  Widget build(BuildContext context) {
    final picked = context.watch<ValueCubit<ReportQuery?>>().state;
    final query = picked ?? ReportQuery(key: (catalog.reports.where((r) => r.available).firstOrNull ?? catalog.reports.first).key);
    final info = catalog.reports.where((r) => r.key == query.key).firstOrNull ?? catalog.reports.first;
    void select(String key) => context.read<ValueCubit<ReportQuery?>>().set(query.copyWith(key: key));
    return LayoutBuilder(
      builder: (context, box) {
        final wide = box.maxWidth >= AppSize.profileSplit;
        final view = ReportView(
          info: info,
          query: query,
          canExport: catalog.canExport,
          onQuery: context.read<ValueCubit<ReportQuery?>>().set,
          picker: wide ? null : ReportPicker(reports: catalog.reports, selected: info.key, onSelect: select),
        );
        if (!wide) return view;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpace.s4,
          children: [
            SizedBox(
              width: AppSize.reportsListWidth,
              child: ReportList(reports: catalog.reports, selected: info.key, onSelect: select),
            ),
            Expanded(child: view),
          ],
        );
      },
    );
  }
}
