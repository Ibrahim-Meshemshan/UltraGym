import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_gym_admin/core/core.dart';
import 'package:ultra_gym_admin/features/billing/domain/models/billing_models.dart';

import '../../core/layout/shell_harness.dart';
import '../../helpers/app_fonts.dart';
import 'fake_billing_repository.dart';

void main() {
  final h = ShellHarness();
  setUpAll(() async {
    await loadAppFonts();
    Formatters.init('Asia/Damascus');
  });
  setUp(h.setUp);
  tearDown(h.tearDown);

  Future<void> open(WidgetTester tester, {double width = 1280, String at = Routes.billing}) =>
      h.pump(tester, width, at: at);

  Future<void> tap(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  Finder inDialog(String text) => find.descendant(of: find.byType(Dialog), matching: find.text(text));

  testWidgets('subscription: plan, status, days left, period, features, owed with overdue badge, history', (tester) async {
    await open(tester);
    expect(find.text('اشتراك النادي والفواتير'), findsOneWidget);
    expect(find.text('Pro · شهري'), findsWidgets);
    expect(find.text('فعّال'), findsOneWidget);
    expect(find.text('ينتهي بعد 19 يوماً'), findsOneWidget);
    expect(find.text('${Formatters.ltr('2026-11-01')} ← ${Formatters.ltr('2026-11-30')}'), findsWidgets);
    expect(find.textContaining('دخول QR'), findsOneWidget);
    expect(find.textContaining('هوية مخصصة'), findsNothing, reason: 'not in the plan');
    expect(find.text('\$49.00'), findsWidgets);
    expect(find.text('فاتورة متأخرة'), findsOneWidget);
    expect(find.text('الاشتراكات السابقة'), findsOneWidget);
    expect(find.text('منتهٍ (قراءة فقط)'), findsOneWidget);
  });

  testWidgets('usage: meters with limits, unlimited staff, storage from entitlements', (tester) async {
    await open(tester);
    expect(find.text('الاستخدام مقابل الحدود'), findsOneWidget);
    expect(find.text('128 / 200'), findsOneWidget);
    expect(find.text('2 / ∞'), findsOneWidget);
    expect(find.text('بلا حد بباقتك'), findsOneWidget);
    expect(find.text('2 / 10'), findsOneWidget);
    expect(find.text('1 GB'), findsOneWidget);
  });

  testWidgets('no subscription (live demo): invitation opens support; usage failure hides its card', (tester) async {
    h.admin.billing
      ..overviewResult = ApiSuccess(BillingOverview.fromJson(overviewJson()))
      ..usageResult = const ApiFailure(Failure(type: FailureType.server, message: 'x'));
    await open(tester);
    expect(find.text('لا يوجد اشتراك مسجّل للنادي بعد'), findsOneWidget);
    expect(find.text('الاستخدام مقابل الحدود'), findsNothing);
    await tap(tester, find.text('فتح الدعم الفني'));
    expect(h.router.routerDelegate.currentConfiguration.uri.toString(), Routes.billingSupport);
    expect(find.text('التذاكر'), findsOneWidget);
  });

  testWidgets('grace subscription shows the grace end', (tester) async {
    h.admin.billing.overviewResult = ApiSuccess(
      BillingOverview.fromJson(overviewJson(current: platformSubJson(status: 'grace'))),
    );
    await open(tester);
    expect(find.text('فترة سماح'), findsOneWidget);
    expect(find.text('السماح حتى ${Formatters.ltr('2026-12-07')}'), findsOneWidget);
    expect(find.text('نهاية فترة السماح'), findsOneWidget);
    expect(find.text('لا مستحقات'), findsOneWidget);
  });

  testWidgets('invoices: rows, overdue badge, remaining, filters and search', (tester) async {
    await open(tester);
    expect(find.text('فواتير المنصة'), findsOneWidget);
    expect(find.text('INV-2026-0007'), findsOneWidget);
    expect(find.text('متأخرة'), findsOneWidget);
    expect(find.text('مدفوعة'), findsWidgets);

    await tap(tester, find.text('المتأخرة'));
    expect(h.admin.billing.queries.last.filter('overdue'), isTrue);
    await tap(tester, find.text('بانتظار الدفع'));
    expect(h.admin.billing.queries.last.filter('status'), 'pending');
    await tester.enterText(find.byType(TextField).first, '0007');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(h.admin.billing.queries.last.search, '0007');
  });

  testWidgets('invoice dialog: amounts, payments, PDF, close', (tester) async {
    await open(tester);
    await tap(tester, find.text('INV-2026-0007'));
    expect(h.admin.billing.opened, [7]);
    expect(inDialog('مدفوعة جزئياً'), findsOneWidget);
    expect(inDialog('\$29.00'), findsOneWidget);
    expect(find.textContaining('حوالة بنكية'), findsOneWidget);
    expect(find.textContaining('TRX-55'), findsOneWidget);
    await tap(tester, find.text('تنزيل PDF'));
    expect(h.admin.billing.pdfs, [7]);
    await tap(tester, find.text('إغلاق'));
    expect(find.byType(Dialog), findsNothing);

    await tap(tester, find.widgetWithText(TextButton, 'PDF').last);
    expect(h.admin.billing.pdfs, [7, 6]);
  });

  testWidgets('invoice without payments says so', (tester) async {
    h.admin.billing.invoiceResult = ApiSuccess(PlatformInvoice.fromJson(invoiceJson()));
    await open(tester);
    await tap(tester, find.text('INV-2026-0007'));
    expect(find.text('لا دفعات مسجّلة على هذه الفاتورة بعد.'), findsOneWidget);
  });

  testWidgets('notification link ?invoice_id= opens the invoice over the first tab', (tester) async {
    await open(tester, at: Routes.billingInvoice(12));
    expect(h.admin.billing.opened, [12]);
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('فواتير المنصة'), findsOneWidget);
  });

  testWidgets('empty invoices invite; errors retry', (tester) async {
    h.admin.billing
      ..invoicesResult = ApiSuccess(pageOf(<PlatformInvoice>[]))
      ..overviewResult = const ApiFailure(Failure(type: FailureType.server, message: 'تعذّر تحميل الاشتراك'));
    await open(tester);
    expect(find.text('لا فواتير بعد'), findsOneWidget);
    expect(find.text('تعذّر تحميل الاشتراك'), findsOneWidget);
    h.admin.billing.overviewResult = ApiSuccess(BillingOverview.fromJson(overviewJson(current: platformSubJson())));
    await tap(tester, find.text('إعادة المحاولة'));
    expect(find.text('فعّال'), findsOneWidget);
  });

  for (final w in [360.0, 800.0, 1024.0, 1440.0]) {
    testWidgets('fits at ${w.toInt()}px with the invoice dialog', (tester) async {
      await open(tester, width: w);
      expect(find.text('INV-2026-0007'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tap(tester, find.text('INV-2026-0007'));
      expect(tester.takeException(), isNull);
    });
  }
}
