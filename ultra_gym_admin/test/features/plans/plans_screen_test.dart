import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_gym_admin/core/networking/api_result.dart';
import 'package:ultra_gym_admin/core/router/routes.dart';
import 'package:ultra_gym_admin/core/widgets/form/form_fields.dart';
import 'package:ultra_gym_admin/features/plans/domain/models/plans_models.dart';

import '../../core/layout/shell_harness.dart';
import 'fake_plans_repository.dart';

void main() {
  final h = ShellHarness();
  setUp(h.setUp);
  tearDown(h.tearDown);

  Future<void> open(WidgetTester tester, {double width = 1280, bool asOwner = true}) =>
      h.pump(tester, width, at: Routes.plans, session: asOwner ? owner : receptionist);

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

  group('plans', () {
    testWidgets('owner: tabs and plan cards from server fields', (tester) async {
      await open(tester);
      expect(h.topTitle(tester), 'الخطط والكوبونات');
      expect(find.text('خطط الاشتراك'), findsOneWidget);
      expect(find.text('الأرشيف'), findsOneWidget);
      expect(find.text('الكوبونات'), findsOneWidget);
      expect(find.text('شهري - حديد'), findsOneWidget);
      expect(find.text(r'$27.50'), findsOneWidget);
      expect(find.text('12 حصة'), findsOneWidget);
      expect(find.text('الفرع الرئيسي - المزة'), findsOneWidget);
      expect(find.text('مرتان · 30 يوماً (افتراضي النادي)'), findsWidgets);
      expect(find.text('بلا تجميد'), findsOneWidget);
      expect(find.text('تدريب شخصي · يحتاج مدرباً'), findsOneWidget);
      expect(find.text('متوقفة'), findsOneWidget);
      expect(find.text('تعديل'), findsNWidgets(4));
      expect(find.text('خطة جديدة'), findsOneWidget);
    });

    testWidgets('reception reads plan cards without tabs or actions', (tester) async {
      await open(tester, asOwner: false);
      expect(find.text('شهري - حديد'), findsOneWidget);
      expect(find.text('الكوبونات'), findsNothing);
      expect(find.text('خطة جديدة'), findsNothing);
      expect(find.text('تعديل'), findsNothing);
      expect(find.byTooltip('أرشفة شهري - حديد'), findsNothing);
    });

    testWidgets('a new duration plan posts its full body with a key, then refreshes', (tester) async {
      await open(tester);
      await tap(tester, find.text('خطة جديدة'));
      await tap(tester, inDialog(find.text('حفظ الخطة')));
      expect(h.plans.savedPlans, isEmpty);
      expect(find.text('اكتب اسم الخطة.'), findsOneWidget);
      await tester.enterText(field('name'), 'أسبوعي');
      await tester.enterText(field('duration_days'), '7');
      await tester.enterText(field('price_usd'), '10');
      await tester.enterText(field('max_freezes'), '0');
      await tap(tester, inDialog(find.text('حفظ الخطة')));
      final sent = h.plans.savedPlans.single;
      expect(sent.id, isNull);
      expect(sent.key, isNotEmpty);
      expect(sent.body, {
        'name': 'أسبوعي',
        'description': null,
        'type': 'duration',
        'duration_days': 7,
        'price_usd': 10,
        'branch_scope': 'all',
        'max_freezes': 0,
        'max_freeze_days': null,
        'is_personal_training': false,
        'status': 'active',
      });
      expect(find.byType(Dialog), findsNothing);
      expect(h.plans.planQueries, hasLength(2));
    });

    testWidgets('a sessions plan for selected branches needs the sessions count and a branch', (tester) async {
      await open(tester);
      await tap(tester, find.text('خطة جديدة'));
      expect(field('sessions_count'), findsNothing);
      await tap(tester, inDialog(find.text('عدد حصص')));
      await tap(tester, inDialog(find.text('فروع محددة')));
      await tester.enterText(field('name'), '8 حصص');
      await tester.enterText(field('duration_days'), '30');
      await tester.enterText(field('price_usd'), '18');
      await tap(tester, inDialog(find.text('حفظ الخطة')));
      expect(h.plans.savedPlans, isEmpty);
      expect(find.text('اكتب عدد الحصص.'), findsOneWidget);
      expect(find.text('اختر عنصراً واحداً على الأقل.'), findsOneWidget);
      await tester.enterText(field('sessions_count'), '8');
      await tap(tester, inDialog(find.text('فرع المالكي')));
      await tap(tester, inDialog(find.text('تدريب شخصي')));
      await tap(tester, inDialog(find.text('حفظ الخطة')));
      final body = h.plans.savedPlans.single.body;
      expect(body['type'], 'sessions');
      expect(body['sessions_count'], 8);
      expect(body['branch_scope'], 'selected');
      expect(body['branch_ids'], [2]);
      expect(body['is_personal_training'], isTrue);
    });

    testWidgets('switching back to a duration plan drops the sessions check', (tester) async {
      await open(tester);
      await tap(tester, find.text('خطة جديدة'));
      await tap(tester, inDialog(find.text('عدد حصص')));
      await tap(tester, inDialog(find.text('حسب المدة')));
      await tester.enterText(field('name'), 'شهري مسائي');
      await tester.enterText(field('duration_days'), '30');
      await tester.enterText(field('price_usd'), '20');
      await tap(tester, inDialog(find.text('حفظ الخطة')));
      expect(h.plans.savedPlans.single.body.containsKey('sessions_count'), isFalse);
    });

    testWidgets('editing prefills the plan and patches it without a key; can stop selling', (tester) async {
      await open(tester);
      await tap(tester, find.text('تعديل').at(2));
      expect(find.text('تعديل خطة'), findsOneWidget);
      expect(tester.widget<TextField>(field('name')).controller!.text, 'تدريب خاص شهري');
      expect(tester.widget<TextField>(field('price_usd')).controller!.text, '100');
      expect(tester.widget<TextField>(field('max_freezes')).controller!.text, '1');
      await tap(tester, inDialog(find.text('فعّالة للبيع')));
      await tap(tester, inDialog(find.text('حفظ الخطة')));
      final sent = h.plans.savedPlans.single;
      expect(sent.id, 3);
      expect(sent.key, isNull);
      expect(sent.body['status'], 'inactive');
      expect(sent.body['max_freezes'], 1);
      expect(sent.body['max_freeze_days'], 7);
      expect(sent.body['is_personal_training'], isTrue);
    });

    testWidgets('club-default freeze limits stay empty when editing', (tester) async {
      await open(tester);
      await tap(tester, find.text('تعديل').first);
      expect(tester.widget<TextField>(field('max_freezes')).controller!.text, isEmpty);
      await tap(tester, inDialog(find.text('حفظ الخطة')));
      expect(h.plans.savedPlans.single.body['max_freezes'], isNull);
      expect(h.plans.savedPlans.single.body['price_usd'], 27.5);
    });

    testWidgets('archiving asks first; the archive tab restores', (tester) async {
      await open(tester);
      await tap(tester, find.byTooltip('أرشفة شهري - حديد'));
      expect(find.textContaining('الاشتراكات المباعة منها لا تتأثر'), findsOneWidget);
      await tap(tester, inDialog(find.text('أرشفة')));
      expect(h.plans.archived, [1]);

      await tap(tester, find.text('الأرشيف'));
      expect(find.text('عرض الصيف'), findsOneWidget);
      expect(find.text('مؤرشفة'), findsOneWidget);
      expect(find.text('خطة جديدة'), findsNothing);
      expect(find.text('تعديل'), findsNothing);
      await tap(tester, find.text('استرجاع'));
      await tap(tester, inDialog(find.text('استرجاع')));
      expect(h.plans.restored, [9]);
    });

    testWidgets('no plans invites the owner to add one', (tester) async {
      h.plans.plansResult = ApiSuccess(pageOf(<Plan>[]));
      await open(tester);
      expect(find.text('لا خطط اشتراك بعد'), findsOneWidget);
    });
  });

  group('coupons', () {
    Future<void> openCoupons(WidgetTester tester, {double width = 1280}) async {
      await open(tester, width: width);
      await tap(tester, find.text('الكوبونات'));
    }

    testWidgets('the table shows discount, validity, usage, plans, status; delete only when unused', (tester) async {
      await openCoupons(tester);
      expect(find.text('WINTER25'), findsOneWidget);
      expect(find.text('25%'), findsOneWidget);
      expect(find.text(r'$5.00'), findsOneWidget);
      expect(find.text('2026-12-01'), findsWidgets);
      expect(find.text('بلا تاريخ'), findsOneWidget);
      expect(find.text('0 / 100'), findsOneWidget);
      expect(find.text('64 / ∞'), findsOneWidget);
      expect(find.text('شهري - حديد، 12 جلسة'), findsOneWidget);
      expect(find.text('كل الخطط'), findsOneWidget);
      expect(find.text('تدريب خاص شهري'), findsOneWidget);
      expect(find.text('متوقف'), findsOneWidget);
      expect(find.byTooltip('حذف WINTER25'), findsOneWidget);
      expect(find.byTooltip('حذف FRIEND5'), findsNothing);
    });

    testWidgets('a new coupon posts an uppercase code with a key; percent over 100 is caught', (tester) async {
      await openCoupons(tester);
      await tap(tester, find.text('كوبون جديد'));
      await tester.enterText(field('code'), 'spring10');
      await tester.enterText(field('discount_value'), '150');
      await tap(tester, inDialog(find.text('حفظ الكوبون')));
      expect(find.text('النسبة لا تتجاوز 100.'), findsOneWidget);
      expect(h.plans.savedCoupons, isEmpty);
      await tester.enterText(field('discount_value'), '10');
      await tester.enterText(field('max_uses'), '50');
      await tap(tester, inDialog(find.text('شهري - حديد')));
      await tap(tester, inDialog(find.text('حفظ الكوبون')));
      final sent = h.plans.savedCoupons.single;
      expect(sent.key, isNotEmpty);
      expect(sent.body['code'], 'SPRING10');
      expect(sent.body['discount_type'], 'percent');
      expect(sent.body['discount_value'], 10);
      expect(sent.body['max_uses'], 50);
      expect(sent.body['plan_ids'], [1]);
      expect(h.plans.couponQueries, hasLength(2));
    });

    testWidgets('a bad code is caught locally; editing patches by id', (tester) async {
      await openCoupons(tester);
      await tap(tester, find.text('كوبون جديد'));
      await tester.enterText(field('code'), 'عرض');
      await tester.enterText(field('discount_value'), '5');
      await tap(tester, inDialog(find.text('حفظ الكوبون')));
      expect(find.text('من 3 إلى 30 حرفاً لاتينياً أو رقماً (و - _).'), findsOneWidget);
      await tap(tester, inDialog(find.text('إلغاء')));

      await tap(tester, find.text('تعديل').at(1));
      expect(tester.widget<TextField>(field('code')).controller!.text, 'FRIEND5');
      await tap(tester, inDialog(find.text('فعّال')));
      await tap(tester, inDialog(find.text('حفظ الكوبون')));
      final sent = h.plans.savedCoupons.single;
      expect(sent.id, 2);
      expect(sent.key, isNull);
      expect(sent.body['discount_type'], 'fixed');
      expect(sent.body['status'], 'inactive');
      expect(sent.body['plan_ids'], isEmpty);
    });

    testWidgets('deleting asks first; a used coupon is refused with the server message', (tester) async {
      h.plans.deleteCouponResult = couponUsedConflict;
      await openCoupons(tester);
      await tap(tester, find.byTooltip('حذف WINTER25'));
      await tap(tester, inDialog(find.text('حذف')));
      expect(h.plans.deletedCoupons, [1]);
      expect(find.text('الكوبون مستخدم باشتراكات: أوقفه بدل حذفه'), findsOneWidget);
    });

    testWidgets('the status filter goes to the server', (tester) async {
      await openCoupons(tester);
      await tap(tester, find.text('الحالة: الكل'));
      await tap(tester, find.widgetWithText(MenuItemButton, 'متوقف'));
      expect(h.plans.couponQueries.last.filter('status'), 'inactive');
    });
  });

  for (final w in [360.0, 800.0, 1024.0, 1440.0]) {
    testWidgets('no overflow at ${w.toInt()}px: plans with the plan dialog, then coupons', (tester) async {
      await open(tester, width: w);
      expect(tester.takeException(), isNull);
      await tap(tester, find.text('خطة جديدة'));
      await tap(tester, inDialog(find.text('عدد حصص')));
      await tap(tester, inDialog(find.text('فروع محددة')));
      expect(tester.takeException(), isNull);
      await tap(tester, inDialog(find.text('إلغاء')));
      await tap(tester, find.text('الكوبونات'));
      expect(tester.takeException(), isNull);
      await tap(tester, find.text('كوبون جديد'));
      expect(tester.takeException(), isNull);
    });
  }
}
