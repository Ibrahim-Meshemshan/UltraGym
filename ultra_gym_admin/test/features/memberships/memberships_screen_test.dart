import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_gym_admin/core/error/failure.dart';
import 'package:ultra_gym_admin/core/networking/api_result.dart';
import 'package:ultra_gym_admin/core/router/routes.dart';
import 'package:ultra_gym_admin/core/widgets/app_tabs.dart';
import 'package:ultra_gym_admin/core/widgets/table/app_data_table.dart';
import 'package:ultra_gym_admin/core/widgets/table/filter_bar.dart';
import 'package:ultra_gym_admin/core/widgets/table/filter_controls.dart';
import 'package:ultra_gym_admin/features/memberships/domain/models/memberships_models.dart';
import 'package:ultra_gym_admin/features/memberships/presentation/widgets/membership_stats.dart';

import '../../core/layout/shell_harness.dart';
import 'fake_memberships_repository.dart';

const offline = Failure(type: FailureType.network, message: 'تعذّر الاتصال.');

void main() {
  final h = ShellHarness();
  setUp(h.setUp);
  tearDown(h.tearDown);

  Future<void> open(WidgetTester tester, {double width = 1280, String at = Routes.memberships}) =>
      h.pump(tester, width, at: at);

  Finder inTable(Finder f) => find.descendant(of: find.byType(AppDataTable<MembershipRow>), matching: f);
  Finder tab(String label) => find.descendant(of: find.byType(AppTabs), matching: find.textContaining(label));
  Finder chip(String label) => find.descendant(of: find.byType(FilterChoiceChips<String>), matching: find.text(label));

  testWidgets('stats, tabs with counts and rows from the server', (tester) async {
    await open(tester);
    expect(find.byType(MembershipStatsRow), findsOneWidget);
    expect(find.text('اشتراكات فعّالة'), findsOneWidget);
    expect(find.text('على اشتراك واحد'), findsOneWidget);
    expect(inTable(find.text('أحمد الخطيب')), findsOneWidget);
    expect(inTable(find.text('تدريب خاص شهري')), findsOneWidget);
    expect(inTable(find.text('حتى 23 تشرين الثاني · باقي 15 يوماً')), findsOneWidget);
    expect(inTable(find.text('يبدأ 9 كانون الأول')), findsOneWidget);
    expect(inTable(find.text(r'$20.00')), findsOneWidget);
    expect(inTable(find.text('لم يبدأ')), findsOneWidget);
    expect(find.text('الخطة: الكل'), findsOneWidget);
    expect(find.text('الفرع: الكل'), findsOneWidget);
    expect(h.memberships.calls.single.tab, MembershipsTab.all);
    expect(h.memberships.calls.single.branchId, isNull);
    expect(h.memberships.statsCalls, [null]);
  });

  testWidgets('status chip and search reach the server; clear resets', (tester) async {
    await open(tester);
    await tester.tap(chip('مجمّد'));
    await tester.pumpAndSettle();
    expect(h.memberships.calls.last.params['status'], 'frozen');

    await tester.enterText(find.descendant(of: find.byType(SearchField), matching: find.byType(TextField)), 'نور');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(h.memberships.calls.last.params['search'], 'نور');

    await tester.tap(find.text('مسح الفلاتر'));
    await tester.pumpAndSettle();
    expect(h.memberships.calls.last.params.keys, ['page', 'per_page']);
  });

  testWidgets('debts tab: own request, no filters, row opens the membership', (tester) async {
    await open(tester);
    await tester.tap(tab('عليها ديون'));
    await tester.pumpAndSettle();
    expect(h.memberships.calls.last.tab, MembershipsTab.debts);
    expect(find.byType(FilterBar), findsNothing);
    expect(inTable(find.text('نور الدين')), findsNothing);

    await tester.tap(inTable(find.text('أحمد الخطيب')));
    await tester.pumpAndSettle();
    expect(h.location, Routes.child(Routes.memberships, 3));
  });

  testWidgets('dashboard link opens the expiring tab; empty explains itself', (tester) async {
    await open(tester, at: '${Routes.memberships}?expiring_within_days=7');
    expect(h.memberships.calls.single.tab, MembershipsTab.expiring);
    expect(find.text('لا اشتراك ينتهي قريباً'), findsOneWidget);
  });

  testWidgets('debt card opens the debts tab', (tester) async {
    await open(tester);
    await tester.tap(find.text('مجموع الديون'));
    await tester.pumpAndSettle();
    expect(h.memberships.calls.last.tab, MembershipsTab.debts);
  });

  testWidgets('initial status from the link; empty with filters offers clearing', (tester) async {
    h.memberships.allResult = ApiSuccess(rows(const [], total: 0));
    await open(tester, at: '${Routes.memberships}?status=expired');
    expect(h.memberships.calls.single.params['status'], 'expired');
    expect(find.text('لا نتائج مطابقة'), findsOneWidget);
    await tester.tap(find.text('مسح الفلاتر').last);
    await tester.pumpAndSettle();
    expect(find.text('لا اشتراكات بعد'), findsOneWidget);
  });

  testWidgets('stats failure hides the cards but keeps the table; list failure retries', (tester) async {
    h.memberships.statsResult = const ApiFailure(offline);
    h.memberships.allResult = const ApiFailure(offline);
    await open(tester);
    expect(find.text('اشتراكات فعّالة'), findsNothing);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
    h.memberships.allResult = ApiSuccess(rows([ahmadDebt, nour]));
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();
    expect(inTable(find.text('أحمد الخطيب')), findsOneWidget);
  });

  testWidgets('plans failure hides only the plan filter', (tester) async {
    h.memberships.plansResult = const ApiFailure(offline);
    await open(tester);
    expect(find.text('الخطة: الكل'), findsNothing);
    expect(inTable(find.text('أحمد الخطيب')), findsOneWidget);
  });

  testWidgets('mobile shows cards instead of the table', (tester) async {
    await open(tester, width: 360);
    expect(find.byType(AppDataTable<MembershipRow>), findsNothing);
    expect(find.text('أحمد الخطيب'), findsOneWidget);
    expect(find.text('نور الدين'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final w in [360.0, 800.0, 1024.0, 1440.0]) {
    testWidgets('no overflow at ${w.toInt()}px', (tester) async {
      await open(tester, width: w);
      expect(tester.takeException(), isNull);
    });
  }
}
