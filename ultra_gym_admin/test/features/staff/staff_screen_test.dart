import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_gym_admin/core/core.dart';
import 'package:ultra_gym_admin/core/layout/nav_config.dart';

import '../../core/layout/shell_harness.dart';
import '../../helpers/app_fonts.dart';

void main() {
  final h = ShellHarness();
  setUpAll(() async {
    await loadAppFonts();
    Formatters.init('Asia/Damascus');
  });
  setUp(h.setUp);
  tearDown(h.tearDown);

  Future<void> open(WidgetTester tester, {double width = 1280, String at = Routes.staff}) =>
      h.pump(tester, width, at: at);

  Future<void> tap(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  Finder field(String name) => find.descendant(
    of: find.byWidgetPredicate((w) => w is FormText && w.name == name),
    matching: find.byType(TextField),
  );

  Future<void> type(WidgetTester tester, String name, String text) async {
    await tester.ensureVisible(field(name));
    await tester.enterText(field(name), text);
    await tester.pumpAndSettle();
  }

  Future<void> menu(WidgetTester tester, String name, String item) async {
    await tap(tester, find.byTooltip('إجراءات $name').first);
    await tap(tester, find.text(item).last);
  }

  Finder dialog(String text) => find.descendant(of: find.byType(Dialog), matching: find.text(text));

  testWidgets('reception tab: limit, rows and badges; other tabs load only when opened', (tester) async {
    await open(tester);
    expect(find.text('حد الموظفين بالخطة'), findsOneWidget);
    expect(find.text('3 / 5'), findsOneWidget);
    expect(find.text('رنا الخطيب'), findsOneWidget);
    expect(find.text('DMO-100002'), findsWidgets);
    expect(find.text('الفرع الرئيسي'), findsWidgets);
    expect(find.text('لم يدخل بعد'), findsOneWidget, reason: 'suspended row has no login yet');
    expect(find.text('موقوف'), findsWidgets);
    expect(h.staff.queries['staff'], isEmpty);
    expect(h.staff.queries['accounts'], isEmpty);
  });

  testWidgets('new receptionist: branches required, keyed body, then the one-time password', (tester) async {
    await open(tester);
    await tap(tester, find.text('حساب استقبال'));
    await type(tester, 'name', 'سلمى');
    await type(tester, 'phone', '0944000111');
    await tap(tester, find.text('إنشاء الحساب'));
    expect(find.text('اختر عنصراً واحداً على الأقل.'), findsOneWidget);
    expect(h.staff.added, isEmpty);

    await tap(tester, find.widgetWithText(FilterChip, 'فرع المالكي'));
    await tap(tester, find.text('إنشاء الحساب'));
    final sent = h.staff.added.single;
    expect(sent.body, {'name': 'سلمى', 'phone': '0944000111', 'email': null, 'branch_ids': [2]});
    expect(sent.key, isNotNull);
    expect(find.text('تم إنشاء حساب سلمى'), findsOneWidget);
    expect(find.text('Tmp-55aa'), findsOneWidget);
  });

  testWidgets('a taken phone (409) stays in the form', (tester) async {
    h.staff.addResult = const ApiFailure(
      Failure(type: FailureType.conflict, message: 'هذا الرقم مسجّل كموظف استقبال. استرجعه من الأرشيف.'),
    );
    await open(tester);
    await tap(tester, find.text('حساب استقبال'));
    await type(tester, 'name', 'سلمى');
    await type(tester, 'phone', '0944000111');
    await tap(tester, find.widgetWithText(FilterChip, 'الفرع الرئيسي - المزة'));
    await tap(tester, find.text('إنشاء الحساب'));
    expect(find.text('هذا الرقم مسجّل كموظف استقبال. استرجعه من الأرشيف.'), findsOneWidget);
  });

  testWidgets('row menu: suspend with a reason, then branches and edit', (tester) async {
    await open(tester);
    await menu(tester, 'رنا الخطيب', 'إيقاف');
    await tap(tester, find.text('إيقاف الحساب'));
    expect(h.staff.actions, isEmpty, reason: 'reason is required');
    await type(tester, 'reason', 'إجازة');
    await tap(tester, find.text('إيقاف الحساب'));
    expect(h.staff.actions, ['suspend 21: إجازة']);
    expect(h.staff.queries['reception']!.length, 2, reason: 'list refreshed');

    await menu(tester, 'رنا الخطيب', 'الفروع');
    await tap(tester, find.widgetWithText(FilterChip, 'فرع المالكي'));
    await tap(tester, dialog('حفظ'));
    expect(h.staff.actions.last, 'branches 21: [1, 2]');

    await menu(tester, 'باسل حداد', 'تفعيل');
    await tap(tester, dialog('تفعيل'));
    expect(h.staff.actions.last, 'activate 22');
  });

  testWidgets('new password: one account, results with skipped and print cards', (tester) async {
    await open(tester);
    await menu(tester, 'رنا الخطيب', 'كلمة سر جديدة');
    await tap(tester, find.text('إصدار كلمة جديدة'));
    expect(h.staff.resets.single, {
      'user_ids': [21],
    });
    expect(find.text('تمت إعادة تعيين كلمة السر لـ 1 حساب'), findsOneWidget);
    expect(find.text('Kx7-49QpL'), findsOneWidget);
    expect(find.text('سامر الحلبي: حساب المالك تديره المنصة'), findsOneWidget);
    await tap(tester, find.text('طباعة البطاقات PDF'));
    expect(h.staff.cards.single.single.password, 'Kx7-49QpL');
    await tap(tester, find.text('تم'));
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('print login cards: bulk reset for receptionists by state and validity', (tester) async {
    await open(tester);
    await tap(tester, find.text('طباعة بطاقات الدخول PDF'));
    expect(find.text('بطاقات دخول الاستقبال'), findsOneWidget);
    await type(tester, 'valid_days', '40');
    await tap(tester, find.text('إصدار الكلمات'));
    expect(find.text('من 1 إلى 30 يوماً.'), findsOneWidget);
    await type(tester, 'valid_days', '3');
    await tap(tester, find.text('كلمته المؤقتة منتهية'));
    await tap(tester, find.text('إصدار الكلمات'));
    expect(h.staff.resets.single, {'state': 'expired', 'role': 'receptionist', 'valid_days': 3});
    expect(find.text('Kx7-49QpL'), findsOneWidget);
  });

  testWidgets('archive toggle asks for archived=only and offers restore', (tester) async {
    await open(tester);
    await tap(tester, find.text('الأرشيف'));
    expect(h.staff.queries['reception']!.last.toParams()['archived'], 'only');
    await tap(tester, find.text('موقوف').first);
    expect(h.staff.queries['reception']!.last.toParams()['status'], isNull, reason: 'status chips hidden in archive');
  });

  testWidgets('trainers tab (?tab=staff): rows, types and commission', (tester) async {
    await open(tester, at: Routes.staffMembers);
    expect(find.text('كابتن سامر'), findsOneWidget);
    expect(find.text('مدرب حديد'), findsOneWidget);
    expect(find.text(r'$300.00'), findsWidgets);
    expect(find.text(Formatters.ltr('20%')), findsOneWidget);
    expect(find.text('2026-01-15'), findsWidgets);
    await tap(tester, find.text('عامل').first);
    expect(h.staff.queries['staff']!.last.toParams()['type'], 'worker');
  });

  testWidgets('new trainer with a fixed commission; a worker has no commission field', (tester) async {
    await open(tester, at: Routes.staffMembers);
    await tap(tester, find.text('موظف'));
    expect(dialog('الحالة'), findsNothing, reason: 'status only when editing');
    await type(tester, 'name', 'كابتن رامي');
    await type(tester, 'salary_amount', '250');
    await tap(tester, find.text(r'مبلغ ثابت $'));
    await type(tester, 'commission_fixed_usd', '4');
    await tap(tester, find.text('إضافة'));
    final saved = h.staff.savedStaff.single;
    expect(saved.key, isNotNull);
    expect(saved.id, isNull);
    expect(saved.body['name'], 'كابتن رامي');
    expect(saved.body['salary_amount'], 250);
    expect((saved.body['commission_type'], saved.body['commission_fixed_usd']), ('fixed', 4));

    await tap(tester, find.text('موظف'));
    await tap(tester, find.descendant(of: find.byType(Dialog), matching: find.text('عامل')));
    expect(find.text('العمولة على العملاء'), findsNothing);
  });

  testWidgets('editing a member patches with its id; archive 409 stays in the dialog', (tester) async {
    await open(tester, at: Routes.staffMembers);
    await tap(tester, find.text('كابتن سامر'));
    expect(find.text('تعديل كابتن سامر'), findsOneWidget);
    await tap(tester, find.text('متوقف').last);
    await tap(tester, dialog('حفظ'));
    expect(h.staff.savedStaff.single.id, 5);
    expect(h.staff.savedStaff.single.key, isNull);
    expect(h.staff.savedStaff.single.body['status'], 'inactive');

    h.staff.actionResult = const ApiFailure(
      Failure(type: FailureType.conflict, message: r'على الموظف سلف غير مسددة ($40.00). سوّها قبل الأرشفة.'),
    );
    await menu(tester, 'كابتن سامر', 'أرشفة');
    await tap(tester, dialog('أرشفة'));
    expect(find.text(r'على الموظف سلف غير مسددة ($40.00). سوّها قبل الأرشفة.'), findsOneWidget);
  });

  testWidgets('a commission 422 lands under the commission field', (tester) async {
    h.staff.saveStaffResult = const ApiFailure(
      Failure(
        type: FailureType.validation,
        message: 'البيانات المدخلة غير صالحة',
        errors: {
          'commission_percent': ['نسبة العمولة يجب ألا يتجاوز 100.'],
        },
      ),
    );
    await open(tester, at: Routes.staffMembers);
    await tap(tester, find.text('كابتن سامر'));
    expect(tester.widget<TextField>(field('commission_percent')).controller!.text, '20');
    await tap(tester, dialog('حفظ'));
    expect(
      find.descendant(
        of: find.byWidgetPredicate((w) => w is FormText && w.name == 'commission_percent'),
        matching: find.text('نسبة العمولة يجب ألا يتجاوز 100.'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('accounts tab: state counts, filters, blocked self and bulk reset', (tester) async {
    await open(tester, at: Routes.staffAccounts);
    expect(find.text('الكل (3)'), findsOneWidget);
    expect(find.text('لم يدخل بعد (1)'), findsOneWidget);
    expect(find.text('حسابك'), findsOneWidget);
    await tap(tester, find.text('لم يدخل بعد (1)'));
    expect(h.staff.queries['accounts']!.last.toParams()['state'], 'never_logged_in');

    await tap(tester, find.byTooltip('إجراءات سامر الحلبي'));
    expect(find.text('هذا حسابك'), findsOneWidget);
    expect(find.text('كلمة سر جديدة'), findsNothing);
    await tester.tapAt(Offset.zero);
    await tester.pumpAndSettle();

    await tap(tester, find.byTooltip('إجراءات عضو مشترك'));
    expect(find.text('مرتبط بنادٍ آخر: كلمة السر من حسابه'), findsOneWidget);
    final reset = tester.widget<MenuItemButton>(find.widgetWithText(MenuItemButton, 'كلمة سر جديدة'));
    expect(reset.onPressed, isNull);
    await tap(tester, find.text('إنهاء الجلسات'));
    await tap(tester, dialog('إنهاء الجلسات'));
    expect(h.staff.actions.single, 'sessions 40');

    await tap(tester, find.text('كلمات سر جديدة لمجموعة'));
    await tap(tester, find.text('إصدار الكلمات'));
    expect(h.staff.resets.single, {'state': 'never_logged_in', 'valid_days': 7});
  });

  test('section: owner with can_manage_staff only', () {
    final e = AdminNav.entryFor(Routes.staff)!;
    expect(e.allowed(owner), isTrue);
    expect(e.allowed(receptionist), isFalse);
  });

  testWidgets('limit failure hides the card; list error offers retry', (tester) async {
    h.staff
      ..usageResult = const ApiFailure(Failure(type: FailureType.server, message: 'خطأ'))
      ..receptionistsResult = const ApiFailure(Failure(type: FailureType.server, message: 'تعذّر التحميل'));
    await open(tester);
    expect(find.text('حد الموظفين بالخطة'), findsNothing);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
  });

  for (final w in [360.0, 800.0, 1024.0, 1440.0]) {
    testWidgets('no overflow at ${w.toInt()}px: all tabs and the dialogs', (tester) async {
      await open(tester, width: w);
      expect(tester.takeException(), isNull);
      await tap(tester, find.text('حساب استقبال'));
      expect(tester.takeException(), isNull);
      await tap(tester, find.text('إلغاء'));
      await tap(tester, find.text('المدربون والعمال'));
      await tap(tester, find.text('موظف'));
      expect(tester.takeException(), isNull);
      await tap(tester, find.text('إلغاء'));
      await tap(tester, find.text('كل الحسابات'));
      expect(find.text('الكل (3)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
