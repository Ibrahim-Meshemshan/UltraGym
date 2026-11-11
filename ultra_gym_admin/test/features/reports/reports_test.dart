import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_gym_admin/features/reports/domain/models/reports_models.dart';
import 'package:ultra_gym_admin/features/reports/presentation/bloc/reports_cubits.dart';

import 'fake_reports_repository.dart';

void main() {
  group('models', () {
    test('catalog rows, export formats, branch use', () {
      final rows = [for (final j in catalogRows()) ReportInfo.fromJson(j)];
      expect(rows[3].usesPeriod, isFalse);
      expect(rows[4].usesBranch, isFalse);
      expect(rows[0].usesBranch, isTrue);
      expect(ReportCatalog(reports: rows, formats: const ['json']).canExport, isFalse);
      expect(ReportCatalog(reports: rows, formats: const ['json', 'xlsx']).canExport, isTrue);
    });

    test('a report keeps the server order, numeric columns, and pagination', () {
      final r = ReportResult.fromJson(reportJson('debts', lastPage: 2));
      expect(r.summary.map((s) => s.label), ['إجمالي الديون', 'بالليرة', 'الاشتراكات', 'اللاعبون']);
      expect(r.summary[2].value, '1');
      expect(r.sections.single.numeric, {3, 4, 5});
      expect(r.sections.single.rows.single[5], r'$20.00');
      expect(r.pagination?.lastPage, 2);
      expect(r.from, DateTime(2026, 11, 1));
      expect(ReportResult.fromJson(reportJson('financial_summary')).pagination, isNull);
    });

    test('charts only for daily cash and attendance', () {
      final chart = ReportTexts.chart(ReportResult.fromJson(reportJson('daily_cash')))!;
      expect(chart.title, 'الصافي اليومي');
      expect(chart.bars.map((b) => b.label), ['11-07', '11-08']);
      expect(chart.bars.first.value, -1.62);
      expect(ReportTexts.chart(ReportResult.fromJson(reportJson('debts'))), isNull);
    });

    test('query params: period and branch only when set; export sends the format without paging', () {
      const q = ReportQuery(key: 'debts');
      expect(q.params(), {'page': 1, 'per_page': 50});
      final full = q.copyWith(period: (DateTime(2026, 10, 1), DateTime(2026, 10, 31)), branch: (2,), page: 3);
      expect(full.params(), {'from': '2026-10-01', 'to': '2026-10-31', 'branch_id': 2, 'page': 3, 'per_page': 50});
      expect(full.params(format: 'pdf'), {'from': '2026-10-01', 'to': '2026-10-31', 'branch_id': 2, 'format': 'pdf'});
      expect(full.copyWith(key: 'attendance').page, 1, reason: 'a new report starts at page 1');
      expect(full.copyWith(branch: (null,)).branchId, isNull);
    });
  });

  test('cubits load the catalog and one report', () async {
    final repo = FakeReportsRepository();
    final catalog = ReportCatalogCubit(repo);
    final report = ReportCubit(repo, const ReportQuery(key: 'daily_cash'));
    addTearDown(catalog.close);
    addTearDown(report.close);
    await catalog.load();
    await report.load();
    expect(catalog.state.data!.reports, hasLength(5));
    expect(report.state.data!.title, 'الصندوق اليومي');
    expect(repo.queries.single.key, 'daily_cash');
  });
}
