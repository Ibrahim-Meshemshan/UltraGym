import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_gym_admin/core/error/failure.dart';
import 'package:ultra_gym_admin/core/networking/api_result.dart';
import 'package:ultra_gym_admin/core/networking/paged.dart';
import 'package:ultra_gym_admin/core/router/routes.dart';
import 'package:ultra_gym_admin/core/widgets/form/form_fields.dart';
import 'package:ultra_gym_admin/features/cash_sessions/domain/models/cash_session_models.dart';

import '../../core/layout/shell_harness.dart';
import 'fake_cash_sessions_repository.dart';

void main() {
  final h = ShellHarness();
  setUp(h.setUp);
  tearDown(h.tearDown);

  Future<void> open(WidgetTester tester, {double width = 1280, String? at}) =>
      h.pump(tester, width, at: at ?? Routes.cashSessions);

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
  String textOf(WidgetTester tester, Finder f) => tester.widget<TextField>(f).controller!.text;

  Future<void> chooseBranch(WidgetTester tester, String name) async {
    await tap(tester, find.text('كل الفروع'));
    await tap(tester, find.text(name).last);
  }

  testWidgets('all branches: the open box with live totals and breakdown, the closed one, then the history', (
    tester,
  ) async {
    await open(tester);
    expect(h.cash.currentCalls, unorderedEquals([1, 2]));
    expect(h.cash.details, [1], reason: 'only the open box asks for its breakdown');
    expect(find.text('المتوقع بالدرج الآن'), findsNWidgets(2));
    expect(find.text(r'+$391.50'), findsOneWidget);
    expect(find.text('دفعة اشتراك · 14'), findsOneWidget);
    expect(find.text('مصروف · 1'), findsOneWidget);
    expect(find.text('إغلاق الوردية بالجرد'), findsOneWidget);
    expect(find.text('الصندوق · فرع المالكي'), findsOneWidget);
    expect(find.text('فتح الصندوق'), findsOneWidget);
    expect(find.text('الورديات السابقة'), findsOneWidget);
    expect(h.cash.queries.single.status, 'closed');
    expect(find.text('#7'), findsOneWidget);
    expect(find.text('\u2066−\$5.00\u2069'), findsOneWidget, reason: 'compact badge: the signed amount only');
    expect(find.textContaining('+10,000'), findsOneWidget);
    expect(find.text('مطابق'), findsNWidgets(4), reason: 'the other currency of each row');
  });

  testWidgets('a chosen branch shows its box only and filters the history', (tester) async {
    await open(tester);
    await chooseBranch(tester, 'فرع المالكي');
    expect(h.cash.currentCalls.last, 2);
    expect(h.cash.queries.last.branchId, 2);
    expect(find.text('فتح الصندوق'), findsOneWidget);
    expect(find.text('المتوقع بالدرج الآن'), findsNothing);
  });

  testWidgets('opening the box: suggested amounts prefilled, branch and key sent, the box reloads', (tester) async {
    await open(tester);
    final before = h.cash.currentCalls.length;
    await tap(tester, find.text('فتح الصندوق'));
    expect(textOf(tester, field('opening_usd')), '75');
    expect(textOf(tester, field('opening_syp')), '325000');
    expect(inDialog(find.textContaining('جرد آخر وردية')), findsOneWidget);
    await tester.enterText(field('notes'), 'وردية المساء');
    await tap(tester, inDialog(find.text('فتح الوردية')));
    final sent = h.cash.opens.single;
    expect(sent.body, {'branch_id': 2, 'opening_usd': 75, 'opening_syp': 325000, 'notes': 'وردية المساء'});
    expect(sent.key, isNotEmpty);
    expect(find.byType(Dialog), findsNothing);
    expect(h.cash.currentCalls.length, before + 1);
    expect(h.cash.queries, hasLength(2), reason: 'the history refreshes too');
  });

  testWidgets('closing: expected and estimated difference while typing, then the result with its report', (
    tester,
  ) async {
    await open(tester);
    await tap(tester, find.text('إغلاق الوردية بالجرد'));
    expect(inDialog(find.text(r'$436.50')), findsOneWidget);
    await tester.enterText(field('closing_usd'), '433.5');
    await tester.enterText(field('closing_syp'), '291,000');
    await tester.pump();
    expect(inDialog(find.textContaining('عجز \u2066−\$3.00')), findsOneWidget);
    expect(inDialog(find.textContaining('زيادة \u2066+5,000')), findsOneWidget);
    await tap(tester, inDialog(find.text('إغلاق الوردية')));
    final sent = h.cash.closes.single;
    expect((sent.id, sent.key.isNotEmpty), (1, true));
    expect(sent.body, {'closing_usd': 433.5, 'closing_syp': 291000});

    expect(inDialog(find.textContaining('تم إغلاق الوردية')), findsOneWidget);
    expect(inDialog(find.text('الجرد')), findsNWidgets(2));
    await tap(tester, inDialog(find.text('تقرير الوردية')));
    expect(h.cash.reports, [1]);
    await tap(tester, inDialog(find.text('تم')));
    expect(find.byType(Dialog), findsNothing);
    expect(h.cash.queries, hasLength(2));
  });

  testWidgets('a count is required, and a server rejection stays in the form', (tester) async {
    h.cash.closeResult = const ApiFailure(
      Failure(type: FailureType.conflict, statusCode: 409, code: 'CONFLICT', message: 'الوردية مغلقة مسبقاً'),
    );
    await open(tester);
    await tap(tester, find.text('إغلاق الوردية بالجرد'));
    await tap(tester, inDialog(find.text('إغلاق الوردية')));
    expect(inDialog(find.text('اكتب المبلغ.')), findsNWidgets(2));
    expect(h.cash.closes, isEmpty);
    await tester.enterText(field('closing_usd'), '0');
    await tester.enterText(field('closing_syp'), '0');
    await tap(tester, inDialog(find.text('إغلاق الوردية')));
    expect(inDialog(find.text('الوردية مغلقة مسبقاً')), findsOneWidget);
  });

  testWidgets('history: difference toggle, clearing, and a row opens the session page', (tester) async {
    h.cash.detailFor = (id) =>
        ApiSuccess(CashSession.fromJson(sessionJson(id: id, status: 'closed', differenceUsd: -5, withBreakdown: true)));
    await open(tester);
    await tap(tester, find.text('بفرق فقط'));
    expect(h.cash.queries.last.query.filter('with_difference'), isTrue);
    await tap(tester, find.text('مسح الفلاتر'));
    expect(h.cash.queries.last.query.filters, isEmpty);

    await tap(tester, find.text('#7'));
    expect(h.location, Routes.child(Routes.cashSessions, 7));
    expect(h.cash.details.last, 7);
    expect(find.text('كل الورديات'), findsOneWidget);
    expect(find.text('الجرد'), findsNWidgets(2));
    expect(find.textContaining('أغلقها ريم العلي'), findsOneWidget);
    expect(find.text('إغلاق الوردية بالجرد'), findsNothing);
    expect(find.text('تقرير الوردية'), findsOneWidget);
  });

  testWidgets('session page: an open session closes from there; a bad id asks nothing', (tester) async {
    await open(tester, at: Routes.child(Routes.cashSessions, 1));
    expect(find.text('إغلاق الوردية بالجرد'), findsOneWidget);
    await tap(tester, find.text('إغلاق الوردية بالجرد'));
    await tester.enterText(field('closing_usd'), '436.5');
    await tester.enterText(field('closing_syp'), '286000');
    await tester.pump();
    expect(inDialog(find.text('مطابق')), findsNWidgets(2));
    final before = h.cash.details.length;
    await tap(tester, inDialog(find.text('إغلاق الوردية')));
    await tap(tester, inDialog(find.text('تم')));
    expect(h.cash.details.length, before + 1, reason: 'the page reloads after closing');

    await tester.pumpWidget(const SizedBox());
    h.cash.details.clear();
    await open(tester, at: '${Routes.cashSessions}/x');
    expect(find.text('الوردية غير موجودة'), findsOneWidget);
    // الطلب الوحيد من صفحة القائمة تحتها (go_router يبني المسار الأب): صندوقها المفتوح.
    expect(h.cash.details, [1]);
  });

  testWidgets('empty history says what fills it', (tester) async {
    h.cash.listResult = const ApiSuccess(Paged());
    await open(tester);
    expect(find.text('لا ورديات مغلقة بعد'), findsOneWidget);
  });

  for (final w in [360.0, 800.0, 1024.0, 1440.0]) {
    testWidgets('no overflow at ${w.toInt()}px, with the close form and its result open', (tester) async {
      await open(tester, width: w);
      expect(tester.takeException(), isNull);
      await tap(tester, find.text('إغلاق الوردية بالجرد'));
      await tester.enterText(field('closing_usd'), '433.5');
      await tester.enterText(field('closing_syp'), '291000');
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tap(tester, inDialog(find.text('إغلاق الوردية')));
      expect(inDialog(find.textContaining('تم إغلاق الوردية')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
