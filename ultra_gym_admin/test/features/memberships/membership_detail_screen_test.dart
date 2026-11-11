import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_gym_admin/core/error/failure.dart';
import 'package:ultra_gym_admin/core/networking/api_result.dart';
import 'package:ultra_gym_admin/core/router/routes.dart';
import 'package:ultra_gym_admin/core/utils/json_x.dart';
import 'package:ultra_gym_admin/core/widgets/app_tabs.dart';
import 'package:ultra_gym_admin/features/memberships/domain/models/membership_detail_models.dart';

import '../../core/layout/shell_harness.dart';
import 'fake_membership_detail_repository.dart';

const offline = Failure(type: FailureType.network, message: 'تعذّر الاتصال.');

void main() {
  final h = ShellHarness();
  setUp(h.setUp);
  tearDown(h.tearDown);

  final at = Routes.child(Routes.memberships, 3);

  Future<void> open(WidgetTester tester, {double width = 1280, bool reception = false, String? path}) =>
      h.pump(tester, width, session: reception ? receptionist : owner, at: path ?? at);

  void serve(Json json) => h.membership.detailResult = ApiSuccess(MembershipDetail.fromJson(json));

  Finder inDialog(Finder f) => find.descendant(of: find.byType(Dialog), matching: f);

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text).first);
    await tester.tap(find.text(text).first);
    await tester.pumpAndSettle();
  }

  Future<void> fill(WidgetTester tester, int index, String text) =>
      tester.enterText(inDialog(find.byType(TextField)).at(index), text);

  testWidgets('header, facts, account and payments from the server', (tester) async {
    await open(tester);
    expect(h.membership.detailCalls, [3]);
    expect(find.text('تدريب خاص شهري'), findsOneWidget);
    expect(find.text('أحمد الخطيب'), findsOneWidget);
    expect(find.text('كابتن مازن'), findsOneWidget);
    expect(find.text(r'$12.00'), findsOneWidget); // عمولة المدرب للمالك
    expect(find.text('استُخدم 0 من 2'), findsOneWidget);
    expect(find.text(r'$60.00'), findsWidgets);
    expect(find.text(r'$20.00'), findsOneWidget);
    expect(find.text('B1-2026-000003'), findsOneWidget);
    expect(find.text('ريم العلي'), findsOneWidget);
    expect(find.textContaining('سداد الدين'), findsOneWidget);
    expect(find.text('إلغاء الاشتراك'), findsOneWidget);
    expect(find.text('فك التجميد'), findsNothing);
  });

  testWidgets('receptionist: no cancel and no commission', (tester) async {
    await open(tester, reception: true);
    expect(find.text('إلغاء الاشتراك'), findsNothing);
    expect(find.text('عمولة المدرب'), findsNothing);
    expect(find.text('تجميد'), findsOneWidget);
  });

  testWidgets('pay debt: both currencies, branch chosen, one key, then refresh', (tester) async {
    await open(tester);
    await tester.tap(find.textContaining('سداد الدين'));
    await tester.pumpAndSettle();
    await fill(tester, 0, '10');
    await fill(tester, 1, '65,000');
    await tester.tap(inDialog(find.text('تسجيل الدفعة')));
    await tester.pumpAndSettle();
    final sent = h.membership.sent.single;
    expect(sent.action, 'pay');
    expect(sent.body, {
      'payments': [
        {'currency': 'USD', 'amount': 10},
        {'currency': 'SYP', 'amount': 65000},
      ],
      'branch_id': 1,
    });
    expect(sent.key, isNotEmpty);
    expect(h.membership.detailCalls, [3, 3]);
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('pay debt: no amount is refused locally; no cash session offers to open it', (tester) async {
    await open(tester);
    await tester.tap(find.textContaining('سداد الدين'));
    await tester.pumpAndSettle();
    await tester.tap(inDialog(find.text('تسجيل الدفعة')));
    await tester.pumpAndSettle();
    expect(find.text('اكتب المبلغ بالدولار أو بالليرة.'), findsOneWidget);
    expect(h.membership.sent, isEmpty);

    h.membership.actionResult = const ApiFailure(cashRequired);
    await fill(tester, 0, '5');
    await tester.tap(inDialog(find.text('تسجيل الدفعة')));
    await tester.pumpAndSettle();
    expect(find.text('لا توجد وردية صندوق مفتوحة بهذا الفرع'), findsOneWidget);
    await tester.tap(find.text('فتح الصندوق'));
    await tester.pumpAndSettle();
    expect(h.location, Routes.cashSessions);
  });

  testWidgets('freeze sends days and reason', (tester) async {
    await open(tester);
    await tapText(tester, 'تجميد');
    expect(find.textContaining('استُخدم 0 من 2 مرات'), findsOneWidget);
    await fill(tester, 0, '5');
    await fill(tester, 1, 'سفر');
    await tester.tap(inDialog(find.text('تجميد')));
    await tester.pumpAndSettle();
    final sent = h.membership.sent.single;
    expect(sent.action, 'freeze');
    expect(sent.body, {'days': 5, 'reason': 'سفر'});
  });

  testWidgets('frozen: unfreeze instead of freeze, and the freeze history', (tester) async {
    serve(ahmadDetailJson(status: 'frozen', label: 'مجمّد'));
    await open(tester);
    expect(find.text('تجميد'), findsNothing);
    await tapText(tester, 'فك التجميد');
    await tester.tap(inDialog(find.text('فك التجميد')).last);
    await tester.pumpAndSettle();
    expect(h.membership.sent.single.action, 'unfreeze');

    await tester.tap(find.descendant(of: find.byType(AppTabs), matching: find.text('التجميدات')));
    await tester.pumpAndSettle();
    expect(find.text('سفر'), findsOneWidget);
    expect(find.text('2026-11-12'), findsOneWidget);
  });

  testWidgets('cancel: reason required, optional refund from the chosen branch', (tester) async {
    await open(tester);
    await tapText(tester, 'إلغاء الاشتراك');
    await tester.tap(inDialog(find.text('إلغاء الاشتراك')).last);
    await tester.pumpAndSettle();
    expect(find.text('اكتب سبب الإلغاء.'), findsOneWidget);
    await fill(tester, 0, 'انتقل لمدينة أخرى');
    await fill(tester, 2, '130000');
    await tester.tap(inDialog(find.text('إلغاء الاشتراك')).last);
    await tester.pumpAndSettle();
    final sent = h.membership.sent.single;
    expect(sent.action, 'cancel');
    expect(sent.body, {
      'reason': 'انتقل لمدينة أخرى',
      'refunds': [
        {'currency': 'SYP', 'amount': 130000},
      ],
      'branch_id': 1,
    });
  });

  testWidgets('renew shows the quote, keeps the trainer and opens the new membership', (tester) async {
    await open(tester);
    await tapText(tester, 'تجديد');
    expect(find.text('2026-11-24 → 2026-12-23'), findsOneWidget);
    expect(find.text('يمكن دفع جزء منه، والباقي يُسجَّل ديناً.'), findsOneWidget);
    await fill(tester, 0, '60');
    await tester.tap(inDialog(find.text('تجديد')).last);
    await tester.pumpAndSettle();
    final sent = h.membership.sent.single;
    expect(sent.body, {
      'payments': [
        {'currency': 'USD', 'amount': 60},
      ],
      'branch_id': 1,
      'trainer_id': 1,
    });
    expect(h.location, Routes.child(Routes.memberships, 14));
  });

  testWidgets('sessions membership records a session with a note', (tester) async {
    serve(ahmadDetailJson(type: 'sessions'));
    await open(tester);
    expect(find.text('4 / 12'), findsOneWidget);
    await tapText(tester, 'تسجيل جلسة');
    await fill(tester, 0, 'حصة إضافية');
    await tester.tap(inDialog(find.text('تسجيل الجلسة')));
    await tester.pumpAndSettle();
    expect(h.membership.sent.single.body, {'note': 'حصة إضافية', 'branch_id': 1});
  });

  testWidgets('cancelled: notice and no actions but the invoice', (tester) async {
    serve(ahmadDetailJson(status: 'cancelled', label: 'ملغى'));
    await open(tester);
    expect(find.text('الاشتراك ملغى'), findsOneWidget);
    expect(find.text('انتقل لمدينة أخرى'), findsOneWidget);
    expect(find.textContaining('سداد الدين'), findsNothing);
    expect(find.text('تجديد'), findsNothing);
    expect(find.text('إلغاء الاشتراك'), findsNothing);
    await tapText(tester, 'الفاتورة');
    expect(h.membership.files, ['invoice 3']);
  });

  testWidgets('attendance tab asks the member visits within the period', (tester) async {
    await open(tester);
    await tester.tap(find.descendant(of: find.byType(AppTabs), matching: find.text('الحضور')));
    await tester.pumpAndSettle();
    expect(h.membership.attendanceCalls.single, (
      playerId: 3,
      from: DateTime(2026, 10, 25),
      to: DateTime(2026, 11, 23),
    ));
    expect(find.text('لا زيارات خلال الاشتراك'), findsOneWidget);
  });

  testWidgets('member link opens the profile; back link returns to the list', (tester) async {
    await open(tester);
    await tapText(tester, 'أحمد الخطيب');
    expect(h.location, Routes.child(Routes.members, 3));
  });

  testWidgets('error retries; a bad id needs no request', (tester) async {
    h.membership.detailResult = const ApiFailure(offline);
    await open(tester);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
    serve(ahmadDetailJson());
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();
    expect(find.text('تدريب خاص شهري'), findsOneWidget);
  });

  testWidgets('non-numeric id shows not found', (tester) async {
    await open(tester, path: '${Routes.memberships}/abc');
    expect(find.text('الاشتراك غير موجود'), findsOneWidget);
    expect(h.membership.detailCalls, isEmpty);
  });

  for (final w in [360.0, 800.0, 1024.0, 1440.0]) {
    testWidgets('no overflow at ${w.toInt()}px', (tester) async {
      await open(tester, width: w);
      expect(tester.takeException(), isNull);
    });
  }
}
