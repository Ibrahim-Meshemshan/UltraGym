import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_gym_admin/core/error/failure.dart';
import 'package:ultra_gym_admin/core/networking/api_result.dart';
import 'package:ultra_gym_admin/core/router/routes.dart';
import 'package:ultra_gym_admin/core/widgets/form/form_fields.dart';

import '../../core/layout/shell_harness.dart';
import 'fake_finance_settings_repository.dart';

void main() {
  final h = ShellHarness();
  setUp(h.setUp);
  tearDown(h.tearDown);

  Future<void> open(WidgetTester tester, {double width = 1280, bool asOwner = true}) =>
      h.pump(tester, width, at: Routes.financeCategories, session: asOwner ? owner : receptionist);

  Future<void> tap(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  Finder inDialog(Finder f) => find.descendant(of: find.byType(Dialog).last, matching: f);
  Finder nameField() => inDialog(
    find.descendant(
      of: find.byWidgetPredicate((w) => w is FormText && w.name == 'name'),
      matching: find.byType(TextField),
    ),
  );

  testWidgets('owner: two groups with usage, status, edit, and delete only for unused', (tester) async {
    await open(tester);
    expect(h.topTitle(tester), 'الصندوق والحركات');
    expect(find.text('تصنيفات المصاريف'), findsOneWidget);
    expect(find.text('تصنيفات الإيرادات الأخرى'), findsOneWidget);
    expect(find.text('حركتان'), findsOneWidget);
    expect(find.text('3 حركات'), findsOneWidget);
    expect(find.text('حركة واحدة'), findsOneWidget);
    expect(find.text('لا حركات'), findsOneWidget);
    expect(find.text('فعّال'), findsNWidgets(3));
    expect(find.text('متوقف'), findsOneWidget);
    expect(find.text('تعديل'), findsNWidgets(4));
    expect(find.text('تصنيف'), findsNWidgets(2));
    expect(find.byTooltip('حذف ضيافة'), findsOneWidget);
    expect(find.byTooltip('حذف إيجار'), findsNothing);
    expect(find.textContaining('أوقف التصنيف ليختفي'), findsOneWidget);
  });

  testWidgets('adding an income category posts its kind and name with a key, then refreshes', (tester) async {
    await open(tester);
    await tap(tester, find.text('تصنيف').last);
    expect(find.text('تصنيف إيراد جديد'), findsOneWidget);
    await tap(tester, inDialog(find.text('إضافة')));
    expect(h.finance.added, isEmpty, reason: 'the name is required');
    await tester.enterText(nameField(), '  اشتراك خزائن ');
    await tap(tester, inDialog(find.text('إضافة')));
    final sent = h.finance.added.single;
    expect(sent.body, {'kind': 'income', 'name': 'اشتراك خزائن'});
    expect(sent.key, isNotEmpty);
    expect(find.byType(Dialog), findsNothing);
    expect(h.finance.categoryCalls, 2);
  });

  testWidgets('a duplicate name shows the server message in the dialog', (tester) async {
    h.finance.addResult = const ApiFailure(
      Failure(
        type: FailureType.validation,
        code: 'VALIDATION_ERROR',
        message: 'البيانات المدخلة غير صالحة',
        errors: {
          'name': ['يوجد تصنيف بنفس الاسم'],
        },
      ),
    );
    await open(tester);
    await tap(tester, find.text('تصنيف').first);
    expect(find.text('تصنيف مصروف جديد'), findsOneWidget);
    await tester.enterText(nameField(), 'إيجار');
    await tap(tester, inDialog(find.text('إضافة')));
    expect(h.finance.added.single.body['kind'], 'expense');
    expect(find.text('يوجد تصنيف بنفس الاسم'), findsOneWidget);
    expect(find.byType(Dialog), findsOneWidget);
  });

  testWidgets('editing sends only what changed: the name, then the status', (tester) async {
    await open(tester);
    await tap(tester, find.text('تعديل').first);
    expect(tester.widget<TextField>(nameField()).controller!.text, 'إيجار');
    await tester.enterText(nameField(), 'إيجار الصالة');
    await tap(tester, inDialog(find.text('حفظ')));
    expect(h.finance.updates.single.id, 2);
    expect(h.finance.updates.single.body, {'name': 'إيجار الصالة'});

    await tap(tester, find.text('تعديل').at(1));
    await tap(tester, inDialog(find.text('متوقف')));
    await tap(tester, inDialog(find.text('حفظ')));
    expect(h.finance.updates.last.id, 3);
    expect(h.finance.updates.last.body, {'status': 'inactive'});
    expect(h.finance.categoryCalls, 3);
  });

  testWidgets('saving without changes sends nothing', (tester) async {
    await open(tester);
    await tap(tester, find.text('تعديل').first);
    await tap(tester, inDialog(find.text('حفظ')));
    expect(h.finance.updates, isEmpty);
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('deleting an unused category asks first; a used one is refused with the server message', (
    tester,
  ) async {
    await open(tester);
    await tap(tester, find.byTooltip('حذف ضيافة'));
    expect(find.textContaining('سيُحذف تصنيف "ضيافة" نهائياً'), findsOneWidget);
    await tap(tester, inDialog(find.text('إلغاء')));
    expect(h.finance.deleted, isEmpty);

    h.finance.deleteResult = usedCategoryConflict;
    await tap(tester, find.byTooltip('حذف ضيافة'));
    await tap(tester, inDialog(find.text('حذف')));
    expect(h.finance.deleted, [5]);
    expect(find.text('التصنيف مستخدم بحركات مالية: أوقفه بدل حذفه'), findsOneWidget);

    h.finance.deleteResult = null;
    await tap(tester, inDialog(find.text('حذف')));
    expect(find.byType(Dialog), findsNothing);
    expect(h.finance.categoryCalls, 2);
  });

  testWidgets('reception reads the lists without actions', (tester) async {
    await open(tester, asOwner: false);
    expect(find.text('إيجار'), findsOneWidget);
    expect(find.text('تصنيف'), findsNothing);
    expect(find.text('تعديل'), findsNothing);
    expect(find.byTooltip('حذف ضيافة'), findsNothing);
  });

  testWidgets('an empty group invites the first category; a failed load offers a retry', (tester) async {
    h.finance.categoriesResult = const ApiSuccess([]);
    await open(tester);
    expect(find.text('لا تصنيفات مصروف بعد. أضف أول تصنيف.'), findsOneWidget);
    expect(find.text('لا تصنيفات إيراد بعد. أضف أول تصنيف.'), findsOneWidget);
  });

  testWidgets('a failed load shows the error', (tester) async {
    h.finance.categoriesResult = const ApiFailure(Failure(type: FailureType.server, message: 'تعذّر الاتصال بالخادم'));
    await open(tester);
    expect(find.text('تعذّر الاتصال بالخادم'), findsWidgets);
  });

  for (final w in [360.0, 800.0, 1024.0, 1440.0]) {
    testWidgets('no overflow at ${w.toInt()}px, with the edit dialog open', (tester) async {
      await open(tester, width: w);
      expect(tester.takeException(), isNull);
      await tap(tester, find.text('تعديل').first);
      expect(tester.takeException(), isNull);
    });
  }
}
