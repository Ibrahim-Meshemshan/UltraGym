import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_gym_admin/core/error/failure.dart';
import 'package:ultra_gym_admin/core/networking/api_result.dart';
import 'package:ultra_gym_admin/core/router/routes.dart';
import 'package:ultra_gym_admin/core/utils/formatters.dart';
import 'package:ultra_gym_admin/core/widgets/form/draft_field.dart';
import 'package:ultra_gym_admin/features/branches/domain/models/branch_models.dart';
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

  Future<void> open(WidgetTester tester, {double width = 1280}) => h.pump(tester, width, at: Routes.settingsBranches);

  Future<void> tap(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find
      .descendant(
        of: find.byWidgetPredicate((w) => w is DraftField && w.label == label),
        matching: find.byType(TextField),
      )
      .first;

  Future<void> type(WidgetTester tester, String label, String text) async {
    await tester.ensureVisible(field(label));
    await tester.enterText(field(label), text);
    await tester.pumpAndSettle();
  }

  Finder inDialog(Finder f) => find.descendant(of: find.byType(Dialog).last, matching: f);

  testWidgets('list with the plan usage; the main branch opens first, read-only main and no stop', (tester) async {
    await open(tester);
    expect(find.text('2 من 10'), findsOneWidget);
    expect(find.text('فرع المالكي'), findsOneWidget);
    expect(find.text('رئيسي · مختلط · دمشق'), findsOneWidget);
    expect(find.text('الفرع الرئيسي'), findsOneWidget);
    expect(find.text('الدخول للجميع بكل الأوقات. هذا هو الافتراضي.'), findsOneWidget);
    expect(find.text('إيقاف'), findsNothing);
    expect(find.text('الفرع الرئيسي لا يُوقف ولا يُؤرشف.'), findsOneWidget);
  });

  testWidgets('a time-split branch shows its slots with the overnight note', (tester) async {
    await open(tester);
    await tap(tester, find.text('فرع المالكي'));
    expect(find.text('حذف الفترة'), findsNWidgets(2));
    expect(find.textContaining('(حتى اليوم التالي)'), findsOneWidget);
    expect(find.text('إيقاف'), findsOneWidget);
    expect(find.text('أرشفة'), findsNothing, reason: 'only a stopped branch is archived');
  });

  testWidgets('edit and save sends the whole branch, then reloads the list', (tester) async {
    await open(tester);
    await tap(tester, find.text('فرع المالكي'));
    await type(tester, 'اسم الفرع', 'فرع المالكي الجديد');
    await type(tester, r'سعر الدخول اليومي ($)', '4');
    await tap(tester, find.text('حفظ التغييرات'));
    final s = h.settings.savedBranches.single;
    expect(s.id, 2);
    expect(s.key, isNull);
    expect(s.body['name'], 'فرع المالكي الجديد');
    expect(s.body['day_pass_price_usd'], 4);
    expect(s.body['gender_policy'], 'time_split');
    expect((s.body['gender_schedule'] as List).first, {
      'days': ['saturday', 'monday', 'wednesday'],
      'from': '08:00',
      'to': '14:00',
      'gender': 'female',
    });
    expect(h.settings.branchCalls, 2);
  });

  testWidgets('switch the main branch to time split, edit a slot, add and remove one', (tester) async {
    await open(tester);
    await tap(tester, find.text('أوقات منفصلة'));
    expect(find.text('حذف الفترة'), findsOneWidget);
    await tap(tester, find.text('إضافة فترة'));
    expect(find.text('حذف الفترة'), findsNWidgets(2));
    await tap(tester, find.text('حذف الفترة').last);
    await type(tester, 'إلى', '7:30');
    await tap(tester, find.text('إناث').first);
    await tap(tester, find.text('الجمعة').first);
    await tap(tester, find.text('حفظ التغييرات'));
    final slots = h.settings.savedBranches.single.body['gender_schedule'] as List;
    expect(slots.single, {
      'days': ['saturday', 'sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
      'from': '08:00',
      'to': '07:30',
      'gender': 'female',
    });
  });

  testWidgets('slot errors show locally and stop the request', (tester) async {
    await open(tester);
    await tap(tester, find.text('فرع المالكي'));
    await type(tester, 'من', '25:00');
    await tap(tester, find.text('حفظ التغييرات'));
    expect(find.text('الوقت بصيغة 08:00.'), findsOneWidget);
    expect(h.settings.savedBranches, isEmpty);
  });

  testWidgets('add a branch: name required, then POST with a key and the club usage reloads', (tester) async {
    await open(tester);
    await tap(tester, find.text('فرع'));
    expect(find.text('فرع جديد'), findsWidgets);
    await tap(tester, find.text('إضافة الفرع'));
    expect(find.text('اكتب اسم الفرع.'), findsOneWidget);
    await type(tester, 'اسم الفرع', 'فرع الشعلان');
    await tap(tester, find.text('إضافة الفرع'));
    final s = h.settings.savedBranches.single;
    expect((s.id, s.body['gender_policy']), (null, 'mixed'));
    expect(s.key, isNotNull);
    expect(h.settings.clubCalls, 2);
  });

  testWidgets('a server rejection is shown and the editor stays', (tester) async {
    h.settings.saveBranchResult = const ApiFailure(
      Failure(
        type: FailureType.planLimitReached,
        message: 'وصلت للحد الأقصى للفروع بخطتك.',
        code: 'PLAN_LIMIT_REACHED',
      ),
    );
    await open(tester);
    await tap(tester, find.text('فرع'));
    await type(tester, 'اسم الفرع', 'فرع ثالث');
    await tap(tester, find.text('إضافة الفرع'));
    expect(find.text('وصلت للحد الأقصى للفروع بخطتك.'), findsOneWidget);
  });

  testWidgets('the plan limit disables adding', (tester) async {
    h.settings.clubResult = ApiSuccess(ClubProfile.fromJson(clubJson(used: 2, limit: 2)));
    await open(tester);
    expect(find.text('2 من 2'), findsOneWidget);
    await tap(tester, find.text('فرع'));
    expect(find.text('إضافة الفرع'), findsNothing);
  });

  testWidgets('stop a branch after a confirmation, then reload the list', (tester) async {
    await open(tester);
    await tap(tester, find.text('فرع المالكي'));
    await tap(tester, find.text('إيقاف'));
    expect(inDialog(find.textContaining('يلزم إغلاق ورديته أولاً')), findsOneWidget);
    await tap(tester, inDialog(find.text('إيقاف الفرع')));
    expect(h.settings.statuses, [(2, 'inactive')]);
    expect(h.settings.branchCalls, 2);
  });

  testWidgets('a stopped branch can be activated or archived', (tester) async {
    h.settings.branchesResult = ApiSuccess([
      settingsBranches().first,
      Branch.fromJson(branchJson(id: 2, name: 'فرع المالكي', main: false, status: 'inactive')),
    ]);
    await open(tester);
    await tap(tester, find.text('فرع المالكي'));
    expect(find.text('موقوف'), findsWidgets);
    await tap(tester, find.text('أرشفة'));
    await tap(tester, inDialog(find.text('أرشفة')));
    expect(h.settings.archived, [2]);
    await tap(tester, find.text('تفعيل'));
    await tap(tester, inDialog(find.text('تفعيل الفرع')));
    expect(h.settings.statuses, [(2, 'active')]);
  });

  testWidgets('a 409 on stopping stays in the dialog', (tester) async {
    h.settings.statusResult = const ApiFailure(
      Failure(type: FailureType.conflict, message: 'أغلق وردية الصندوق المفتوحة بالفرع أولاً.', code: 'CONFLICT'),
    );
    await open(tester);
    await tap(tester, find.text('فرع المالكي'));
    await tap(tester, find.text('إيقاف'));
    await tap(tester, inDialog(find.text('إيقاف الفرع')));
    expect(inDialog(find.text('أغلق وردية الصندوق المفتوحة بالفرع أولاً.')), findsOneWidget);
  });

  testWidgets('load failure offers a retry', (tester) async {
    h.settings.branchesResult = const ApiFailure(Failure(type: FailureType.server, message: 'تعذّر الاتصال بالخادم.'));
    await open(tester);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
  });
}
