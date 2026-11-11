import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_gym_admin/core/error/failure.dart';
import 'package:ultra_gym_admin/core/networking/api_result.dart';
import 'package:ultra_gym_admin/core/networking/paged.dart';
import 'package:ultra_gym_admin/core/router/routes.dart';
import 'package:ultra_gym_admin/core/widgets/form/form_fields.dart';
import 'package:ultra_gym_admin/features/transactions/domain/models/transaction_models.dart';

import '../../core/layout/shell_harness.dart';
import 'fake_transactions_repository.dart';

void main() {
  final h = ShellHarness();
  setUp(h.setUp);
  tearDown(h.tearDown);

  Future<void> open(WidgetTester tester, {double width = 1280, String? at, bool asOwner = true}) =>
      h.pump(tester, width, at: at ?? Routes.transactions, session: asOwner ? owner : receptionist);

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

  /// `index`: 0 التصنيف، 1 صندوق الفرع.
  Future<void> choose(WidgetTester tester, int index, String option) async {
    await tap(tester, inDialog(find.byType(DropdownButtonFormField<int>)).at(index));
    await tap(tester, find.text(option).last);
  }

  Future<void> fillExpense(WidgetTester tester) async {
    await tap(tester, find.text('تسجيل إيراد أو مصروف'));
    await choose(tester, 0, 'صيانة أجهزة');
    await tester.enterText(field('amount'), '25');
    await tester.enterText(field('description'), 'تبديل حزام جهاز المشي');
  }

  testWidgets('owner: tabs, totals, rows with signs, reversed and reverse actions', (tester) async {
    await open(tester);
    expect(h.topTitle(tester), 'الصندوق والحركات');
    expect(find.text('دفتر الحركات'), findsOneWidget);
    expect(find.textContaining('481.00'), findsOneWidget);
    expect(find.textContaining('441.38'), findsOneWidget);
    expect(find.text('B1-2026-000029'), findsOneWidget);
    expect(find.text(r'+$30.00'), findsOneWidget);
    expect(find.text('−450,000 ل.س'), findsOneWidget);
    expect(find.text('كهرباء ومولدة'), findsOneWidget);
    expect(find.text('خالد يوسف'), findsOneWidget);
    expect(find.text('معكوسة'), findsOneWidget);
    expect(find.text('عكس'), findsNWidgets(3), reason: 'not the reversal nor the reversed entry');
    expect(find.textContaining('آخر 31 يوماً'), findsWidgets);
    expect(h.tx.queries.single.branchId, isNull);
  });

  testWidgets('the cash tab goes back to the sessions page, and its card records from that box', (tester) async {
    await open(tester);
    await tap(tester, find.text('الورديات'));
    expect(h.location, Routes.cashSessions);
    final before = h.cash.currentCalls.length;
    await tap(tester, find.text('مصروف أو إيراد'));
    expect(
      inDialog(find.text('صندوق الفرع *', findRichText: true)),
      findsNothing,
      reason: 'the branch is the box itself',
    );
    await choose(tester, 0, 'إيجار');
    await tester.enterText(field('amount'), '100');
    await tester.enterText(field('description'), 'إيجار الشهر');
    await tap(tester, inDialog(find.text('تسجيل')));
    expect(h.tx.records.single.body['branch_id'], 1);
    expect(h.cash.currentCalls.length, greaterThan(before), reason: 'the box reloads its live totals');
  });

  testWidgets('recording an expense: body, branch, key, then the ledger reloads', (tester) async {
    await open(tester);
    await fillExpense(tester);
    expect(inDialog(find.text('صندوق الفرع *', findRichText: true)), findsOneWidget);
    await tap(tester, inDialog(find.text('تسجيل')));
    final sent = h.tx.records.single;
    expect(sent.body, {
      'type': 'expense',
      'currency': 'USD',
      'amount': 25,
      'category_id': 3,
      'description': 'تبديل حزام جهاز المشي',
      'branch_id': 1,
    });
    expect(sent.key, isNotEmpty);
    expect(find.byType(Dialog), findsNothing);
    expect(h.tx.queries, hasLength(2));
  });

  testWidgets('income in pounds: switching direction clears the category and lists income ones only', (tester) async {
    await open(tester);
    await tap(tester, find.text('تسجيل إيراد أو مصروف'));
    await choose(tester, 0, 'إيجار');
    await tap(tester, inDialog(find.text('إيراد آخر')));
    await tap(tester, inDialog(find.byType(DropdownButtonFormField<int>)).first);
    expect(find.text('إيجار'), findsNothing);
    await tap(tester, find.text('بيع مكملات').last);
    await tap(tester, inDialog(find.text('ليرة')));
    await tester.enterText(field('amount'), '130,000');
    await tester.enterText(field('description'), 'علبة بروتين');
    await choose(tester, 1, 'فرع المالكي');
    await tap(tester, inDialog(find.text('تسجيل')));
    expect(h.tx.records.single.body, {
      'type': 'income',
      'currency': 'SYP',
      'amount': 130000,
      'category_id': 4,
      'description': 'علبة بروتين',
      'branch_id': 2,
    });
  });

  testWidgets('local checks, a server rejection stays in the form', (tester) async {
    h.tx.recordResult = const ApiFailure(
      Failure(type: FailureType.conflict, code: 'CASH_SESSION_REQUIRED', message: 'لا توجد وردية صندوق مفتوحة'),
    );
    await open(tester);
    await tap(tester, find.text('تسجيل إيراد أو مصروف'));
    await tester.enterText(field('amount'), '0');
    await tap(tester, inDialog(find.text('تسجيل')));
    expect(inDialog(find.text('اكتب مبلغاً أكبر من صفر.')), findsOneWidget);
    expect(inDialog(find.text('اختر التصنيف.')), findsOneWidget);
    expect(inDialog(find.text('اكتب وصفاً قصيراً للحركة.')), findsOneWidget);
    expect(h.tx.records, isEmpty);
    await tap(tester, inDialog(find.text('إلغاء')));
    await fillExpense(tester);
    await tap(tester, inDialog(find.text('تسجيل')));
    expect(inDialog(find.text('لا توجد وردية صندوق مفتوحة')), findsOneWidget);
    expect(inDialog(find.text('فتح الصندوق')), findsOneWidget);
  });

  testWidgets('no income categories: a note and a local failure; failing categories open nothing', (tester) async {
    h.tx.categoriesResult = ApiSuccess([FinanceCategory.fromJson(categoriesJson.first)]);
    await open(tester);
    await tap(tester, find.text('تسجيل إيراد أو مصروف'));
    await tap(tester, inDialog(find.text('إيراد آخر')));
    expect(inDialog(find.textContaining('لا تصنيفات إيراد بعد')), findsOneWidget);
    await tester.enterText(field('amount'), '5');
    await tester.enterText(field('description'), 'بيع');
    await tap(tester, inDialog(find.text('تسجيل')));
    expect(inDialog(find.textContaining('لا تصنيف لهذا النوع')), findsOneWidget);
    expect(h.tx.records, isEmpty);
    await tap(tester, inDialog(find.text('إلغاء')));

    h.tx.categoriesResult = const ApiFailure(Failure(type: FailureType.server, message: 'تعذّر التحميل'));
    await tap(tester, find.text('تسجيل إيراد أو مصروف'));
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('reversing from the row: reason required, then sent with a key and the ledger reloads', (tester) async {
    await open(tester);
    await tap(tester, find.text('عكس').first);
    expect(inDialog(find.text('B1-2026-000029')), findsOneWidget);
    expect(inDialog(find.textContaining('تُسجَّل حركة معاكسة')), findsOneWidget);
    await tap(tester, inDialog(find.text('تأكيد العكس')));
    expect(inDialog(find.text('اكتب سبب العكس.')), findsOneWidget);
    await tester.enterText(field('reason'), 'سُجّلت على العضو الخطأ');
    await tap(tester, inDialog(find.text('تأكيد العكس')));
    final sent = h.tx.reversals.single;
    expect((sent.id, sent.reason, sent.key.isNotEmpty), (29, 'سُجّلت على العضو الخطأ', true));
    expect(find.byType(Dialog), findsNothing);
    expect(h.tx.queries, hasLength(2));
  });

  testWidgets('reception: no reverse, recording still there', (tester) async {
    await open(tester, asOwner: false);
    expect(find.text('عكس'), findsNothing);
    expect(find.text('معكوسة'), findsOneWidget);
    expect(find.text('تسجيل إيراد أو مصروف'), findsOneWidget);
  });

  testWidgets('detail: reversed entry with its reversal receipt; a payment opens its membership', (tester) async {
    await open(tester);
    await tap(tester, find.text('B1-2026-000024'));
    expect(h.tx.details, [24]);
    expect(inDialog(find.textContaining('B1-2026-000025')), findsOneWidget);
    expect(inDialog(find.text('عكس الحركة')), findsNothing);
    await tap(tester, inDialog(find.text('طباعة الإيصال')));
    expect(h.tx.receipts, [24]);
    await tap(tester, inDialog(find.text('إغلاق')));

    await tap(tester, find.text('B1-2026-000029'));
    expect(inDialog(find.text('عكس الحركة')), findsOneWidget);
    expect(inDialog(find.text('390,000 ل.س')), findsOneWidget);
    await tap(tester, inDialog(find.text('فتح الاشتراك')));
    expect(h.location, Routes.child(Routes.memberships, 17));
  });

  testWidgets('filters: type, reversed toggle, clearing; the link column opens the member', (tester) async {
    await open(tester);
    await tap(tester, find.text('بلا المعكوسة'));
    expect(h.tx.queries.last.query.filter('include_reversed'), isFalse);
    await tap(tester, find.text('النوع: الكل'));
    await tap(tester, find.widgetWithText(MenuItemButton, 'مصروف'));
    expect(h.tx.queries.last.query.filter('type'), 'expense');
    await tap(tester, find.text('مسح الفلاتر'));
    expect(h.tx.queries.last.query.filters, isEmpty);
    await tap(tester, find.text('خالد يوسف'));
    expect(h.location, Routes.child(Routes.members, 6));
  });

  testWidgets('a link with filters opens them, and empty says what fills it', (tester) async {
    h.tx.listResult = const ApiSuccess(Paged());
    await open(tester, at: '${Routes.transactions}?type=expense');
    expect(h.tx.queries.single.query.filter('type'), 'expense');
    await tap(tester, find.text('مسح الفلاتر').first);
    expect(find.text('لا حركات بهذه الفترة'), findsOneWidget);
  });

  for (final w in [360.0, 800.0, 1024.0, 1440.0]) {
    testWidgets('no overflow at ${w.toInt()}px, with the record form and a detail open', (tester) async {
      await open(tester, width: w);
      expect(tester.takeException(), isNull);
      await fillExpense(tester);
      expect(tester.takeException(), isNull);
      await tap(tester, inDialog(find.text('إلغاء')));
      await tap(tester, find.text('B1-2026-000029').first);
      expect(inDialog(find.text('طباعة الإيصال')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
