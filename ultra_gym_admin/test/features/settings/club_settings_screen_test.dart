import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_gym_admin/core/error/failure.dart';
import 'package:ultra_gym_admin/core/layout/nav_config.dart';
import 'package:ultra_gym_admin/core/networking/api_result.dart';
import 'package:ultra_gym_admin/core/router/routes.dart';
import 'package:ultra_gym_admin/core/utils/formatters.dart';
import 'package:ultra_gym_admin/core/widgets/form/form_fields.dart';
import 'package:ultra_gym_admin/features/settings/domain/models/settings_models.dart';

import '../../core/layout/shell_harness.dart';
import '../../helpers/app_fonts.dart';
import 'fake_settings_repository.dart';

void main() {
  final h = ShellHarness();
  setUpAll(() async {
    await loadAppFonts();
    Formatters.init('Asia/Damascus');
  });
  setUp(h.setUp);
  tearDown(h.tearDown);

  Future<void> open(WidgetTester tester, {double width = 1280, String at = Routes.settings}) =>
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

  Finder toggle(String label) => find.widgetWithText(SwitchListTile, label);

  testWidgets('club tab: identity, operation, memberships, extras and notifications by audience', (tester) async {
    await open(tester);
    expect(find.text('النادي'), findsWidgets);
    expect(find.text('الفروع'), findsWidgets);
    expect(find.text('نادي الأبطال'), findsOneWidget);
    expect(find.text('تحدده المنصة.'), findsOneWidget);
    expect(find.text('رفع شعار'), findsOneWidget);
    expect(find.text('إزالة'), findsNothing);
    expect(find.text('Asia/Damascus'), findsOneWidget);
    expect(find.text('2 فجراً'), findsOneWidget);
    expect(find.text('شكراً لثقتكم'), findsOneWidget);
    expect(find.text('المالك والاستقبال'), findsOneWidget);
    expect(find.text('تذكير بانتهاء الاشتراك'), findsOneWidget);
    expect(find.textContaining('فواتير المنصة'), findsOneWidget);
    expect(h.settings.branchCalls, 0, reason: 'branches load when their tab opens');
  });

  testWidgets('saving without changes sends nothing', (tester) async {
    await open(tester);
    await tap(tester, find.text('حفظ الإعدادات'));
    expect(h.settings.clubBodies, isEmpty);
    expect(h.settings.settingsBodies, isEmpty);
  });

  testWidgets('edits send only the settings request, with a notification turned off, then reload', (tester) async {
    await open(tester);
    await type(tester, 'membership_grace_days', '5');
    await tap(tester, toggle('اشتراكات تنتهي قريباً'));
    await tap(tester, toggle('يضيف العضو برامجه من التطبيق'));
    await tap(tester, find.text('حفظ الإعدادات'));
    expect(h.settings.clubBodies, isEmpty);
    final body = h.settings.settingsBodies.single;
    expect(body['membership_grace_days'], 5);
    expect(body['disabled_notifications'], ['membership_expiring']);
    expect(body['player_workouts_enabled'], isTrue);
    expect(h.settings.clubCalls, 2);
  });

  testWidgets('contact changes go to PATCH club; a cleared field is null', (tester) async {
    await open(tester);
    await type(tester, 'address', '');
    await type(tester, 'contact_email', 'club@demo.test');
    await tap(tester, find.text('حفظ الإعدادات'));
    expect(h.settings.clubBodies.single, {
      'contact_phone': '+963112223344',
      'contact_email': 'club@demo.test',
      'city': 'دمشق',
      'address': null,
    });
    expect(h.settings.settingsBodies, isEmpty);
  });

  testWidgets('local limits stop the request', (tester) async {
    await open(tester);
    await type(tester, 'membership_grace_days', '40');
    await type(tester, 'contact_email', 'not-an-email');
    await tap(tester, find.text('حفظ الإعدادات'));
    expect(find.text('من 0 حتى 30.'), findsOneWidget);
    expect(find.text('اكتب بريداً صحيحاً.'), findsOneWidget);
    expect(h.settings.settingsBodies, isEmpty);
    expect(h.settings.clubBodies, isEmpty);
  });

  testWidgets('a 422 shows under its field', (tester) async {
    h.settings.updateClubResult = const ApiFailure(
      Failure(
        type: FailureType.validation,
        message: 'البيانات المدخلة غير صالحة',
        errors: {
          'contact_phone': ['صيغة الهاتف غير صالحة.'],
        },
      ),
    );
    await open(tester);
    await type(tester, 'contact_phone', '123');
    await tap(tester, find.text('حفظ الإعدادات'));
    expect(find.text('صيغة الهاتف غير صالحة.'), findsOneWidget);
  });

  testWidgets('cancel restores the saved values', (tester) async {
    await open(tester);
    await type(tester, 'receipt_footer', 'نص جديد');
    await tap(tester, find.text('إلغاء التغييرات'));
    expect(find.text('نص جديد'), findsNothing);
    expect(find.text('شكراً لثقتكم'), findsOneWidget);
  });

  testWidgets('a club with a logo can remove it after a confirmation', (tester) async {
    h.settings.clubResult = ApiSuccess(ClubProfile.fromJson(clubJson(logo: 'https://cdn.test/logo.png')));
    await open(tester);
    expect(find.text('تغيير الشعار'), findsOneWidget);
    await tap(tester, find.text('إزالة'));
    await tap(tester, find.descendant(of: find.byType(Dialog), matching: find.text('إزالة')));
    expect(h.settings.logoDeletes, 1);
    expect(h.settings.clubCalls, 2);
  });

  testWidgets('load failure offers a retry', (tester) async {
    h.settings.clubResult = const ApiFailure(Failure(type: FailureType.server, message: 'تعذّر الاتصال بالخادم.'));
    await open(tester);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
    h.settings.clubResult = ApiSuccess(ClubProfile.fromJson(clubJson()));
    await tap(tester, find.text('إعادة المحاولة'));
    expect(find.text('نادي الأبطال'), findsOneWidget);
  });

  testWidgets('?tab=branches opens the branches tab', (tester) async {
    await open(tester, at: Routes.settingsBranches);
    expect(find.text('بيانات الفرع'), findsOneWidget);
    expect(find.text('2 من 10'), findsOneWidget);
  });

  test('receptionist: the section is owner-only', () {
    final e = AdminNav.entryFor(Routes.settings)!;
    expect(e.allowed(owner), isTrue);
    expect(e.allowed(receptionist), isFalse);
  });

  for (final w in [360.0, 800.0, 1440.0]) {
    testWidgets('no overflow at ${w.toInt()}px: both tabs', (tester) async {
      await open(tester, width: w);
      expect(tester.takeException(), isNull);
      await tap(tester, find.text('الفروع').first);
      await tap(tester, find.text('فرع المالكي'));
      expect(find.text('(حتى اليوم التالي) تنتهي ${Formatters.ltr('01:00')} صباح اليوم التالي.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
