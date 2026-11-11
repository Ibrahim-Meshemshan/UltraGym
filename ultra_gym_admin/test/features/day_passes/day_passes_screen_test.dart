import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_gym_admin/core/error/failure.dart';
import 'package:ultra_gym_admin/core/networking/api_result.dart';
import 'package:ultra_gym_admin/core/networking/paged.dart';
import 'package:ultra_gym_admin/core/router/routes.dart';
import 'package:ultra_gym_admin/core/widgets/form/form_fields.dart';
import 'package:ultra_gym_admin/core/widgets/form/form_pickers.dart';
import 'package:ultra_gym_admin/features/day_passes/domain/models/day_pass_models.dart';

import '../../core/layout/shell_harness.dart';
import 'fake_day_passes_repository.dart';

void main() {
  final h = ShellHarness();
  setUp(h.setUp);
  tearDown(h.tearDown);

  Future<void> open(WidgetTester tester, {double width = 1280, bool reception = false, String? at}) =>
      h.pump(tester, width, session: reception ? receptionist : owner, at: at ?? Routes.dayPasses);

  Future<void> tap(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  Finder inDialog(Finder f) => find.descendant(of: find.byType(Dialog).last, matching: f);
  Finder field(String name) => inDialog(
    find.descendant(
      of: find.byWidgetPredicate((w) => w is FormText && w.name == name),
      matching: find.byType(TextField),
    ),
  );

  final gender = find.byWidgetPredicate((w) => w is FormDropdown && w.name == 'gender');

  Future<void> openSale(WidgetTester tester) => tap(tester, find.text('بيع دخول يومي'));

  testWidgets('price of the main branch, totals for the filter, and the log', (tester) async {
    await open(tester);
    expect(h.dayPasses.priceCalls, [1], reason: 'all branches: the main branch price');
    expect(find.text('سعر الدخول اليومي · الفرع الرئيسي - المزة'), findsOneWidget);
    expect(find.text(r'$5.00'), findsWidgets);
    expect(find.text('أعضاء بلا اشتراك'), findsOneWidget);
    expect(find.text('خالد الأحمد'), findsOneWidget);
    expect(find.text('مجاني'), findsOneWidget);
    expect(find.text('زائر'), findsWidgets);
    expect(find.textContaining('آخر 31 يوماً'), findsWidgets);
  });

  testWidgets('no price yet: the owner is told to type it, the receptionist cannot sell', (tester) async {
    h.dayPasses.priceFor = (_) => ApiSuccess(DayPassPrice.fromJson(priceJson(price: null)));
    await open(tester);
    expect(find.textContaining('اكتبه عند البيع'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    h.dayPasses.priceFor = (_) => ApiSuccess(DayPassPrice.fromJson(priceJson(price: null, canChange: false)));
    await open(tester, reception: true);
    expect(find.textContaining('يحدده مالك النادي'), findsOneWidget);
    await tester.tap(find.text('بيع دخول يومي'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('sell to a visitor: price prefilled, full payment, receipt, then the log refreshes', (tester) async {
    await open(tester);
    await openSale(tester);
    await tester.enterText(field('visitor_name'), 'زائر تجريبي');
    await tester.enterText(field('visitor_phone'), '0933000111');
    await tap(tester, inDialog(find.text('تأكيد البيع')));
    final sale = h.dayPasses.sales.single;
    expect(sale.body, {
      'branch_id': 1,
      'visitor_name': 'زائر تجريبي',
      'visitor_phone': '0933000111',
      'payments': [
        {'currency': 'USD', 'amount': 5},
      ],
    });
    expect(sale.key, isNotEmpty);
    expect(inDialog(find.text('تم بيع الدخول اليومي')), findsOneWidget);
    expect(inDialog(find.text('طباعة الإيصال')), findsOneWidget);

    await tap(tester, inDialog(find.text('إغلاق')));
    expect(find.byType(Dialog), findsNothing);
    expect(h.dayPasses.queries, hasLength(2));
  });

  testWidgets('owner gives a free trial day: price 0 and no payment', (tester) async {
    await open(tester);
    await openSale(tester);
    await tester.enterText(field('visitor_name'), 'مروان');
    await tester.enterText(field('price_usd'), '0');
    await tester.enterText(field('usd'), '');
    await tap(tester, inDialog(find.text('تأكيد البيع')));
    expect(h.dayPasses.sales.single.body, {'branch_id': 1, 'visitor_name': 'مروان', 'price_usd': 0});
  });

  testWidgets('no amount for a paid pass stops locally; a server rejection stays in the form', (tester) async {
    await open(tester);
    await openSale(tester);
    await tester.enterText(field('visitor_name'), 'زائر');
    await tester.enterText(field('usd'), '');
    await tap(tester, inDialog(find.text('تأكيد البيع')));
    expect(inDialog(find.text('اكتب المبلغ بالدولار أو بالليرة.')), findsOneWidget);
    expect(h.dayPasses.sales, isEmpty);

    h.dayPasses.sellResult = const ApiFailure(
      Failure(type: FailureType.conflict, statusCode: 409, code: 'DAY_PASS_EXISTS', message: 'له دخول يومي اليوم'),
    );
    await tester.enterText(field('usd'), '5');
    await tap(tester, inDialog(find.text('تأكيد البيع')));
    expect(inDialog(find.text('له دخول يومي اليوم')), findsOneWidget);
  });

  testWidgets('a registered member is picked by search and sent as player_id', (tester) async {
    h.dayPasses.sellResult = ApiSuccess(DayPass.fromJson(dayPassJson(kind: 'player', name: 'سامي منتهٍ')));
    await open(tester);
    await openSale(tester);
    await tap(tester, inDialog(find.text('عضو مسجّل')));
    await tap(tester, inDialog(find.text('اختر العضو بالبحث')));
    await tester.enterText(find.descendant(of: find.byType(Dialog).last, matching: find.byType(TextField)), 'سامي');
    await tester.pumpAndSettle();
    await tap(tester, find.text('سامي منتهٍ').last);
    expect(inDialog(find.text('تغيير العضو')), findsOneWidget);
    await tap(tester, inDialog(find.text('تأكيد البيع')));
    expect(h.dayPasses.sales.single.body, {
      'branch_id': 1,
      'player_id': 7,
      'payments': [
        {'currency': 'USD', 'amount': 5},
      ],
    });
    expect(inDialog(find.textContaining('سُجّل دخوله تلقائياً')), findsOneWidget);
  });

  testWidgets('member mode without a member stops locally', (tester) async {
    await open(tester);
    await openSale(tester);
    await tap(tester, inDialog(find.text('عضو مسجّل')));
    await tap(tester, inDialog(find.text('تأكيد البيع')));
    expect(inDialog(find.text('اختر العضو بالبحث بالاسم أو الموبايل.')), findsOneWidget);
  });

  testWidgets('switching to a time-split branch reloads the price and asks for the gender', (tester) async {
    await open(tester);
    await openSale(tester);
    expect(inDialog(gender), findsNothing);
    await tap(tester, inDialog(find.text('الفرع الرئيسي - المزة')));
    await tap(tester, find.text('فرع المالكي').last);
    expect(h.dayPasses.priceCalls.last, 2);
    expect(inDialog(gender), findsOneWidget);
  });

  testWidgets('detail: payments with receipt, owner cancels with a reason and the log refreshes', (tester) async {
    await open(tester);
    await tap(tester, find.text('خالد الأحمد'));
    expect(inDialog(find.text('B1-2026-000007')), findsOneWidget);
    await tap(tester, inDialog(find.text('إلغاء الدخول')));
    await tester.enterText(inDialog(find.byType(TextField)), 'سُجّل بالخطأ');
    await tap(tester, inDialog(find.text('إلغاء الدخول')));
    expect(h.dayPasses.cancels.single, (id: 1, reason: 'سُجّل بالخطأ'));
    expect(find.byType(Dialog), findsNothing);
    expect(h.dayPasses.queries, hasLength(2));
  });

  testWidgets('receptionist sees the detail without cancel', (tester) async {
    await open(tester, reception: true);
    await tap(tester, find.text('خالد الأحمد'));
    expect(inDialog(find.text('طباعة الإيصال')), findsOneWidget);
    expect(inDialog(find.text('إلغاء الدخول')), findsNothing);
  });

  testWidgets('filters: kind menu, status chips, link period, clearing', (tester) async {
    await open(tester, at: '${Routes.dayPasses}?from=2026-11-01&to=2026-11-09');
    expect(find.text('2026-11-01 → 2026-11-09'), findsOneWidget);
    await tap(tester, find.text('النوع: الكل'));
    await tap(tester, find.widgetWithText(MenuItemButton, 'زوار'));
    expect(h.dayPasses.queries.last.query.filter('kind'), 'visitor');
    await tap(tester, find.text('الملغى'));
    expect(h.dayPasses.queries.last.query.filter('status'), 'cancelled');
    await tap(tester, find.text('مسح الفلاتر'));
    expect(h.dayPasses.queries.last.query.filters, isEmpty);
  });

  testWidgets('empty log invites to sell', (tester) async {
    h.dayPasses.listResult = const ApiSuccess(Paged());
    await open(tester);
    expect(find.text('لا دخول يومي بهذه الفترة'), findsOneWidget);
  });

  for (final w in [360.0, 800.0, 1024.0, 1440.0]) {
    testWidgets('no overflow at ${w.toInt()}px, with the sale and its result open', (tester) async {
      await open(tester, width: w);
      expect(tester.takeException(), isNull);
      await openSale(tester);
      await tester.enterText(field('visitor_name'), 'زائر تجريبي');
      await tap(tester, inDialog(find.text('تأكيد البيع')));
      expect(inDialog(find.text('تم بيع الدخول اليومي')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
