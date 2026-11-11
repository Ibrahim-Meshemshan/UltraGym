import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_gym_admin/core/error/failure.dart';
import 'package:ultra_gym_admin/core/networking/api_result.dart';
import 'package:ultra_gym_admin/core/router/routes.dart';
import 'package:ultra_gym_admin/core/widgets/table/pagination_bar.dart';
import 'package:ultra_gym_admin/features/reports/domain/models/reports_models.dart';

import '../../core/layout/shell_harness.dart';
import 'fake_reports_repository.dart';

void main() {
  final h = ShellHarness();
  setUp(h.setUp);
  tearDown(h.tearDown);

  Future<void> open(WidgetTester tester, {double width = 1366}) => h.pump(tester, width, at: Routes.reports);

  Future<void> tap(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  testWidgets('the list, then the first report: summary, sections, export', (tester) async {
    await open(tester);
    expect(h.topTitle(tester), 'التقارير');
    expect(find.text('التقارير المتاحة لك'), findsOneWidget);
    expect(find.text('الإيراد والمصروف وحركة النقد'), findsOneWidget);
    expect(find.text('للمتابعة والتجديد'), findsNothing, reason: 'only what the server lists');
    expect(h.reports.queries.single.key, 'financial_summary');
    expect(find.text('الأرباح والخسائر'), findsNWidgets(2));
    expect(find.text('من 2026-11-01 إلى 2026-11-10 · كل الفروع'), findsOneWidget);
    expect(find.text(r'-$77.12'), findsOneWidget);
    expect(find.text('كهرباء ومولدة'), findsOneWidget);
    expect(find.text(r'$34.62'), findsOneWidget);
    expect(find.text('لا بيانات بهذه الفترة.'), findsOneWidget);
    expect(find.text('PDF'), findsOneWidget);
    expect(find.text('Excel'), findsOneWidget);
    expect(find.textContaining('أول 2000 صف'), findsOneWidget);
  });

  testWidgets('daily cash draws the daily net; export sends the shown report and format', (tester) async {
    await open(tester);
    await tap(tester, find.text('الصندوق اليومي'));
    expect(h.reports.queries.last.key, 'daily_cash');
    expect(find.text('الصافي اليومي'), findsOneWidget);
    expect(find.text('الأحمر = صافٍ سالب.'), findsOneWidget);
    expect(find.text('-450,000'), findsOneWidget);
    await tap(tester, find.text('Excel'));
    expect(h.reports.exports.single.format, 'xlsx');
    expect(h.reports.exports.single.query.key, 'daily_cash');
  });

  testWidgets('branch filter while the top bar is on all branches', (tester) async {
    await open(tester);
    await tap(tester, find.text('الفرع: الكل'));
    await tap(tester, find.widgetWithText(MenuItemButton, 'فرع المالكي'));
    expect(h.reports.queries.last.branchId, 2);
    expect(h.reports.queries.last.key, 'financial_summary');
  });

  testWidgets('debts: no period, pages ask the server', (tester) async {
    await open(tester);
    await tap(tester, find.text('الديون').first);
    expect(find.textContaining('هذا الشهر'), findsNothing);
    expect(find.text('عمر الخطيب'), findsOneWidget);
    await tap(tester, find.descendant(of: find.byType(PaginationBar), matching: find.text('2')));
    expect(h.reports.queries.last.page, 2);
    expect(h.reports.queries.last.key, 'debts');
  });

  testWidgets('a report outside the plan: badge, message, no request', (tester) async {
    h.reports.catalogResult = ApiSuccess(
      ReportCatalog(
        reports: [for (final j in catalogRows(branchesAvailable: false)) ReportInfo.fromJson(j)],
        formats: const ['json'],
      ),
    );
    await open(tester);
    expect(find.text('التصدير غير متاح بخطتك'), findsOneWidget);
    expect(find.text('PDF'), findsNothing);
    expect(find.text('ليس ضمن باقتك'), findsOneWidget);
    final before = h.reports.queries.length;
    await tap(tester, find.text('مقارنة الفروع'));
    expect(find.text('هذا التقرير ليس ضمن باقتك'), findsOneWidget);
    expect(h.reports.queries.length, before);
  });

  testWidgets('a failed report shows the error with retry', (tester) async {
    h.reports.reportResult = const ApiFailure(Failure(type: FailureType.server, message: 'تعذّر بناء التقرير.'));
    await open(tester);
    expect(find.text('تعذّر بناء التقرير.'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
  });

  testWidgets('narrow: a report pill replaces the side list', (tester) async {
    await open(tester, width: 800);
    expect(find.text('التقارير المتاحة لك'), findsNothing);
    await tap(tester, find.text('التقرير: الأرباح والخسائر'));
    expect(find.widgetWithText(MenuItemButton, 'الكل'), findsNothing, reason: 'a report is always chosen');
    await tap(tester, find.widgetWithText(MenuItemButton, 'الحضور'));
    expect(h.reports.queries.last.key, 'attendance');
  });

  for (final w in [360.0, 800.0, 1024.0, 1440.0]) {
    testWidgets('no overflow at ${w.toInt()}px: profit and loss, then daily cash', (tester) async {
      await open(tester, width: w);
      expect(tester.takeException(), isNull);
      if (find.text('التقارير المتاحة لك').evaluate().isNotEmpty) {
        await tap(tester, find.text('الصندوق اليومي'));
      } else {
        await tap(tester, find.textContaining('التقرير:'));
        await tap(tester, find.widgetWithText(MenuItemButton, 'الصندوق اليومي'));
      }
      expect(tester.takeException(), isNull);
    });
  }
}
