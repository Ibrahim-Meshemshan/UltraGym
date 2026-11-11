import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_gym_admin/core/networking/api_result.dart';
import 'package:ultra_gym_admin/core/router/routes.dart';
import 'package:ultra_gym_admin/core/utils/formatters.dart';
import 'package:ultra_gym_admin/core/widgets/form/form_fields.dart';
import 'package:ultra_gym_admin/features/payroll/domain/models/payroll_models.dart';

import '../../core/layout/shell_harness.dart';
import 'fake_payroll_repository.dart';

void main() {
  final h = ShellHarness();
  setUp(h.setUp);
  tearDown(h.tearDown);

  final period = PayrollTexts.recentPeriods(Formatters.clubTime(DateTime.now().toUtc())).first;

  Future<void> open(WidgetTester tester, {double width = 1366}) =>
      h.pump(tester, width, at: Routes.payroll);

  Future<void> tap(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  Finder inDialog(Finder f) => find.descendant(of: find.byType(Dialog).last, matching: f);
  Finder field(String name, {bool dialog = false}) {
    final f = find.descendant(
      of: find.byWidgetPredicate((w) => w is FormText && w.name == name),
      matching: find.byType(TextField),
    );
    return dialog ? inDialog(f) : f;
  }

  group('salaries', () {
    testWidgets('staff with the month status, and the first one previewed', (tester) async {
      await open(tester);
      expect(h.topTitle(tester), 'الرواتب والسلف');
      expect(find.text('الرواتب الشهرية'), findsOneWidget);
      expect(find.text('كابتن مازن'), findsWidgets);
      expect(find.text('مستحق'), findsOneWidget);
      expect(find.text('مصروف'), findsOneWidget);
      expect(h.payroll.salaryQueries.single.filter('period'), period);
      expect(h.payroll.previews.single, (staffId: 1, period: period));
      expect(find.text('مدرب كمال أجسام · الفرع الرئيسي - المزة · راتب ${PayrollTexts.month(period)}'), findsOneWidget);
      expect(find.text('العمولة · 3 عملاء'), findsOneWidget);
      expect(find.text(r'$250.00'), findsWidgets);
      expect(find.text(r'$36.00'), findsWidgets);
      expect(find.text(r'$50.00'), findsOneWidget, reason: 'open advances tile');
      expect(find.text(r'$286.00'), findsOneWidget, reason: 'the estimated net');
      expect(find.text('حتى \$50.00'), findsOneWidget);
    });

    testWidgets('the estimate follows the amounts and the currency', (tester) async {
      await open(tester);
      await tester.enterText(field('bonus_usd'), '10');
      await tester.enterText(field('deductions_usd'), '5');
      await tester.enterText(field('advance_deduction_usd'), '20');
      await tester.pump();
      expect(find.text(r'$271.00'), findsOneWidget);
      expect(find.text(r'- $5.00'), findsNothing);
      expect(find.text(r'− $5.00'), findsOneWidget);
      await tap(tester, find.text('بالليرة'));
      expect(find.text('يعادل \u20663,929,500 ل.س\u2069 بسعر اليوم'), findsOneWidget);
    });

    testWidgets('pay: confirm with the branch, body and key, then the staff shows paid', (tester) async {
      await open(tester);
      await tester.enterText(field('bonus_usd'), '30');
      await tester.enterText(field('advance_deduction_usd'), '50');
      await tester.enterText(field('note'), 'مكافأة الالتزام');
      await tap(tester, find.text('صرف الراتب من الصندوق'));
      expect(inDialog(find.text('صرف راتب كابتن مازن')), findsOneWidget);
      expect(inDialog(find.text('صندوق الفرع *', findRichText: true)), findsOneWidget);
      await tap(tester, inDialog(find.text('صرف الراتب')));
      final sent = h.payroll.paid.single;
      expect(sent.staffId, 1);
      expect(sent.body, {
        'period': period,
        'currency': 'USD',
        'bonus_usd': 30,
        'advance_deduction_usd': 50,
        'note': 'مكافأة الالتزام',
        'branch_id': 1,
      });
      expect(sent.key, isNotEmpty);
      expect(find.byType(Dialog), findsNothing);
      expect(find.text('مستحق'), findsNothing, reason: 'the roster reloaded');
      expect(find.text('صرف الراتب من الصندوق'), findsNothing);
      expect(find.text(r'$316.00'), findsOneWidget);
    });

    testWidgets('local checks: advance over the open amount and a negative net', (tester) async {
      await open(tester);
      await tester.enterText(field('advance_deduction_usd'), '60');
      await tester.enterText(field('deductions_usd'), '400');
      await tap(tester, find.text('صرف الراتب من الصندوق'));
      expect(find.byType(Dialog), findsNothing);
      expect(find.textContaining('أقصى خصم'), findsOneWidget);
      expect(find.text('الخصومات أكبر من الراتب: الصافي سالب.'), findsOneWidget);
      expect(h.payroll.paid, isEmpty);
    });

    testWidgets('closed cash box: the server message with the open-box action', (tester) async {
      h.payroll.payResult = cashRequired;
      await open(tester);
      await tap(tester, find.text('صرف الراتب من الصندوق'));
      await tap(tester, inDialog(find.text('صرف الراتب')));
      expect(inDialog(find.text('لا توجد وردية صندوق مفتوحة لهذا الفرع')), findsOneWidget);
      expect(inDialog(find.text('فتح الصندوق')), findsOneWidget);
    });

    testWidgets('a paid salary shows its saved lines and receipt, without a preview', (tester) async {
      await open(tester);
      await tap(tester, find.text('كابتن لينا'));
      expect(find.text('مصروف 2026-11-05'), findsOneWidget);
      expect(find.textContaining('لا يمكن صرفه مرة ثانية'), findsOneWidget);
      expect(find.text('طباعة الإيصال'), findsOneWidget);
      expect(find.text(r'$162.41'), findsOneWidget);
      expect(find.text('خصم تأخير'), findsOneWidget);
      expect(h.payroll.previews.map((p) => p.staffId), [1]);
      await tap(tester, find.text('دفتر الحركات'));
      expect(h.location, Routes.transactions);
    });

    testWidgets('another month reloads the roster for it', (tester) async {
      await open(tester);
      final previous = PayrollTexts.recentPeriods(Formatters.clubTime(DateTime.now().toUtc()))[1];
      await tap(tester, find.textContaining('الشهر:'));
      await tap(tester, find.widgetWithText(MenuItemButton, PayrollTexts.month(previous)));
      expect(h.payroll.salaryQueries.last.filter('period'), previous);
      expect(h.payroll.previews.last.period, previous);
    });

    testWidgets('no active staff: an invitation, no preview', (tester) async {
      h.payroll.staffResult = const ApiSuccess([]);
      await open(tester);
      expect(find.text('لا موظفين فعّالين'), findsOneWidget);
      expect(h.payroll.previews, isEmpty);
    });
  });

  group('advances', () {
    Future<void> openAdvances(WidgetTester tester, {double width = 1366}) async {
      await open(tester, width: width);
      await tap(tester, find.text('السلف'));
    }

    testWidgets('stats, every row by default, then open only', (tester) async {
      await openAdvances(tester);
      expect(find.text('سلف مفتوحة'), findsOneWidget);
      expect(find.text('المتبقي للخصم'), findsOneWidget);
      expect(find.text('كابتن لينا'), findsOneWidget);
      expect(find.text('مسددة'), findsWidgets);
      expect(find.text('الإيصال'), findsNWidgets(2));
      await tap(tester, find.text('مفتوحة').first);
      expect(find.text('كابتن مازن'), findsOneWidget);
      expect(find.text('كابتن لينا'), findsNothing);
      expect(h.payroll.advanceQueries.last.filter('status'), 'open');
    });

    testWidgets('pay an advance: staff, amount, note, branch and key', (tester) async {
      await openAdvances(tester);
      await tap(tester, find.text('صرف سلفة'));
      await tap(tester, inDialog(find.byType(DropdownButtonFormField<int>)).first);
      await tap(tester, find.text('كابتن لينا').last);
      await tester.enterText(field('amount', dialog: true), '25');
      await tester.enterText(field('note', dialog: true), 'إيجار البيت');
      await tap(tester, inDialog(find.text('صرف السلفة')));
      final sent = h.payroll.added.single;
      expect(sent.body, {
        'staff_member_id': 2,
        'currency': 'USD',
        'amount': 25,
        'note': 'إيجار البيت',
        'branch_id': 1,
      });
      expect(sent.key, isNotEmpty);
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('an advance needs the staff and a positive amount', (tester) async {
      await openAdvances(tester);
      await tap(tester, find.text('صرف سلفة'));
      await tester.enterText(field('amount', dialog: true), '0');
      await tap(tester, inDialog(find.text('صرف السلفة')));
      expect(inDialog(find.text('اكتب مبلغاً أكبر من صفر.')), findsOneWidget);
      expect(h.payroll.added, isEmpty);
    });

    testWidgets('empty: an invitation to pay one', (tester) async {
      h.payroll.advancesResult = ApiSuccess(pageOf(const <StaffAdvance>[]));
      await openAdvances(tester);
      expect(find.text('لا سلف بعد'), findsOneWidget);
    });
  });

  for (final w in [360.0, 800.0, 1024.0, 1440.0]) {
    testWidgets('no overflow at ${w.toInt()}px: salaries with the confirm, then advances with the dialog', (tester) async {
      await open(tester, width: w);
      expect(tester.takeException(), isNull);
      await tap(tester, find.text('صرف الراتب من الصندوق'));
      expect(tester.takeException(), isNull);
      await tap(tester, inDialog(find.text('إلغاء')));
      await tap(tester, find.text('كابتن لينا').first);
      expect(tester.takeException(), isNull);
      await tap(tester, find.text('السلف'));
      expect(tester.takeException(), isNull);
      await tap(tester, find.text('صرف سلفة').first);
      expect(tester.takeException(), isNull);
    });
  }
}
