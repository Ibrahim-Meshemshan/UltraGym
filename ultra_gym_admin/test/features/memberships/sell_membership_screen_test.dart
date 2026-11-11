import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_gym_admin/core/bloc/app_form_cubit.dart';
import 'package:ultra_gym_admin/core/error/failure.dart';
import 'package:ultra_gym_admin/core/networking/api_result.dart';
import 'package:ultra_gym_admin/core/router/routes.dart';
import 'package:ultra_gym_admin/features/memberships/presentation/widgets/sale_form_steps.dart';
import 'package:ultra_gym_admin/features/memberships/presentation/widgets/sale_summary.dart';

import '../../core/layout/shell_harness.dart';
import 'fake_membership_detail_repository.dart';

void main() {
  final h = ShellHarness();
  setUp(h.setUp);
  tearDown(h.tearDown);

  Future<void> open(
    WidgetTester tester, {
    String at = Routes.sellMembership,
    double width = 1280,
    bool reception = false,
  }) => h.pump(tester, width, session: reception ? receptionist : owner, at: at);

  String uri() => h.router.routerDelegate.currentConfiguration.uri.toString();

  Finder field(String hint) => find.byWidgetPredicate((w) => w is TextField && w.decoration?.hintText == hint);

  Future<void> tap(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  Future<void> type(WidgetTester tester, String hint, String text) async {
    await tester.ensureVisible(field(hint));
    await tester.enterText(field(hint), text);
    await tester.pump();
  }

  Future<void> choosePlan(WidgetTester tester, String name) => tap(tester, find.text(name).first);

  testWidgets('memberships list opens the sale; plans from the server', (tester) async {
    await open(tester, at: Routes.memberships);
    await tap(tester, find.text('بيع اشتراك'));
    expect(h.location, Routes.sellMembership);
    expect(h.sell.planCalls, [null]);
    for (final name in ['شهري - كل الفروع', '12 جلسة', 'تدريب خاص شهري', 'شهري - فرع المالكي']) {
      expect(find.text(name), findsOneWidget);
    }
    expect(find.textContaining('خلال 45 يوماً'), findsOneWidget);
    expect(find.text('يحتاج مدرباً'), findsOneWidget);
    expect(find.text('اختيار العضو'), findsOneWidget);
    expect(find.text('اختر العضو والخطة أولاً.'), findsOneWidget);
  });

  testWidgets('member profile opens the sale on that member', (tester) async {
    await open(tester, at: Routes.child(Routes.members, 3));
    await tap(tester, find.text('بيع اشتراك'));
    expect(uri(), Routes.sellTo(3));
    expect(h.sell.memberCalls, [3]);
  });

  testWidgets('picks the member from the search dialog', (tester) async {
    await open(tester);
    await tap(tester, find.text('اختيار العضو'));
    await tester.enterText(find.descendant(of: find.byType(Dialog), matching: find.byType(TextField)), 'أحمد');
    await tester.pumpAndSettle();
    await tap(tester, find.text('أحمد الخطيب'));
    expect(find.byType(Dialog), findsNothing);
    expect(h.location, Routes.sellMembership, reason: 'picking does not open the profile');
    expect(find.text('أحمد الخطيب'), findsOneWidget);
    expect(find.textContaining('عليه دين'), findsOneWidget);
    expect(find.text('تغيير العضو'), findsOneWidget);
  });

  testWidgets('full sale: quote, both currencies, debt estimate, receipts, open membership', (tester) async {
    await open(tester, at: Routes.sellTo(15));
    expect(find.text('عضو تجريبي'), findsOneWidget);
    await choosePlan(tester, 'شهري - كل الفروع');
    expect(h.sell.quotes.single, {'plan_id': 1});
    expect(find.text('2026-12-11'), findsWidgets);
    await type(tester, '0.00', '15');
    await type(tester, '0', '65,000');
    expect(find.text('المتبقي (دين)'), findsOneWidget);
    Finder inSummary(String t) => find.descendant(of: find.byType(SaleSummary), matching: find.text(t));
    expect(inSummary(r'$20.00'), findsOneWidget);
    expect(inSummary(r'$5.00'), findsOneWidget);

    await tap(tester, find.text('تأكيد البيع'));
    final sale = h.sell.sales.single;
    expect(sale.body, {
      'player_id': 15,
      'plan_id': 1,
      'branch_id': 1,
      'payments': [
        {'currency': 'USD', 'amount': 15},
        {'currency': 'SYP', 'amount': 65000},
      ],
    });
    expect(sale.key, isNotEmpty);
    expect(find.text('تم البيع'), findsOneWidget);
    expect(find.textContaining('دين على اللاعب'), findsOneWidget);
    expect(find.text('B1-2026-000031'), findsOneWidget);
    expect(find.text('B1-2026-000032'), findsOneWidget);

    await tap(tester, find.text('طباعة الإيصال').first);
    expect(h.membership.files, ['receipt 31']);
    await tap(tester, find.text('فتح الاشتراك'));
    expect(h.location, Routes.child(Routes.memberships, 21));
  });

  testWidgets('another sale starts clean', (tester) async {
    await open(tester, at: Routes.sellTo(15));
    await choosePlan(tester, '12 جلسة');
    await type(tester, '0.00', '18');
    await tap(tester, find.text('تأكيد البيع'));
    await tap(tester, find.text('بيع اشتراك آخر'));
    expect(find.text('اختيار العضو'), findsOneWidget);
    expect(tester.widget<TextField>(field('0.00')).controller!.text, isEmpty);
  });

  testWidgets('personal training needs a trainer', (tester) async {
    await open(tester, at: Routes.sellTo(15));
    await choosePlan(tester, 'تدريب خاص شهري');
    expect(find.text('اختر المدرب'), findsOneWidget);
    await tap(tester, find.text('تأكيد البيع'));
    expect(find.text('اختر المدرب.'), findsOneWidget);
    expect(h.sell.sales, isEmpty);

    await tap(
      tester,
      find.ancestor(of: find.text('اختر المدرب'), matching: find.byType(DropdownButtonFormField<int>)),
    );
    await tap(tester, find.text('كابتن مازن · الفرع الرئيسي - المزة').last);
    await tap(tester, find.text('تأكيد البيع'));
    expect(h.sell.sales.single.body['trainer_id'], 1);
  });

  testWidgets('switching away from personal training drops the trainer check', (tester) async {
    await open(tester, at: Routes.sellTo(15));
    await choosePlan(tester, 'تدريب خاص شهري');
    await choosePlan(tester, 'شهري - كل الفروع');
    await tap(tester, find.text('تأكيد البيع'));
    expect(h.sell.sales.single.body.containsKey('trainer_id'), isFalse);
  });

  testWidgets('coupon: rejected with the reason, then applied and sent', (tester) async {
    await open(tester, at: Routes.sellTo(15));
    await choosePlan(tester, 'شهري - كل الفروع');
    await type(tester, 'WELCOME10', 'nope');
    await tap(tester, find.text('تطبيق'));
    expect(find.text('الكوبون غير موجود'), findsOneWidget);
    await type(tester, 'WELCOME10', 'welcome10');
    await tap(tester, find.text('تطبيق'));
    expect(find.textContaining('كوبون صالح'), findsOneWidget);
    expect(find.text(r'$22.50'), findsWidgets);
    await tap(tester, find.text('تأكيد البيع'));
    expect(h.sell.sales.single.body['coupon_code'], 'WELCOME10');
  });

  testWidgets('manual discount is for the owner only', (tester) async {
    await open(tester, at: Routes.sellTo(15), reception: true);
    expect(find.text('خصم يدوي · للمالك'), findsNothing);
    expect(field('WELCOME10'), findsOneWidget);
  });

  testWidgets('owner manual discount re-quotes and is sent', (tester) async {
    await open(tester, at: Routes.sellTo(15));
    await choosePlan(tester, 'شهري - كل الفروع');
    await tap(tester, find.text('خصم يدوي · للمالك'));
    await type(tester, '5.00', '5');
    await tap(tester, find.text('تطبيق'));
    expect(h.sell.quotes.last, {'plan_id': 1, 'discount_usd': 5.0});
    await tap(tester, find.text('تأكيد البيع'));
    expect(h.sell.sales.single.body['discount_usd'], 5.0);
  });

  testWidgets('a start date from the picker re-quotes and is sent', (tester) async {
    await open(tester, at: Routes.sellTo(15));
    await choosePlan(tester, 'شهري - كل الفروع');
    tester.element(find.byType(SaleDiscountStep)).read<AppFormCubit>().set('starts_on', DateTime(2026, 11, 12));
    await tester.pumpAndSettle();
    expect(h.sell.quotes.last, {'plan_id': 1, 'starts_on': '2026-11-12'});
    await tap(tester, find.text('تأكيد البيع'));
    expect(h.sell.sales.single.body['starts_on'], '2026-11-12');
  });

  testWidgets('closed cash at the chosen branch shows a notice that opens the cash page', (tester) async {
    await open(tester, at: Routes.sellTo(15));
    expect(find.textContaining('لا توجد وردية'), findsNothing);
    await tap(tester, find.text('الفرع الرئيسي - المزة').last);
    await tap(tester, find.text('فرع المالكي').last);
    expect(find.text('لا توجد وردية صندوق مفتوحة بـفرع المالكي.'), findsOneWidget);
    await tap(tester, find.text('فتح الصندوق'));
    expect(h.location, Routes.cashSessions);
  });

  testWidgets('CASH_SESSION_REQUIRED from the server keeps the page and offers the cash page', (tester) async {
    h.sell.sellResult = const ApiFailure(cashRequired);
    await open(tester, at: Routes.sellTo(15));
    await choosePlan(tester, 'شهري - كل الفروع');
    await type(tester, '0.00', '25');
    await tap(tester, find.text('تأكيد البيع'));
    expect(find.text('لا توجد وردية صندوق مفتوحة بهذا الفرع'), findsOneWidget);
    expect(h.location, Routes.sellMembership);
    await tap(tester, find.text('فتح الصندوق'));
    expect(h.location, Routes.cashSessions);
  });

  testWidgets('payment errors from the server show above the button', (tester) async {
    h.sell.sellResult = const ApiFailure(
      Failure(
        type: FailureType.validation,
        message: 'مجموع الدفعات (\$30.00) أكبر من المستحق (\$25.00)',
        errors: {
          'payments': ['مجموع الدفعات أكبر من المستحق'],
        },
      ),
    );
    await open(tester, at: Routes.sellTo(15));
    await choosePlan(tester, 'شهري - كل الفروع');
    await type(tester, '0.00', '30');
    expect(find.text('المدفوع أكثر من الصافي'), findsOneWidget);
    await tap(tester, find.text('تأكيد البيع'));
    expect(find.text('مجموع الدفعات أكبر من المستحق'), findsOneWidget);
  });

  testWidgets('plans failure retries; no plans invites to add one', (tester) async {
    h.sell.plansResult = const ApiFailure(Failure(type: FailureType.network, message: 'تعذّر الاتصال.'));
    await open(tester);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
    h.sell.plansResult = const ApiSuccess([]);
    await tap(tester, find.text('إعادة المحاولة'));
    expect(find.text('لا خطط فعّالة'), findsOneWidget);
  });

  for (final w in [360.0, 800.0, 1024.0, 1440.0]) {
    testWidgets('no overflow at ${w.toInt()}px with a personal plan chosen', (tester) async {
      await open(tester, at: Routes.sellTo(15), width: w);
      await choosePlan(tester, 'تدريب خاص شهري');
      expect(tester.takeException(), isNull);
    });
  }
}
