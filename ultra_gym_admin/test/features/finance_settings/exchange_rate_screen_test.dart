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
      h.pump(tester, width, at: Routes.exchangeRate, session: asOwner ? owner : receptionist);

  Future<void> tap(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  Finder field(String name) => find.descendant(
    of: find.byWidgetPredicate((w) => w is FormText && w.name == name),
    matching: find.byType(TextField),
  );

  testWidgets('owner: the tab, the current rate with who set it, the history with changes, and the form', (
    tester,
  ) async {
    await open(tester);
    expect(h.topTitle(tester), 'الصندوق والحركات');
    expect(find.text('السعر المعتمد الآن'), findsOneWidget);
    expect(find.text('13,000'), findsWidgets);
    expect(find.textContaining('حدّثه سامر الحلبي'), findsOneWidget);
    expect(find.text('السجل'), findsOneWidget);
    expect(find.text('+500'), findsOneWidget);
    expect(find.text('−300'), findsOneWidget);
    expect(find.text('سعر السوق'), findsOneWidget);
    expect(find.text('اعتماد السعر'), findsOneWidget);
    expect(h.finance.rateQueries.single.perPage, 10);
  });

  testWidgets('a new rate posts the number and note with a key, then the page refreshes', (tester) async {
    await open(tester);
    await tester.enterText(field('syp_per_usd'), '13,500');
    await tester.enterText(field('note'), 'سعر المساء');
    await tap(tester, find.text('اعتماد السعر'));
    final sent = h.finance.rateBodies.single;
    expect(sent.body, {'syp_per_usd': 13500, 'note': 'سعر المساء'});
    expect(sent.key, isNotEmpty);
    expect(h.finance.rateQueries, hasLength(2));
    expect(tester.widget<TextField>(field('syp_per_usd')).controller!.text, isEmpty);
  });

  testWidgets('an empty or below-1 rate is caught locally, and a server refusal shows above the form', (
    tester,
  ) async {
    await open(tester);
    await tap(tester, find.text('اعتماد السعر'));
    expect(h.finance.rateBodies, isEmpty);
    await tester.enterText(field('syp_per_usd'), '0');
    await tap(tester, find.text('اعتماد السعر'));
    expect(find.text('اكتب سعراً لا يقل عن 1.'), findsOneWidget);
    expect(h.finance.rateBodies, isEmpty);

    h.finance.setRateResult = const ApiFailure(
      Failure(type: FailureType.forbidden, code: 'FORBIDDEN', message: 'هذه العملية لمالك النادي فقط'),
    );
    await tester.enterText(field('syp_per_usd'), '14000');
    await tap(tester, find.text('اعتماد السعر'));
    expect(find.text('هذه العملية لمالك النادي فقط'), findsOneWidget);
    expect(h.finance.rateQueries, hasLength(1), reason: 'no refresh after a failure');
  });

  testWidgets('no rate yet: the owner is told sales in SYP are refused, and the history invites the first', (
    tester,
  ) async {
    h.finance.ratesResult = ApiSuccess(
      ratesPage(
        rows: const [],
        meta: const {
          'current': {'syp_per_usd': null, 'updated_at': null},
        },
      ),
    );
    await open(tester);
    expect(find.textContaining('أي مبلغ بالليرة يُرفض'), findsOneWidget);
    expect(find.text('لا أسعار مسجّلة بعد'), findsOneWidget);
    expect(find.text('اعتماد السعر'), findsOneWidget);
  });

  testWidgets('reception reads the rate and history without the form', (tester) async {
    await open(tester, asOwner: false);
    expect(find.text('13,000'), findsWidgets);
    expect(find.text('اعتماد السعر'), findsNothing);
    expect(find.byWidgetPredicate((w) => w is FormText), findsNothing);
  });

  testWidgets('the tabs move between the finance pages', (tester) async {
    await open(tester);
    await tap(tester, find.text('التصنيفات'));
    expect(h.location, Routes.financeCategories);
    await tap(tester, find.text('سعر الصرف'));
    expect(h.location, Routes.exchangeRate);
  });

  testWidgets('a failed load offers a retry', (tester) async {
    h.finance.ratesResult = const ApiFailure(Failure(type: FailureType.server, message: 'تعذّر الاتصال بالخادم'));
    await open(tester);
    expect(find.text('تعذّر الاتصال بالخادم'), findsWidgets);
  });

  for (final w in [360.0, 800.0, 1024.0, 1440.0]) {
    testWidgets('no overflow at ${w.toInt()}px', (tester) async {
      await open(tester, width: w);
      expect(tester.takeException(), isNull);
      expect(find.text('اعتماد السعر'), findsOneWidget);
    });
  }
}
