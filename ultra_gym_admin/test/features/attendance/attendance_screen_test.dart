import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_gym_admin/core/error/failure.dart';
import 'package:ultra_gym_admin/core/networking/api_result.dart';
import 'package:ultra_gym_admin/core/networking/paged.dart';
import 'package:ultra_gym_admin/core/router/routes.dart';
import 'package:ultra_gym_admin/features/attendance/domain/models/attendance_models.dart';
import 'package:ultra_gym_admin/features/attendance/presentation/widgets/attendance_today.dart';
import 'package:ultra_gym_admin/features/attendance/presentation/widgets/check_in_dialog.dart';
import 'package:ultra_gym_admin/features/attendance/presentation/widgets/qr_scan_dialog.dart';
import 'package:ultra_gym_admin/features/club_plan/domain/models/club_plan_models.dart';

import '../../core/layout/shell_harness.dart';
import '../club_plan/fake_club_plan_repository.dart';
import 'fake_attendance_repository.dart';

void main() {
  final h = ShellHarness();
  setUp(h.setUp);
  tearDown(h.tearDown);

  Future<void> open(WidgetTester tester, {double width = 1280, bool reception = false, String? at}) =>
      h.pump(tester, width, session: reception ? receptionist : owner, at: at ?? Routes.attendance);

  Future<void> tap(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  Finder inDialog(Finder f) => find.descendant(of: find.byType(Dialog), matching: f);

  Future<void> checkInByCode(WidgetTester tester, String code) async {
    await tap(tester, find.text('تسجيل دخول يدوي'));
    await tester.enterText(inDialog(find.byType(TextField)).first, code);
    await tap(tester, inDialog(find.text('تسجيل الدخول')));
  }

  testWidgets('today numbers for the main branch, the hours chart and the log', (tester) async {
    await open(tester);
    expect(h.attendance.todayCalls, [1], reason: 'all branches: today needs one, the main');
    expect(h.attendance.queries.single.branchId, isNull);
    expect(find.text('حضور اليوم · الفرع الرئيسي - المزة'), findsOneWidget);
    expect(find.text('دخول مقبول اليوم'), findsOneWidget);
    expect(find.text('جلسات مستهلكة'), findsOneWidget);
    expect(find.text('الذروة 18:00'), findsOneWidget);
    expect(find.text('أحمد الخطيب'), findsOneWidget);
    expect(find.text('اشتراك اللاعب منتهٍ'), findsOneWidget);
    expect(find.text('دون اتصال'), findsOneWidget);
    expect(find.text('مقبول بالسماح'), findsOneWidget);
    expect(find.textContaining('آخر 31 يوماً'), findsWidgets);
  });

  testWidgets('no entry today: the chart says so', (tester) async {
    h.attendance.todayResult = const ApiSuccess(AttendanceToday(branchName: 'الفرع الرئيسي - المزة'));
    await open(tester);
    expect(find.text('لا دخول مقبول اليوم بعد.'), findsOneWidget);
    expect(find.textContaining('الذروة'), findsNothing);
  });

  testWidgets('the rejected card and the chips filter the log', (tester) async {
    await open(tester);
    await tap(tester, find.text('مرفوض اليوم'));
    expect(h.attendance.queries.last.query.filter('status'), 'rejected');
    await tap(tester, find.text('المقبول'));
    expect(h.attendance.queries.last.query.filter('status'), 'accepted');
  });

  testWidgets('method menu, a link with a period, and clearing', (tester) async {
    await open(tester, at: '${Routes.attendance}?from=2026-11-01&to=2026-11-09');
    expect(h.attendance.queries.single.query.toParams(), containsPair('from', '2026-11-01'));
    expect(find.text('2026-11-01 → 2026-11-09'), findsOneWidget);
    await tap(tester, find.text('الطريقة: الكل'));
    await tap(tester, find.widgetWithText(MenuItemButton, 'QR'));
    expect(h.attendance.queries.last.query.filter('method'), 'qr');
    await tap(tester, find.text('مسح الفلاتر'));
    expect(h.attendance.queries.last.query.filters, isEmpty);
  });

  testWidgets('a fixed top-bar branch drives both the log and today', (tester) async {
    await open(tester);
    await tap(tester, find.text('كل الفروع'));
    await tap(tester, find.text('فرع المالكي').last);
    expect(h.attendance.queries.last.branchId, 2);
    expect(h.attendance.todayCalls.last, 2);
  });

  testWidgets('row opens the member profile', (tester) async {
    await open(tester);
    await tap(tester, find.text('رامي العمر'));
    expect(h.location, Routes.child(Routes.members, 7));
  });

  testWidgets('check-in by code: accepted card with the debt, then the screen refreshes', (tester) async {
    await open(tester);
    await checkInByCode(tester, 'dmo-873152');
    final call = h.attendance.checkIns.single;
    expect(call.body, {'member_code': 'DMO-873152', 'branch_id': 1});
    expect(call.key, isNotEmpty);
    expect(inDialog(find.text('تم تسجيل الدخول')), findsOneWidget);
    expect(inDialog(find.textContaining('عليه دين')), findsOneWidget);
    expect(inDialog(find.text('سداد الدين')), findsOneWidget);

    await tap(tester, inDialog(find.text('إغلاق')));
    expect(find.byType(Dialog), findsNothing);
    expect(h.attendance.todayCalls, hasLength(2));
    expect(h.attendance.queries, hasLength(2));
  });

  testWidgets('rejected: red card with the reason and "sell membership" opens the sale for that member', (
    tester,
  ) async {
    h.attendance.checkInResult = rejectedNoMembership;
    await open(tester);
    await checkInByCode(tester, 'DMO-873152');
    expect(inDialog(find.text('لا يوجد اشتراك للاعب')), findsOneWidget);
    await tap(tester, inDialog(find.text('بيع اشتراك')));
    expect(h.router.routerDelegate.currentConfiguration.uri.toString(), Routes.sellTo(15));
  });

  testWidgets('duplicate shows "already in" and another check-in starts clean with a new key', (tester) async {
    h.attendance.checkInResult = ApiSuccess(
      CheckInResult.fromJson(checkInJson(duplicate: true), message: 'اللاعب مسجّل دخوله مسبقاً منذ 5 دقائق'),
    );
    await open(tester);
    await checkInByCode(tester, 'DMO-873152');
    expect(inDialog(find.text('اللاعب مسجّل دخوله مسبقاً منذ 5 دقائق')), findsOneWidget);
    await tap(tester, inDialog(find.text('تسجيل آخر')));
    expect(inDialog(find.text('معرّف العضو أو الباركود')), findsOneWidget);
    await tester.enterText(inDialog(find.byType(TextField)).first, 'DMO-873152');
    await tap(tester, inDialog(find.text('تسجيل الدخول')));
    expect(h.attendance.checkIns[1].key, isNot(h.attendance.checkIns[0].key));
    await tap(tester, inDialog(find.text('إغلاق')));
    expect(h.attendance.todayCalls, hasLength(1), reason: 'a duplicate records nothing new');
  });

  testWidgets('no member: message without a request; not found from the server stays in the form', (tester) async {
    await open(tester);
    await tap(tester, find.text('تسجيل دخول يدوي'));
    await tap(tester, inDialog(find.text('تسجيل الدخول')));
    expect(inDialog(find.text('اكتب معرّف العضو أو اختره بالبحث.')), findsOneWidget);
    expect(h.attendance.checkIns, isEmpty);

    h.attendance.checkInResult = const ApiFailure(
      Failure(type: FailureType.notFound, statusCode: 404, message: 'اللاعب غير موجود بهذا النادي'),
    );
    await tester.enterText(inDialog(find.byType(TextField)).first, 'DMO-000000');
    await tap(tester, inDialog(find.text('تسجيل الدخول')));
    expect(inDialog(find.text('اللاعب غير موجود بهذا النادي')), findsOneWidget);
  });

  testWidgets('pick from search sends player_id, with the session switch', (tester) async {
    await open(tester);
    await tap(tester, find.text('تسجيل دخول يدوي'));
    await tap(tester, inDialog(find.text('البحث بالاسم أو الموبايل')));
    await tester.enterText(find.descendant(of: find.byType(Dialog).last, matching: find.byType(TextField)), 'أحمد');
    await tester.pumpAndSettle();
    await tap(tester, find.text('أحمد الخطيب').last);
    expect(find.byType(Dialog), findsOneWidget);
    expect(inDialog(find.text('تغيير العضو')), findsOneWidget);
    await tap(tester, inDialog(find.text('استهلاك جلسة مع الدخول')));
    await tap(tester, inDialog(find.text('تسجيل الدخول')));
    expect(h.attendance.checkIns.single.body, {'player_id': 3, 'branch_id': 1, 'consume_session': true});
  });

  testWidgets('a scanned app QR goes as qr_token untouched; its 422 shows the server message', (tester) async {
    const token = 'UG1.k_Ab12.1794400000.xY-z_09aBc';
    h.attendance.checkInResult = const ApiFailure(
      Failure(
        type: FailureType.validation,
        statusCode: 422,
        code: 'QR_EXPIRED',
        message: 'رمز QR منتهي الصلاحية، اطلب من اللاعب تحديثه',
      ),
    );
    await open(tester);
    await checkInByCode(tester, '  $token ');
    expect(h.attendance.checkIns.single.body, {'qr_token': token, 'branch_id': 1});
    expect(inDialog(find.text('رمز QR منتهي الصلاحية، اطلب من اللاعب تحديثه')), findsOneWidget);
  });

  testWidgets('the camera scan sends the read QR as qr_token, replacing a picked member', (tester) async {
    const token = 'UG1.k_Ab12.1794400000.xY-z_09aBc';
    h.qr.next = token;
    await open(tester);
    await tap(tester, find.text('تسجيل دخول يدوي'));
    await tap(tester, inDialog(find.text('البحث بالاسم أو الموبايل')));
    await tester.enterText(find.descendant(of: find.byType(Dialog).last, matching: find.byType(TextField)), 'أحمد');
    await tester.pumpAndSettle();
    await tap(tester, find.text('أحمد الخطيب').last);
    await tap(tester, inDialog(find.text('مسح QR بالكاميرا')));
    expect(h.qr.scans, 1);
    expect(h.attendance.checkIns.single.body, {'qr_token': token, 'branch_id': 1});
  });

  testWidgets('a cancelled camera scan sends nothing and keeps the form', (tester) async {
    await open(tester);
    await tap(tester, find.text('تسجيل دخول يدوي'));
    await tap(tester, inDialog(find.text('مسح QR بالكاميرا')));
    expect(h.qr.scans, 1);
    expect(h.attendance.checkIns, isEmpty);
    expect(inDialog(find.text('تسجيل الدخول')), findsOneWidget);
  });

  testWidgets('no camera button when the plan has no qr_attendance', (tester) async {
    h.plan.entitlementsResult = ApiSuccess(entitlementsWithout({PlanFeature.qrAttendance}));
    await open(tester);
    await tap(tester, find.text('تسجيل دخول يدوي'));
    expect(inDialog(find.text('مسح QR بالكاميرا')), findsNothing);
    expect(inDialog(find.text('البحث بالاسم أو الموبايل')), findsOneWidget);
  });

  test('the camera accepts only member codes', () {
    expect(QrScanDialog.isMemberScan('UG1.k.1.s'), isTrue);
    expect(QrScanDialog.isMemberScan('DMO-873152'), isTrue);
    expect(QrScanDialog.isMemberScan('https://example.com'), isFalse);
    expect(QrScanDialog.isMemberScan('6291041500213'), isFalse, reason: 'a product barcode');
  });

  test('only the app QR prefix is a token', () {
    expect(CheckInDialog.isQrToken('UG1.k.1.s'), isTrue);
    expect(CheckInDialog.isQrToken('ug1.k.1.s'), isFalse, reason: 'a lower-cased member code stays a code');
    expect(CheckInDialog.isQrToken('DMO-873152'), isFalse);
  });

  testWidgets('today failure keeps the log and retries', (tester) async {
    h.attendance.todayResult = const ApiFailure(Failure(type: FailureType.network, message: 'تعذّر الاتصال.'));
    await open(tester);
    expect(find.byType(HoursCard), findsNothing);
    expect(find.text('أحمد الخطيب'), findsOneWidget);
    h.attendance.todayResult = ApiSuccess(AttendanceToday.fromJson(todayJson));
    await tap(tester, find.text('إعادة المحاولة'));
    expect(find.byType(HoursCard), findsOneWidget);
  });

  testWidgets('empty log invites to check in', (tester) async {
    h.attendance.listResult = const ApiSuccess(Paged());
    await open(tester);
    expect(find.text('لا دخول بهذه الفترة'), findsOneWidget);
  });

  testWidgets('receptionist checks members in too', (tester) async {
    await open(tester, reception: true);
    await tap(tester, find.text('تسجيل دخول يدوي'));
    expect(inDialog(find.text('معرّف العضو أو الباركود')), findsOneWidget);
  });

  for (final w in [360.0, 800.0, 1024.0, 1440.0]) {
    testWidgets('no overflow at ${w.toInt()}px, with the check-in result open', (tester) async {
      await open(tester, width: w);
      expect(tester.takeException(), isNull);
      await checkInByCode(tester, 'DMO-873152');
      expect(tester.takeException(), isNull);
    });
  }
}
