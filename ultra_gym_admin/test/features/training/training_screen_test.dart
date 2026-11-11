import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_gym_admin/core/error/failure.dart';
import 'package:ultra_gym_admin/core/networking/api_result.dart';
import 'package:ultra_gym_admin/core/router/routes.dart';
import 'package:ultra_gym_admin/features/training/presentation/bloc/training_cubits.dart';
import 'package:ultra_gym_admin/core/widgets/form/draft_field.dart';
import 'package:ultra_gym_admin/features/training/domain/models/training_models.dart';
import 'package:ultragym_design/ultragym_design.dart';

import '../../core/layout/shell_harness.dart';
import '../../helpers/app_fonts.dart';
import 'fake_training_repository.dart';

void main() {
  final h = ShellHarness();
  setUpAll(loadAppFonts);
  setUp(h.setUp);
  tearDown(h.tearDown);

  Future<void> open(WidgetTester tester, {double width = 1280, bool asOwner = true}) =>
      h.pump(tester, width, at: Routes.training, session: asOwner ? owner : receptionist);

  Future<void> tap(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  /// حقل بالمحرر بمفتاحه: `workout-title`، أو بادئة ولاحقة (`day-` + `-title`، `ex-` + `-name`).
  Finder draft({String? key, String prefix = '', String suffix = ''}) => find.descendant(
    of: find.byWidgetPredicate((w) {
      final k = w is DraftField ? (w.key as ValueKey<String>?)?.value : null;
      return k != null && (key == null ? k.startsWith(prefix) && k.endsWith(suffix) : k == key);
    }),
    matching: find.byType(TextField),
  );

  Future<void> type(WidgetTester tester, Finder f, String text) async {
    await tester.ensureVisible(f);
    await tester.enterText(f, text);
    await tester.pump();
  }

  Future<void> pickMember(WidgetTester tester, Finder opener) async {
    await tap(tester, opener);
    await tester.enterText(find.descendant(of: find.byType(Dialog), matching: find.byType(TextField)), 'أحمد');
    await tester.pumpAndSettle();
    await tap(tester, find.text('أحمد الخطيب'));
  }

  Finder badge(String text) => find.descendant(of: find.byType(StatusBadge), matching: find.text(text));

  testWidgets('owner: member plans, the first open in the editor with its days, and the trainers link', (tester) async {
    await open(tester);
    expect(h.topTitle(tester), 'المدربون والتدريب');
    expect(h.training.planQueries.single.filters[WorkoutFilters.templates], 0);
    expect(find.text('تنشيف'), findsOneWidget);
    expect(badge('مؤرشفة'), findsOneWidget);
    expect(badge('أضافها العضو'), findsOneWidget);
    expect(find.text('اليوم 1'), findsOneWidget);
    expect(find.text('اليوم 2'), findsOneWidget);
    expect(find.text('بنش برس'), findsWidgets);
    expect(find.text('باسل حداد'), findsWidgets);
    expect(find.textContaining('2026-12-31'), findsOneWidget);

    await tap(tester, find.text('تنشيف'));
    expect(find.text('أضافها العضو من تطبيقه؛ تعديلها من هنا يظهر له.'), findsOneWidget);

    await tap(tester, find.text('المدربون'));
    expect(h.location, Routes.staff);
    expect(find.text('سجلات للرواتب والعمولات فقط. المدربون والعمال لا يدخلون النظام.'), findsOneWidget);
  });

  testWidgets('templates tab: sends templates=1 and shows the template badge', (tester) async {
    await open(tester);
    await tap(tester, find.text('قوالب عامة'));
    expect(h.training.planQueries.last.filters[WorkoutFilters.templates], 1);
    expect(find.text('مبتدئ · 3 أيام'), findsWidgets);
    expect(badge('قالب عام'), findsOneWidget);
  });

  testWidgets('new member plan: local errors, member picked, days and exercises added, saved with a key', (tester) async {
    await open(tester);
    await tap(tester, find.text('خطة'));
    expect(find.text('خطة جديدة لعضو'), findsOneWidget);

    await tap(tester, find.text('حفظ الخطة'));
    for (final e in ['اكتب عنوان الخطة.', 'اختر العضو.', 'اكتب عنوان اليوم.', 'اكتب اسم التمرين.']) {
      expect(find.text(e), findsOneWidget);
    }
    expect(h.training.saved, isEmpty);

    await type(tester, draft(key: 'workout-title'), 'خطة أحمد');
    await pickMember(tester, find.text('اختر العضو'));
    expect(find.text('أحمد الخطيب'), findsOneWidget);
    await type(tester, draft(prefix: 'day-', suffix: '-title').first, 'صدر');
    await type(tester, draft(prefix: 'ex-', suffix: '-name').first, 'بنش');
    await type(tester, draft(prefix: 'ex-', suffix: '-sets').first, '4');
    await type(tester, draft(prefix: 'ex-', suffix: '-reps').first, '8-10');
    await tap(tester, find.text('تمرين'));
    await type(tester, draft(prefix: 'ex-', suffix: '-name').at(1), 'تفتيح');
    await tap(tester, find.text('يوم'));
    expect(find.text('اليوم 2'), findsOneWidget);
    await type(tester, draft(prefix: 'day-', suffix: '-title').at(1), 'ظهر');
    await type(tester, draft(prefix: 'ex-', suffix: '-name').at(2), 'سحب');

    await tap(tester, find.text('حفظ الخطة'));
    final s = h.training.saved.single;
    expect(s.id, isNull);
    expect(s.key, isNotNull);
    expect(s.body['player_id'], 3);
    expect(s.body['title'], 'خطة أحمد');
    final days = s.body['days']! as List<Object?>;
    expect(days, hasLength(2));
    final first = days.first! as Map<String, Object?>;
    expect(first['title'], 'صدر');
    expect(first['exercises'], [
      {'name': 'بنش', 'sets': 4, 'reps': '8-10'},
      {'name': 'تفتيح'},
    ]);
    expect(h.training.planQueries, hasLength(2), reason: 'the list refreshes after saving');
  });

  testWidgets('editing an existing plan patches it; 422 shows under the field', (tester) async {
    await open(tester);
    await type(tester, draft(key: 'workout-title'), 'مكرر');
    h.training.saveResult = const ApiFailure(
      Failure(type: FailureType.validation, message: 'البيانات المدخلة غير صالحة', errors: {'title': ['العنوان مستعمل.']}),
    );
    await tap(tester, find.text('حفظ الخطة'));
    expect((h.training.saved.single.id, h.training.saved.single.key), (1, null));
    expect(find.text('العنوان مستعمل.'), findsOneWidget);
    expect(find.text('البيانات المدخلة غير صالحة'), findsOneWidget);
  });

  testWidgets('removing a day keeps the other; a single exercise cannot be removed', (tester) async {
    await open(tester);
    expect(find.text('حذف اليوم'), findsNWidgets(2));
    await tap(tester, find.text('حذف اليوم').first);
    expect(find.text('اليوم 2'), findsNothing);
    expect(find.text('سحب أمامي'), findsOneWidget);
    expect(find.text('حذف اليوم'), findsNothing);
    expect(find.byTooltip('حذف التمرين'), findsNothing);
  });

  testWidgets('assigning a template copies it to the member and opens the copy', (tester) async {
    await open(tester);
    await tap(tester, find.text('قوالب عامة'));
    await pickMember(tester, find.text('إسناد لعضو'));
    expect(find.text('إسناد الخطة لعضو'), findsOneWidget);
    await tap(tester, find.text('إسناد'));
    final a = h.training.assigned.single;
    expect(a.id, 7);
    expect(a.body, {'player_id': 3});
    expect(a.key, isNotNull);
    expect(h.training.planQueries.last.filters[WorkoutFilters.templates], 0);
  });

  testWidgets('deleting a plan after confirmation', (tester) async {
    await open(tester);
    await tap(tester, find.byTooltip('حذف الخطة'));
    expect(find.textContaining('وتختفي من تطبيق عضو تجريبي'), findsOneWidget);
    await tap(tester, find.text('حذف'));
    expect(h.training.deleted, [1]);
    expect(h.training.planQueries, hasLength(2), reason: 'the list refreshes after deleting');
  });

  testWidgets('receptionist reads plans without edit actions', (tester) async {
    await open(tester, asOwner: false);
    expect(find.text('بنش برس'), findsWidgets);
    for (final t in ['خطة', 'حفظ الخطة', 'إسناد لعضو', 'يوم', 'تمرين', 'المدربون']) {
      expect(find.text(t), findsNothing, reason: t);
    }
    expect(find.byTooltip('حذف الخطة'), findsNothing);
    expect(tester.widget<TextField>(draft(key: 'workout-title')).enabled, isFalse);
  });

  testWidgets('no plans: an invitation to add the first', (tester) async {
    h.training.memberPlans = ApiSuccess(trainingPage(<WorkoutPlan>[]));
    await open(tester);
    expect(find.text('لا خطط لأعضاء بعد'), findsOneWidget);
  });

  for (final w in [360.0, 800.0, 1024.0, 1440.0]) {
    testWidgets('no overflow at ${w.toInt()}px: editor, templates and a new plan', (tester) async {
      await open(tester, width: w);
      expect(tester.takeException(), isNull);
      await tap(tester, find.text('قوالب عامة'));
      expect(tester.takeException(), isNull);
      await tap(tester, find.text('خطة'));
      expect(find.text('قالب جديد'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
