import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_gym_admin/core/bloc/app_form_cubit.dart';
import 'package:ultra_gym_admin/core/bloc/slice.dart';
import 'package:ultra_gym_admin/core/error/failure.dart';
import 'package:ultra_gym_admin/core/networking/api_result.dart';
import 'package:ultra_gym_admin/features/training/domain/models/training_models.dart';
import 'package:ultra_gym_admin/features/training/domain/models/workout_draft.dart';
import 'package:ultra_gym_admin/features/training/presentation/bloc/training_cubits.dart';
import 'package:ultra_gym_admin/features/training/presentation/bloc/workout_editor_cubit.dart';
import 'package:ultra_gym_admin/features/training/presentation/widgets/measurement_actions.dart';
import 'package:ultra_gym_admin/features/training/presentation/widgets/measurement_values.dart';

import 'fake_training_repository.dart';

void main() {
  group('models', () {
    test('workout plan with days, exercises and refs from the server shape', () {
      final p = WorkoutPlan.fromJson(workoutJson());
      expect(p.title, 'تضخيم · 4 أيام');
      expect(p.player, (id: 15, name: 'عضو تجريبي'));
      expect(p.trainer, (id: 3, name: 'باسل حداد'));
      expect(p.startsOn, DateTime(2026, 11, 1));
      expect(p.days, hasLength(2));
      final e = p.days.first.exercises.first;
      expect((e.name, e.sets, e.reps, e.weightKg, e.restSeconds, e.notes), ('بنش برس', 4, '8-10', 60.0, 90, 'إحماء خفيف'));
      expect(TrainingTexts.subtitle(p), 'عضو تجريبي · يومان · باسل حداد');

      final t = WorkoutPlan.fromJson(workoutJson(template: true, trainer: null, withDays: false));
      expect((t.isTemplate, t.player, t.days.length), (true, null, 0));
      expect(TrainingTexts.subtitle(t), 'قالب عام · يومان');
      expect(WorkoutPlan.fromJson(workoutJson(source: 'player', status: 'archived')).byPlayer, isTrue);
    });

    test('measurements page: values, bmi and server progress', () {
      final page = measurementsPage();
      final m = page.items.first;
      expect(m[MeasureField.weight], 82.4);
      expect(m[MeasureField.hips], isNull);
      expect(m.bmi, 26);
      expect(page.progress![MeasureField.weight], -3.1);
      expect(page.progress![MeasureField.muscle], 1.4);
      expect(measurementsPage(items: [m]).progress, isNull);
    });

    test('texts: values with units, signed deltas, day counts', () {
      expect(TrainingTexts.value(82.4, 'kg'), '82.4 kg');
      expect(TrainingTexts.value(18.2, '%'), '18.2%');
      expect(TrainingTexts.value(null, 'kg'), '—');
      expect(TrainingTexts.delta(-3.1), '−3.1');
      expect(TrainingTexts.delta(1.4), '+1.4');
      expect(TrainingTexts.delta(0), '0');
    });

    test('weight trend points run oldest first and skip missing weights', () {
      final rows = [...measurementRows(), BodyMeasurement.fromJson(measurementJson(id: 4, on: '2026-06-01', weight: null))];
      expect(WeightTrend.pointsOf(rows).map((p) => p.$2), [85.5, 84.0, 82.4]);
    });
  });

  group('draft', () {
    test('of(plan) keeps hidden fields; body numbers days in order and sends player only when new', () {
      final d = WorkoutDraft.of(WorkoutPlan.fromJson(workoutJson()));
      final body = d.body();
      expect(body.containsKey('player_id'), isFalse);
      expect(body['trainer_id'], 3);
      expect(body['starts_on'], '2026-11-01');
      final days = body['days'] as List<Object?>;
      expect([for (final x in days) (x! as Map)['day']], [1, 2]);
      final first = ((days.first! as Map)['exercises'] as List).first as Map;
      expect(first, {'name': 'بنش برس', 'sets': 4, 'reps': '8-10', 'rest_seconds': 90, 'notes': 'إحماء خفيف', 'weight_kg': 60.0});

      final fresh = WorkoutDraft.blank(memberPlan: true).copyWith(title: ' جديد ', player: ((id: 15, name: 'عضو'),));
      expect(fresh.body()['player_id'], 15);
      expect(fresh.body()['title'], 'جديد');
      expect(fresh.body()['description'], isNull);
    });

    test('validate uses the server keys', () {
      final blank = WorkoutDraft.blank(memberPlan: true);
      expect(blank.validate().keys, containsAll(['title', 'player_id', 'days.0.title', 'days.0.exercises.0.name']));
      expect(WorkoutDraft.blank(memberPlan: false).validate().containsKey('player_id'), isFalse);

      final day = DayDraft.blank();
      final bad = WorkoutDraft(
        title: 'x',
        startsOn: DateTime(2026, 12, 1),
        endsOn: DateTime(2026, 11, 1),
        days: [
          day.copyWith(
            title: 'يوم',
            exercises: [day.exercises.first.copyWith(name: 'سكوات', sets: '0', rest: '2000')],
          ),
        ],
      );
      expect(bad.validate(), {
        'ends_on': 'تاريخ النهاية قبل البداية.',
        'days.0.exercises.0.sets': 'من 1 إلى 50.',
        'days.0.exercises.0.rest_seconds': 'من 0 إلى 1800 ثانية.',
      });
      expect(const WorkoutDraft(title: 'x').validate(), {'days': 'أضف يوماً واحداً على الأقل.'});
    });
  });

  group('editor cubit', () {
    late FakeTrainingRepository repo;
    setUp(() => repo = FakeTrainingRepository());

    test('local errors block saving; editing a field clears its error', () async {
      final cubit = WorkoutEditorCubit(repo, WorkoutDraft.blank(memberPlan: false));
      expect(await cubit.save(), isNull);
      expect(repo.saved, isEmpty);
      expect(cubit.state.error('title'), 'اكتب عنوان الخطة.');
      cubit.setTitle('قالب');
      expect(cubit.state.error('title'), isNull);
      expect(cubit.state.error('days.0.title'), isNotNull);
      await cubit.close();
    });

    test('days and exercises: add, remove, limits; new save posts with a key and the same key on retry', () async {
      final cubit = WorkoutEditorCubit(repo, WorkoutDraft.blank(memberPlan: false))..setTitle('قالب');
      final day = cubit.state.draft.days.single;
      cubit
        ..setDayTitle(day.uid, 'صدر')
        ..setExercise(day.uid, day.exercises.single.uid, 'name', 'بنش')
        ..addExercise(day.uid)
        ..addDay();
      expect(cubit.state.draft.days, hasLength(2));
      expect(cubit.state.draft.days.first.exercises, hasLength(2));
      cubit
        ..removeExercise(day.uid, cubit.state.draft.days.first.exercises.last.uid)
        ..removeDay(cubit.state.draft.days.last.uid);

      repo.saveResult = const ApiFailure(
        Failure(type: FailureType.validation, message: 'البيانات المدخلة غير صالحة', errors: {'days.0.title': ['مكرر']}),
      );
      expect(await cubit.save(), isNull);
      expect(cubit.state.error('days.0.title'), 'مكرر');
      expect(cubit.state.failure?.message, 'البيانات المدخلة غير صالحة');
      repo.saveResult = null;
      final saved = await cubit.save();
      expect(saved?.id, 30);
      expect(repo.saved.map((s) => s.key).toSet(), hasLength(1));
      expect(repo.saved.first.key, isNotNull);
      expect(cubit.state.draft.id, 30);
      await cubit.close();
    });

    test('existing plan saves with PATCH (no key)', () async {
      final cubit = WorkoutEditorCubit(repo, WorkoutDraft.of(WorkoutPlan.fromJson(workoutJson(id: 5))));
      await cubit.save();
      expect((repo.saved.single.id, repo.saved.single.key), (5, null));
      await cubit.close();
    });
  });

  group('cubits', () {
    test('plans list sends templates as 1/0', () async {
      final repo = FakeTrainingRepository();
      final members = WorkoutPlansCubit(repo, false);
      final templates = WorkoutPlansCubit(repo, true);
      await members.load();
      await templates.load();
      expect(repo.planQueries.map((q) => q.filters[WorkoutFilters.templates]), [0, 1]);
      expect(templates.state.slice.data!.items.single.title, 'مبتدئ · 3 أيام');
      await members.close();
      await templates.close();
    });

    test('measurements by member and page', () async {
      final repo = FakeTrainingRepository();
      final cubit = MeasurementsCubit(repo, (playerId: 15, page: 2));
      await cubit.load();
      expect(repo.measurementCalls.single, (playerId: 15, page: 2));
      expect(cubit.state.status, LoadStatus.success);
      await cubit.close();
    });
  });

  group('measurement body', () {
    test('numbers parsed (comma decimals), empty skipped on create and sent as null on edit', () {
      final form = AppFormCubit(initial: {'measured_on': DateTime(2026, 11, 4)});
      form.text('weight_kg').text = '82,4';
      form.text('height_cm').text = '178';
      form.text('body_fat_percent').text = '';
      form.text('notes').text = 'بعد البرنامج';
      expect(MeasurementActions.bodyOf(form, keepNulls: false), {
        'measured_on': '2026-11-04',
        'notes': 'بعد البرنامج',
        'weight_kg': 82.4,
        'height_cm': 178,
      });
      final edit = MeasurementActions.bodyOf(form, keepNulls: true);
      expect(edit['body_fat_percent'], isNull);
      expect(edit.containsKey('thigh_cm'), isTrue);
      form.close();
    });
  });
}
