import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../branches/presentation/bloc/branch_scope_cubit.dart';
import '../../data/repo/reports_repository.dart';
import '../../domain/models/reports_models.dart';
import '../bloc/reports_cubits.dart';
import 'report_body.dart';

/// عارض التقرير المختار: شريط الفترة والفرع والتصدير، ثم التقرير (Cubit جديد لكل فترة / فرع / صفحة).
/// فرع الشريط العلوي يغلب فلتر الفرع هنا، والحبة تظهر فقط حين يكون على "كل الفروع".
class ReportView extends StatelessWidget {
  const ReportView({
    super.key,
    required this.info,
    required this.query,
    required this.canExport,
    required this.onQuery,
    this.picker,
  });

  final ReportInfo info;
  final ReportQuery query;
  final bool canExport;
  final ValueChanged<ReportQuery> onQuery;

  /// حبة اختيار التقرير على الشاشات الضيقة.
  final Widget? picker;

  @override
  Widget build(BuildContext context) {
    final scope = context.watch<BranchScopeCubit>().state;
    final effective = ReportQuery(
      key: info.key,
      from: info.usesPeriod ? query.from : null,
      to: info.usesPeriod ? query.to : null,
      branchId: info.usesBranch ? scope.branchId ?? query.branchId : null,
      page: query.page,
    );
    final branchFilter = info.usesBranch && scope.branchId == null && scope.canChoose;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.s4,
      children: [
        Wrap(
          spacing: AppSpace.s2,
          runSpacing: AppSpace.s2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ?picker,
            if (info.usesPeriod)
              FilterDateRange(
                from: query.from,
                to: query.to,
                emptyLabel: 'هذا الشهر',
                onChanged: (from, to) => onQuery(query.copyWith(period: (from, to))),
              ),
            if (branchFilter)
              FilterMenu<int>(
                label: 'الفرع',
                value: query.branchId,
                options: [for (final b in scope.active) (value: b.id, label: b.name)],
                onChanged: (v) => onQuery(query.copyWith(branch: (v,))),
              ),
            if (info.available) _Export(query: effective, canExport: canExport),
          ],
        ),
        if (!info.available)
          const EmptyState(
            icon: Icons.workspace_premium_rounded,
            title: 'هذا التقرير ليس ضمن باقتك',
            message: 'مقارنة الفروع ضمن التقارير المتقدمة. تواصل مع UltraGym لإضافتها لناديك.',
          )
        else
          BlocProvider(
            key: ValueKey(effective),
            create: (_) => sl<ReportCubit>(param1: effective)..load(),
            child: Builder(
              builder: (context) {
                final cubit = context.watch<ReportCubit>();
                return SliceView<ReportResult>(
                  slice: cubit.state,
                  onRetry: cubit.load,
                  loading: const Column(spacing: AppSpace.s4, children: [StatsShimmer(), TableShimmer(columns: 4)]),
                  builder: (context, r) => ReportBody(
                    report: r,
                    canExport: canExport,
                    onPage: (p) => onQuery(query.copyWith(page: p)),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

/// زرّا PDF و Excel، أو "التصدير غير متاح بخطتك" (`meta.formats` بلا pdf/xlsx).
class _Export extends StatelessWidget {
  const _Export({required this.query, required this.canExport});

  final ReportQuery query;
  final bool canExport;

  static Future<void> _open(ReportQuery q, String format) async {
    switch (await sl<ReportsRepository>().export(q, format)) {
      case ApiSuccess(:final data):
        await BlobOpener.open(data);
      case ApiFailure(:final failure):
        AppSnackbar.show(failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!canExport) return const StatusBadge('التصدير غير متاح بخطتك', tone: UTone.neutral);
    return BlocProvider(
      create: (_) => ValueCubit<String?>(null),
      child: Builder(
        builder: (context) {
          final busy = context.watch<ValueCubit<String?>>();
          Future<void> export(String format) async {
            busy.set(format);
            await _open(query, format);
            if (!busy.isClosed) busy.set(null);
          }

          return Wrap(
            spacing: AppSpace.s2,
            children: [
              UGButton(
                label: 'PDF',
                icon: Icons.picture_as_pdf_rounded,
                kind: UButtonKind.secondary,
                onPressed: busy.state == null ? () => export('pdf') : null,
              ),
              UGButton(
                label: 'Excel',
                icon: Icons.table_view_rounded,
                kind: UButtonKind.secondary,
                onPressed: busy.state == null ? () => export('xlsx') : null,
              ),
            ],
          );
        },
      ),
    );
  }
}
