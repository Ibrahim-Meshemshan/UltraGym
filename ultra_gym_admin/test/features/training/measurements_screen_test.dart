import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_gym_admin/core/networking/api_result.dart';
import 'package:ultra_gym_admin/core/router/routes.dart';
import 'package:ultra_gym_admin/core/widgets/form/form_fields.dart';
import 'package:ultra_gym_admin/features/training/presentation/screens/training_screen.dart';

import '../../core/layout/shell_harness.dart';
import '../../helpers/app_fonts.dart';
import 'fake_training_repository.dart';

void main() {
  final h = ShellHarness();
  setUpAll(loadAppFonts);
  setUp(h.setUp);
  tearDown(h.tearDown);

  Future<void> open(WidgetTester tester, {double width = 1280, bool asOwner = true, int? playerId = 15}) => h.pump(
    tester,
    width,
    at: playerId == null ? '${Routes.training}?tab=${TrainingScreen.measurementsTab}' : Routes.measurementsOf(playerId),
    session: asOwner ? owner : receptionist,
  );

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

  testWidgets('no member yet: an invitation; picking one loads the values, trend and table', (tester) async {
    await open(tester, playerId: null);
    expect(find.text('اختر عضواً لعرض قياساته'), findsOneWidget);
    expect(h.training.measurementCalls, isEmpty);

    await tap(tester, find.text('اختيار عضو').first);
    await tester.enterText(find.descendant(of: find.byType(Dialog), matching: find.byType(TextField)), 'أحمد');
    await tester.pumpAndSettle();
    await tap(tester, find.text('أحمد الخطيب'));
    expect(h.training.measurementCalls, [(playerId: 3, page: 1)]);
    expect(find.text('أحمد الخطيب · DMO-098969'), findsOneWidget);

    expect(find.text('مؤشر كتلة الجسم'), findsOneWidget);
    for (final t in ['82.4 kg', '18.2%', '36.9 kg', '86 cm', '178 cm']) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
    expect(find.text('−3.1 منذ البداية'), findsOneWidget);
    expect(find.text('+1.4 منذ البداية'), findsOneWidget);
    expect(find.text('الوزن عبر الزمن'), findsOneWidget);
    expect(find.text('2026-07-01 · 85.5 kg'), findsOneWidget);
    expect(find.text('الدهون'), findsOneWidget);
    expect(find.text('بعد شهرين من البرنامج'), findsOneWidget);
    expect(find.text('سجّله'), findsNothing, reason: 'the server does not send who recorded it');
  });

  testWidgets('link from the profile opens the member measurements directly', (tester) async {
    await open(tester);
    expect(h.training.memberCalls, 1);
    expect(find.text('عضو تجريبي · DMO-873152'), findsOneWidget);
    expect(h.training.measurementCalls, [(playerId: 15, page: 1)]);
  });

  testWidgets('new measurement: at least one value, max checked, numbers sent with a key', (tester) async {
    await open(tester);
    await tap(tester, find.text('قياس جديد'));
    expect(find.text('قياس جديد · عضو تجريبي'), findsOneWidget);
    await tap(tester, inDialog(find.text('حفظ القياس')));
    expect(inDialog(find.text('اكتب قياساً واحداً على الأقل.')), findsOneWidget);
    expect(h.training.savedMeasurements, isEmpty);

    await tester.enterText(field('weight_kg'), '81,9');
    await tester.enterText(field('body_fat_percent'), '95');
    await tap(tester, inDialog(find.text('حفظ القياس')));
    expect(inDialog(find.text('أقصى قيمة 80.')), findsOneWidget);
    await tester.enterText(field('body_fat_percent'), '17.5');
    await tap(tester, inDialog(find.text('حفظ القياس')));

    final s = h.training.savedMeasurements.single;
    expect((s.playerId, s.id), (15, null));
    expect(s.key, isNotNull);
    expect(s.body['weight_kg'], 81.9);
    expect(s.body['body_fat_percent'], 17.5);
    expect(s.body['measured_on'], isA<String>());
    expect(s.body.containsKey('height_cm'), isFalse);
    expect(find.byType(Dialog), findsNothing);
    expect(h.training.measurementCalls, hasLength(2), reason: 'refreshed after saving');
  });

  testWidgets('editing patches the measurement; a cleared field is sent as null', (tester) async {
    await open(tester);
    await tap(tester, find.byTooltip('تعديل القياس').first);
    expect(find.text('تعديل قياس · عضو تجريبي'), findsOneWidget);
    expect(tester.widget<TextField>(field('weight_kg')).controller!.text, '82.4');
    await tester.enterText(field('weight_kg'), '82');
    await tester.enterText(field('arm_cm'), '');
    await tap(tester, inDialog(find.text('حفظ القياس')));
    final s = h.training.savedMeasurements.single;
    expect((s.id, s.key), (1, null));
    expect(s.body['weight_kg'], 82);
    expect(s.body.containsKey('arm_cm'), isTrue);
    expect(s.body['arm_cm'], isNull);
    expect(s.body['notes'], 'بعد شهرين من البرنامج');
  });

  testWidgets('deleting a measurement after confirmation', (tester) async {
    await open(tester);
    await tap(tester, find.byTooltip('حذف القياس').first);
    await tap(tester, inDialog(find.text('حذف')));
    expect(h.training.deletedMeasurements, [(15, 1)]);
    expect(h.training.measurementCalls, hasLength(2));
  });

  testWidgets('a member without measurements: an invitation for the owner', (tester) async {
    h.training.measurementsResult = ApiSuccess(measurementsPage(items: const []));
    await open(tester);
    expect(find.text('لا قياسات لـ عضو تجريبي بعد'), findsOneWidget);
    await tap(tester, find.text('قياس جديد').last);
    expect(find.text('قياس جديد · عضو تجريبي'), findsOneWidget);
  });

  testWidgets('receptionist reads measurements without actions', (tester) async {
    await open(tester, asOwner: false);
    expect(find.text('82.4 kg'), findsOneWidget);
    expect(find.text('قياس جديد'), findsNothing);
    expect(find.byTooltip('تعديل القياس'), findsNothing);
    expect(find.byTooltip('حذف القياس'), findsNothing);
  });

  testWidgets('second page: table only, values stay with the latest page', (tester) async {
    h.training.measurementsResult = ApiSuccess(measurementsPage(lastPage: 2));
    await open(tester);
    await tap(tester, find.byTooltip('الصفحة التالية'));
    expect(h.training.measurementCalls.last, (playerId: 15, page: 2));
    expect(find.text('الوزن عبر الزمن'), findsNothing);
    expect(find.text('الدهون'), findsOneWidget);
  });

  for (final w in [360.0, 800.0, 1024.0, 1440.0]) {
    testWidgets('no overflow at ${w.toInt()}px: values, trend, table and the dialog', (tester) async {
      await open(tester, width: w);
      expect(tester.takeException(), isNull);
      await tap(tester, find.text('قياس جديد'));
      expect(tester.takeException(), isNull);
    });
  }
}
