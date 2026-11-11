import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_gym_admin/core/error/failure.dart';
import 'package:ultra_gym_admin/core/networking/api_result.dart';
import 'package:ultra_gym_admin/core/router/routes.dart';
import 'package:ultra_gym_admin/features/members/domain/models/member_profile_models.dart';

import '../../core/layout/shell_harness.dart';
import 'fake_member_profile_repository.dart';

const offline = Failure(type: FailureType.network, message: 'تعذّر الاتصال.');

void main() {
  final h = ShellHarness();
  setUp(h.setUp);
  tearDown(h.tearDown);

  final at = Routes.child(Routes.members, 3);

  Future<void> open(WidgetTester tester, {double width = 1280, String? path}) => h.pump(tester, width, at: path ?? at);

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  Finder dialogField(int i) => find.descendant(of: find.byType(Dialog), matching: find.byType(TextField)).at(i);

  testWidgets('shows the header, current membership, data, activity, training and notes', (tester) async {
    await open(tester);
    expect(h.profile.profileCalls, [3]);
    expect(find.text('أحمد الخطيب'), findsOneWidget);
    expect(find.text('فعّال'), findsWidgets);
    expect(find.textContaining(r'$20.00'), findsWidgets);
    expect(find.text('DMO-098969'), findsOneWidget);
    expect(find.text('2026-09-27'), findsOneWidget);
    // الاشتراك الحالي
    expect(find.text('حتى 23 تشرين الثاني · باقي 15 يوماً'), findsWidgets);
    expect(find.text('2026-11-23'), findsNWidgets(2));
    // البيانات والنشاط والتدريب والملاحظات
    expect(find.text('1996-04-12'), findsOneWidget);
    expect(find.text('+963933001245'), findsOneWidget);
    expect(find.text('لم يدخل بعد'), findsOneWidget);
    expect(find.text('كابتن مازن'), findsOneWidget);
    expect(find.text('86 kg · 2026-11-06'), findsOneWidget);
    expect(find.text('يفضّل التمرين المسائي.'), findsOneWidget);
    // السجل يبدأ بالاشتراكات
    expect(h.profile.historyCalls, ['memberships:1']);
    expect(find.text('2026-10-25'), findsOneWidget);
  });

  testWidgets('history tabs load attendance and payments on demand', (tester) async {
    await open(tester);
    await tapText(tester, 'الحضور');
    expect(h.profile.historyCalls.last, 'attendance:1');
    expect(find.text('مرفوض'), findsOneWidget);
    expect(find.text('ليس وقت قسمك'), findsOneWidget);
    expect(find.text('يدوي'), findsOneWidget);

    await tapText(tester, 'الدفعات');
    expect(h.profile.historyCalls.last, 'payments:1');
    expect(find.text('130,000 ل.س'), findsOneWidget);
    expect(find.text('B1-2026-000004'), findsOneWidget);
  });

  testWidgets('suspend needs a reason, then refreshes the profile', (tester) async {
    await open(tester);
    await tapText(tester, 'إيقاف');
    await tapText(tester, 'إيقاف العضو');
    expect(h.profile.suspended, isEmpty);

    await tester.enterText(dialogField(0), 'تأخر بالدفع');
    await tapText(tester, 'إيقاف العضو');
    expect(h.profile.suspended, ['تأخر بالدفع']);
    expect(h.profile.profileCalls, hasLength(2));
  });

  testWidgets('a suspended member shows the reason and can be activated', (tester) async {
    h.profile.profileResult = ApiSuccess(
      MemberProfile.fromJson(profileJson(status: 'suspended', reason: 'تأخر بالدفع')),
    );
    await open(tester);
    expect(find.text('الحساب موقوف'), findsOneWidget);
    expect(find.text('تأخر بالدفع'), findsOneWidget);
    expect(find.text('حساب موقوف'), findsOneWidget);
    expect(find.text('إيقاف'), findsNothing);

    await tapText(tester, 'تفعيل');
    await tapText(tester, 'تفعيل');
    expect(h.profile.activated, 1);
  });

  testWidgets('new password is confirmed, then shown once with its expiry', (tester) async {
    await open(tester);
    await tapText(tester, 'كلمة سر جديدة');
    expect(h.profile.resets, 0);
    await tapText(tester, 'إنشاء كلمة سر');
    expect(h.profile.resets, 1);
    expect(find.text('735190'), findsOneWidget);
    expect(find.text('كلمة السر صالحة حتى '), findsOneWidget);
    expect(find.text('2026-11-16'), findsOneWidget);
    await tapText(tester, 'تم');
    expect(find.text('735190'), findsNothing);
  });

  testWidgets('edit is prefilled and sends cleared fields as null', (tester) async {
    await open(tester);
    await tapText(tester, 'تعديل');
    expect(find.descendant(of: find.byType(Dialog), matching: find.text('أحمد الخطيب')), findsOneWidget);
    // الجنس (قائمة بقيم نصية) يظهر بقيمته الحالية لا "اختر"
    expect(find.descendant(of: find.byType(Dialog), matching: find.text('ذكر')), findsOneWidget);
    await tester.enterText(dialogField(0), 'أحمد خالد الخطيب');
    await tapText(tester, 'حفظ');
    final body = h.profile.updates.single;
    expect(body['name'], 'أحمد خالد الخطيب');
    expect(body['phone'], '+963944100001');
    expect(body['gender'], 'male');
    expect(body['birth_date'], '1996-04-12');
    expect(body.containsKey('address'), isTrue);
    expect(body['address'], isNull);
    expect(h.profile.profileCalls, hasLength(2));
  });

  testWidgets('archived member: notice, no actions, no edit', (tester) async {
    h.profile.profileResult = ApiSuccess(MemberProfile.fromJson(profileJson(archivedAt: '2026-11-01T10:00:00Z')));
    await open(tester);
    expect(find.text('العضو بالأرشيف'), findsOneWidget);
    expect(find.text('مؤرشف'), findsOneWidget);
    expect(find.text('كلمة سر جديدة'), findsNothing);
    expect(find.text('تعديل'), findsNothing);
  });

  testWidgets('load failure shows retry; a bad id shows not found; back link returns', (tester) async {
    h.profile.profileResult = const ApiFailure(offline);
    await open(tester);
    expect(find.text('تعذّر الاتصال.'), findsWidgets);
    h.profile.profileResult = ApiSuccess(ahmadProfile);
    await tapText(tester, 'إعادة المحاولة');
    expect(find.text('أحمد الخطيب'), findsOneWidget);

    await tapText(tester, 'كل الأعضاء');
    expect(h.location, Routes.members);
  });

  testWidgets('a non-numeric id shows not found without a request', (tester) async {
    await open(tester, path: '${Routes.members}/abc');
    expect(find.text('العضو غير موجود'), findsOneWidget);
    expect(h.profile.profileCalls, isEmpty);
  });

  for (final width in [360.0, 800.0, 1024.0, 1440.0]) {
    testWidgets('no overflow at $width', (tester) async {
      await open(tester, width: width);
      expect(tester.takeException(), isNull);
      await tapText(tester, 'الدفعات');
      expect(h.profile.historyCalls.last, 'payments:1');
      expect(tester.takeException(), isNull);
    });
  }
}
