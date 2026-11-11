import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_gym_admin/core/error/failure.dart';
import 'package:ultra_gym_admin/core/layout/nav_config.dart';
import 'package:ultra_gym_admin/core/networking/api_result.dart';
import 'package:ultra_gym_admin/core/router/routes.dart';
import 'package:ultra_gym_admin/core/utils/formatters.dart';
import 'package:ultra_gym_admin/core/widgets/form/form_fields.dart';
import 'package:ultra_gym_admin/core/widgets/form/form_pickers.dart';

import '../../core/layout/shell_harness.dart';
import '../../helpers/app_fonts.dart';
import 'fake_announcements_repository.dart';

void main() {
  final h = ShellHarness();
  setUpAll(() async {
    await loadAppFonts();
    Formatters.init('Asia/Damascus');
  });
  setUp(h.setUp);
  tearDown(h.tearDown);

  Future<void> open(WidgetTester tester, {double width = 1280}) => h.pump(tester, width, at: Routes.announcements);

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

  testWidgets('lists announcements with state, audience, branch, when and the push badge', (tester) async {
    await open(tester);
    expect(h.announcements.queries.single.filters, isEmpty);
    expect(find.text('جهاز سكوات جديد'), findsOneWidget);
    expect(find.text('صيانة المكيفات'), findsOneWidget);
    expect(find.text('منشور'), findsOneWidget);
    expect(find.text('مسودة'), findsOneWidget);
    expect(find.text('منتهٍ'), findsOneWidget);
    expect(find.text('الفعّالون'), findsWidgets);
    expect(find.text('فرع المالكي'), findsOneWidget);
    expect(find.text('لم يُنشر'), findsOneWidget);
    expect(find.textContaining('2026-11-16'), findsOneWidget);
    expect(find.text('أُرسل إشعاراً لـ 12 عضواً'), findsOneWidget);
    expect(find.text('إعلان جديد'), findsOneWidget);
  });

  testWidgets('state chips filter by the server state', (tester) async {
    await open(tester);
    await tap(tester, find.text('مسودات'));
    expect(h.announcements.queries.last.filters, {'state': 'draft'});
    await tap(tester, find.text('منتهية'));
    expect(h.announcements.queries.last.filters, {'state': 'expired'});
    await tap(tester, find.text('الكل'));
    expect(h.announcements.queries.last.filters, isEmpty);
  });

  testWidgets('empty: one invitation button, no header button', (tester) async {
    h.announcements.listResult = ApiSuccess(announcementsPage(const []));
    await open(tester);
    expect(find.text('لا إعلانات بعد'), findsOneWidget);
    expect(find.text('إعلان جديد'), findsOneWidget);
    await tap(tester, find.text('إعلان جديد'));
    expect(inDialog(find.text('معاينة في تطبيق العضو')), findsOneWidget);
  });

  testWidgets('new announcement: required fields, live preview, publish with a key, or save a draft', (tester) async {
    await open(tester);
    await tap(tester, find.text('إعلان جديد'));
    await tap(tester, inDialog(find.text('نشر')));
    expect(h.announcements.saved, isEmpty);

    await tester.enterText(field('title'), 'مواعيد العيد');
    await tester.enterText(field('body'), 'النادي مفتوح أيام العيد من 10 حتى 8.');
    await tester.pumpAndSettle();
    expect(inDialog(find.text('مواعيد العيد')), findsNWidgets(2), reason: 'the field and the preview');
    await tap(tester, inDialog(find.text('المنتهية اشتراكاتهم')));
    expect(inDialog(find.text('من ليس له اشتراك جارٍ، للتذكير بالتجديد.')), findsOneWidget);

    await tester.tap(inDialog(find.text('حفظ مسودة')));
    await tester.pump();
    expect(inDialog(find.text('نشر')), findsOneWidget, reason: 'the progress label is on the pressed button');
    await tester.pumpAndSettle();
    final draft = h.announcements.saved.single;
    expect(draft.id, isNull);
    expect(draft.key, isNotNull);
    expect(draft.body['publish'], isFalse);
    expect(draft.body['audience'], 'expired');
    expect(draft.body['branch_id'], isNull);
    expect(draft.body['send_push'], isTrue);
    expect(draft.body['expires_at'], isNull);
    expect(find.byType(Dialog), findsNothing);

    await tap(tester, find.text('إعلان جديد'));
    await tester.enterText(field('title'), 'عرض العودة');
    await tester.enterText(field('body'), 'خصم 20% لمن انتهى اشتراكه.');
    await tap(tester, inDialog(find.text('نشر')));
    expect(h.announcements.saved.last.body['publish'], isTrue);
  });

  testWidgets('edit a published one: no push switch once sent, expiry kept, and stop publishing', (tester) async {
    await open(tester);
    await tap(tester, find.text('تعديل').first);
    expect(inDialog(find.text('تعديل الإعلان')), findsOneWidget);
    expect(inDialog(find.text('حفظ التعديل')), findsOneWidget);
    expect(inDialog(find.byType(FormSwitch)), findsNothing);
    expect(inDialog(find.textContaining('لا يُعاد بعد التعديل')), findsOneWidget);
    expect(inDialog(find.text('الفرع الرئيسي - المزة')), findsOneWidget);

    await tester.enterText(field('title'), 'جهاز سكوات وبنش جديدين');
    await tap(tester, inDialog(find.text('حفظ التعديل')));
    final edit = h.announcements.saved.single;
    expect(edit.id, 1);
    expect(edit.key, isNull);
    expect(edit.body['title'], 'جهاز سكوات وبنش جديدين');
    expect(edit.body['branch_id'], 1);
    for (final k in ['publish', 'send_push', 'expires_at']) {
      expect(edit.body.containsKey(k), isFalse, reason: k);
    }

    await tap(tester, find.text('تعديل').first);
    await tap(tester, inDialog(find.byTooltip('مسح التاريخ')));
    expect(inDialog(find.text('بلا انتهاء')), findsOneWidget);
    await tap(tester, inDialog(find.text('إيقاف النشر')));
    expect(h.announcements.saved.last.body['publish'], isFalse);
    expect(h.announcements.saved.last.body['expires_at'], isNull);
    expect(h.announcements.saved.last.body.containsKey('expires_at'), isTrue);
  });

  testWidgets('edit a draft: publish sends the push choice', (tester) async {
    await open(tester);
    await tap(tester, find.text('تعديل').at(1));
    expect(inDialog(find.byType(FormSwitch)), findsOneWidget);
    await tap(tester, inDialog(find.text('نشر')));
    final s = h.announcements.saved.single;
    expect(s.id, 2);
    expect(s.body['publish'], isTrue);
    expect(s.body['send_push'], isFalse);
  });

  testWidgets('a 422 shows under its field', (tester) async {
    h.announcements.saveResult = const ApiFailure(
      Failure(
        type: FailureType.validation,
        message: 'البيانات المدخلة غير صالحة',
        errors: {
          'expires_at': ['يجب أن يكون تاريخ الانتهاء بعد الآن.'],
        },
      ),
    );
    await open(tester);
    await tap(tester, find.text('تعديل').last);
    await tap(tester, inDialog(find.text('حفظ التعديل')));
    expect(inDialog(find.text('يجب أن يكون تاريخ الانتهاء بعد الآن.')), findsOneWidget);
    expect(find.byType(Dialog), findsOneWidget);
  });

  testWidgets('delete asks first, then refreshes', (tester) async {
    await open(tester);
    await tap(tester, find.byTooltip('حذف صيانة المكيفات'));
    expect(inDialog(find.textContaining('لا يمكن التراجع')), findsOneWidget);
    await tap(tester, inDialog(find.text('حذف')));
    expect(h.announcements.deleted, [2]);
    expect(h.announcements.queries.length, 2);
  });

  test('receptionist: the section is owner-only, so the link goes home', () {
    final e = AdminNav.all.firstWhere((e) => e.route == Routes.announcements);
    expect(e.allowed(owner), isTrue);
    expect(e.allowed(receptionist), isFalse);
  });

  for (final w in [360.0, 800.0, 1440.0]) {
    testWidgets('no overflow at ${w.toInt()}px: list and the dialog with its preview', (tester) async {
      await open(tester, width: w);
      expect(tester.takeException(), isNull);
      await tap(tester, find.text('تعديل').first);
      expect(inDialog(find.text('معاينة في تطبيق العضو')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
