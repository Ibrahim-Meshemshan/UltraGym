import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_gym_admin/core/error/failure.dart';
import 'package:ultra_gym_admin/core/networking/api_result.dart';
import 'package:ultra_gym_admin/core/router/routes.dart';
import 'package:ultra_gym_admin/core/widgets/table/app_data_table.dart';
import 'package:ultra_gym_admin/core/widgets/table/filter_bar.dart';
import 'package:ultra_gym_admin/features/members/domain/models/member_models.dart';
import 'package:ultra_gym_admin/features/members/presentation/widgets/member_cells.dart';

import '../../core/layout/shell_harness.dart';
import 'fake_members_repository.dart';

const offline = Failure(type: FailureType.network, message: 'تعذّر الاتصال.');

void main() {
  final h = ShellHarness();
  setUp(h.setUp);
  tearDown(h.tearDown);

  Future<void> open(WidgetTester tester, {double width = 1280, bool reception = false, String at = Routes.members}) =>
      h.pump(tester, width, session: reception ? receptionist : owner, at: at);

  Finder inTable(Finder f) => find.descendant(of: find.byType(AppDataTable<MemberRow>), matching: f);

  testWidgets('owner sees tabs with counts, rows, debt, suspension and the range', (tester) async {
    await open(tester);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(inTable(find.text('أحمد الخطيب')), findsOneWidget);
    expect(inTable(find.text('DMO-098969')), findsOneWidget);
    expect(inTable(find.text(r'$20.00')), findsOneWidget);
    expect(inTable(find.text('حساب موقوف')), findsOneWidget);
    expect(inTable(find.text('بلا اشتراك')), findsOneWidget);
    expect(inTable(find.text('حتى 23 تشرين الثاني · باقي 15 يوماً')), findsOneWidget);
    expect(find.textContaining('عضوًا'), findsOneWidget);
    // كل الفروع ← فلتر الفرع داخل الجدول، وبلا branch_id بالطلب
    expect(find.text('الفرع: الكل'), findsOneWidget);
    expect(h.members.listCalls.single.branchId, isNull);
    expect(h.members.countCalls, [null]);
  });

  testWidgets('chips, toggle and debounced search reach the server; clear resets', (tester) async {
    await open(tester);
    await tester.tap(find.text('منتهٍ'));
    await tester.pumpAndSettle();
    expect(h.members.listCalls.last.params['membership_status'], 'expired');

    await tester.tap(find.text('عليه دين'));
    await tester.pumpAndSettle();
    expect(h.members.listCalls.last.params['has_debt'], 1);

    final calls = h.members.listCalls.length;
    await tester.enterText(find.descendant(of: find.byType(SearchField), matching: find.byType(TextField)), 'أحمد');
    await tester.pump(const Duration(milliseconds: 200));
    expect(h.members.listCalls, hasLength(calls));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(h.members.listCalls.last.params['search'], 'أحمد');

    await tester.tap(find.text('مسح الفلاتر'));
    await tester.pumpAndSettle();
    expect(h.members.listCalls.last.params.keys, ['page', 'per_page']);
    expect(find.text('أحمد'), findsNothing);
  });

  testWidgets('empty with filters suggests clearing; empty without is an invitation', (tester) async {
    h.members.listResult = ApiSuccess(page(const [], total: 0));
    await open(tester, at: '${Routes.members}?membership_status=frozen');
    expect(h.members.listCalls.single.params['membership_status'], 'frozen');
    expect(find.text('لا نتائج مطابقة'), findsOneWidget);
    // زر الحالة الفارغة (الثاني بعد زر شريط الفلاتر)
    await tester.tap(find.text('مسح الفلاتر').last);
    await tester.pumpAndSettle();
    expect(find.text('أضف أول عضو'), findsOneWidget);
  });

  testWidgets('first load failure shows retry, then the table', (tester) async {
    h.members.listResult = const ApiFailure(offline);
    await open(tester);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
    h.members.listResult = ApiSuccess(firstPage);
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();
    expect(inTable(find.text('أحمد الخطيب')), findsOneWidget);
  });

  testWidgets('archive tab asks for archived members; empty archive explains itself', (tester) async {
    await open(tester);
    await tester.tap(find.text('الأرشيف'));
    await tester.pumpAndSettle();
    expect(h.members.listCalls.last.tab, MembersTab.archive);
    expect(find.text('الأرشيف فارغ'), findsOneWidget);
    // لا رقائق حالة الاشتراك بالأرشيف
    expect(find.text('بلا اشتراك'), findsNothing);
  });

  testWidgets('row opens the profile; owner archives from the menu', (tester) async {
    await open(tester);
    await tester.tap(find.byTooltip('إجراءات العضو').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('أرشفة'));
    await tester.pumpAndSettle();
    expect(find.text('أرشفة أحمد الخطيب؟'), findsOneWidget);
    await tester.tap(find.text('أرشفة').last);
    await tester.pumpAndSettle();
    expect(h.members.archived, [3]);
    expect(h.members.countCalls, hasLength(2));

    await tester.tap(inTable(find.text('أحمد الخطيب')));
    await tester.pumpAndSettle();
    expect(h.location, Routes.child(Routes.members, 3));
  });

  testWidgets('receptionist: no archive action', (tester) async {
    await open(tester, reception: true);
    await tester.tap(find.byTooltip('إجراءات العضو').first);
    await tester.pumpAndSettle();
    expect(find.text('فتح الملف'), findsOneWidget);
    expect(find.text('أرشفة'), findsNothing);
  });

  testWidgets('add member sends one key per body and shows the password once', (tester) async {
    await open(tester);
    await tester.tap(find.text('إضافة عضو'));
    await tester.pumpAndSettle();
    final dialog = find.byType(Dialog);
    final fields = find.descendant(of: dialog, matching: find.byType(TextField));
    await tester.enterText(fields.at(0), 'سامي حداد');
    await tester.enterText(fields.at(1), '0944200200');
    await tester.tap(find.descendant(of: dialog, matching: find.text('إضافة')));
    await tester.pumpAndSettle();

    final sent = h.members.created.single;
    expect(sent.body, containsPair('name', 'سامي حداد'));
    expect(sent.body, containsPair('phone', '0944200200'));
    expect(sent.key, isNotEmpty);
    expect(find.text('تمت إضافة سامي حداد'), findsOneWidget);
    expect(find.text('482913'), findsOneWidget);
    expect(find.text('إرسال بواتساب'), findsOneWidget);
    // تاريخ الانتهاء بسطر مستقل LTR (لا داخل الجملة فينكسر بين سطرين)
    expect(find.text('كلمة السر صالحة حتى '), findsOneWidget);
    expect(find.text('2026-11-16'), findsOneWidget);
    await tester.tap(find.text('تم'));
    await tester.pumpAndSettle();
    expect(find.text('482913'), findsNothing);
  });

  testWidgets('pages: numbers jump to the page', (tester) async {
    h.members.listResult = ApiSuccess(page([ahmad, omar, hiba], total: 40, last: 3));
    await open(tester);
    await tester.ensureVisible(find.byTooltip('الصفحة 2'));
    await tester.tap(find.byTooltip('الصفحة 2'));
    await tester.pumpAndSettle();
    expect(h.members.listCalls.last.params['page'], 2);
  });

  testWidgets('mobile shows cards instead of the table', (tester) async {
    await open(tester, width: 360);
    expect(find.byType(AppDataTable<MemberRow>), findsNothing);
    expect(find.byType(MemberMobileCard), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  for (final w in [360.0, 800.0, 1024.0]) {
    testWidgets('no overflow at ${w.toInt()}px', (tester) async {
      await open(tester, width: w);
      expect(tester.takeException(), isNull);
    });
  }
}
