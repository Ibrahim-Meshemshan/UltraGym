import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_gym_admin/core/error/failure.dart';
import 'package:ultra_gym_admin/core/networking/api_result.dart';
import 'package:ultra_gym_admin/core/router/routes.dart';

import '../../core/layout/shell_harness.dart';
import 'fake_dashboard_repository.dart';

const offline = Failure(type: FailureType.network, message: 'تعذّر الاتصال.');

void main() {
  final h = ShellHarness();
  setUp(h.setUp);
  tearDown(h.tearDown);

  Future<void> open(WidgetTester tester, {double width = 1280, bool reception = false}) =>
      h.pump(tester, width, session: reception ? receptionist : owner, at: Routes.dashboard);

  testWidgets('owner sees the day, money, cash boxes, alerts and expiring list', (tester) async {
    await open(tester);

    // التحية بالبانر (الاسم يظهر أيضاً بحساب القائمة الجانبية)
    expect(find.textContaining('، سامر'), findsOneWidget);
    expect(find.text('الأحد 8 تشرين الثاني'), findsOneWidget);
    expect(find.textContaining('دخول اليوم: 7'), findsOneWidget);
    // all branches (two active) ← no branch_id
    expect(h.dashboard.summaryCalls, [null]);

    expect(find.text('الأعضاء'), findsWidgets);
    expect(find.text(r'$20.00'), findsOneWidget);
    expect(find.text('على عضو واحد'), findsOneWidget);
    expect(find.text('المال · هذا الشهر'), findsOneWidget);
    expect(find.text(r'-$1.62'), findsOneWidget);
    expect(find.text(r'$314.50'), findsOneWidget);
    expect(find.text('فتح الصندوق'), findsOneWidget);
    expect(find.text('يوجد فرع صندوقه مغلق'), findsOneWidget);
    expect(find.text('أحمد الخطيب'), findsOneWidget);
    expect(find.text('بعد 3 أيام'), findsOneWidget);
    expect(find.text('ينتهي اليوم'), findsOneWidget);
    expect(find.text('بيع اشتراك'), findsOneWidget);
  });

  testWidgets('receptionist: no money card and no cash balance', (tester) async {
    h.dashboard.summaryResult = ApiSuccess(receptionData);
    await open(tester, reception: true);

    expect(find.text('المال · هذا الشهر'), findsNothing);
    expect(find.text('المتوقع بالدولار'), findsNothing);
    expect(find.text('الصناديق'), findsOneWidget);
    expect(find.text('تنبيهات'), findsNothing);
  });

  testWidgets('first load failure shows retry, then the page', (tester) async {
    h.dashboard.summaryResult = const ApiFailure(offline);
    await open(tester);
    expect(find.text('لا يوجد اتصال'), findsOneWidget);

    h.dashboard.summaryResult = ApiSuccess(ownerData);
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();
    expect(find.text(r'$20.00'), findsOneWidget);
  });

  testWidgets('empty expiring list is a short note, not an error', (tester) async {
    h.dashboard.expiringResult = const ApiSuccess([]);
    await open(tester);
    expect(find.text('لا اشتراكات تنتهي خلال 7 أيام.'), findsOneWidget);
  });

  testWidgets('stat cards and expiring rows open their pages', (tester) async {
    await open(tester);
    await tester.tap(find.text('الديون'));
    await tester.pumpAndSettle();
    expect(h.location, Routes.memberships);
    expect(h.router.routerDelegate.currentConfiguration.uri.queryParameters, {'has_debt': '1'});

    h.router.go(Routes.dashboard);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('أحمد الخطيب'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('أحمد الخطيب'));
    await tester.pumpAndSettle();
    expect(h.location, '/memberships/3');
  });

  for (final width in [360.0, 800.0, 1024.0]) {
    testWidgets('no overflow at ${width.toInt()}px', (tester) async {
      await open(tester, width: width);
      expect(tester.takeException(), isNull);
      expect(find.text('بيع اشتراك'), findsNothing);
      await tester.dragUntilVisible(
        find.text('تنتهي خلال 7 أيام'),
        find.byType(Scrollable).first,
        const Offset(0, -300),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
