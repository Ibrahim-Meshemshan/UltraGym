import 'package:get_it/get_it.dart';
import 'package:ultra_gym_admin/core/error/failure.dart';
import 'package:ultra_gym_admin/core/networking/api_result.dart';
import 'package:ultra_gym_admin/core/networking/list_query.dart';
import 'package:ultra_gym_admin/core/networking/paged.dart';
import 'package:ultra_gym_admin/core/utils/json_x.dart';
import 'package:ultra_gym_admin/features/training/data/repo/training_repository.dart';
import 'package:ultra_gym_admin/features/training/domain/models/training_models.dart';
import 'package:ultra_gym_admin/features/training/presentation/bloc/training_cubits.dart';

/// تمرين بشكل رد الخادم.
Json exerciseJson(String name, {int? sets = 4, String? reps = '8-10', int? rest = 90, num? weight, String? notes}) => {
  'name': name,
  'sets': sets,
  'reps': reps,
  'weight_kg': weight,
  'duration_seconds': null,
  'rest_seconds': rest,
  'notes': notes,
};

/// برنامج بشكل `ClubPayloads::workoutPlan` (التفاصيل بأيامها؛ القائمة بلا `days`).
Json workoutJson({
  int id = 1,
  String title = 'تضخيم · 4 أيام',
  bool template = false,
  String source = 'club',
  Json? player = const {'id': 15, 'name': 'عضو تجريبي'},
  Json? trainer = const {'id': 3, 'name': 'باسل حداد'},
  String? startsOn = '2026-11-01',
  String? endsOn = '2026-12-31',
  String status = 'active',
  bool withDays = true,
}) => {
  'id': id,
  'title': title,
  'description': 'الهدف زيادة الكتلة العضلية',
  'is_template': template,
  'source': source,
  'player': template ? null : player,
  'trainer': trainer,
  'starts_on': startsOn,
  'ends_on': endsOn,
  'status': status,
  'days_count': 2,
  if (withDays)
    'days': [
      {
        'day': 1,
        'title': 'صدر وترايسبس',
        'exercises': [
          exerciseJson('بنش برس', weight: 60, notes: 'إحماء خفيف'),
          exerciseJson('تفتيح دمبل', sets: 3, reps: '12'),
        ],
      },
      {
        'day': 2,
        'title': 'ظهر',
        'exercises': [exerciseJson('سحب أمامي')],
      },
    ],
  'created_at': '2026-11-01T09:00:00Z',
};

/// قياس بشكل الرد (`bmi` من الخادم).
Json measurementJson({
  int id = 1,
  String on = '2026-11-04',
  num? weight = 82.4,
  num? fat = 18.2,
  num? muscle = 36.9,
  num? waist = 86,
  num? height = 178,
  num? bmi = 26,
  String? notes,
}) => {
  'id': id,
  'measured_on': on,
  'weight_kg': weight,
  'height_cm': height,
  'body_fat_percent': fat,
  'muscle_mass_kg': muscle,
  'chest_cm': 104,
  'waist_cm': waist,
  'hips_cm': null,
  'arm_cm': 36.5,
  'thigh_cm': null,
  'bmi': bmi,
  'notes': notes,
  'created_at': '2026-11-04T10:00:00Z',
};

List<BodyMeasurement> measurementRows() => [
  BodyMeasurement.fromJson(measurementJson(notes: 'بعد شهرين من البرنامج')),
  BodyMeasurement.fromJson(measurementJson(id: 2, on: '2026-09-01', weight: 84, fat: 19.5, muscle: 36.1, waist: 88)),
  BodyMeasurement.fromJson(measurementJson(id: 3, on: '2026-07-01', weight: 85.5, fat: 20.8, muscle: 35.5, waist: 90)),
];

MeasurementsPage measurementsPage({List<BodyMeasurement>? items, int lastPage = 1, Json? progress}) {
  final rows = items ?? measurementRows();
  return MeasurementsPage.from(
    Paged(
      items: rows,
      pagination: Pagination(currentPage: 1, perPage: 50, total: rows.length, lastPage: lastPage),
      meta: {
        'progress':
            progress ??
            (rows.length < 2
                ? null
                : {'weight_kg': -3.1, 'body_fat_percent': -2.6, 'muscle_mass_kg': 1.4, 'waist_cm': -4, 'height_cm': 0}),
      },
    ),
  );
}

Paged<T> trainingPage<T>(List<T> items) => Paged(
  items: items,
  pagination: Pagination(currentPage: 1, perPage: 30, total: items.length, lastPage: 1),
);

class FakeTrainingRepository implements TrainingRepository {
  ApiResult<Paged<WorkoutPlan>> memberPlans = ApiSuccess(
    trainingPage([
      WorkoutPlan.fromJson(workoutJson(withDays: false)),
      WorkoutPlan.fromJson(
        workoutJson(id: 2, title: 'تنشيف', source: 'player', trainer: null, status: 'archived', withDays: false),
      ),
    ]),
  );
  ApiResult<Paged<WorkoutPlan>> templatePlans = ApiSuccess(
    trainingPage([WorkoutPlan.fromJson(workoutJson(id: 7, title: 'مبتدئ · 3 أيام', template: true, withDays: false))]),
  );
  final details = <int, ApiResult<WorkoutPlan>>{};
  ApiResult<WorkoutPlan>? saveResult, assignResult;
  ApiResult<void> deleteResult = const ApiSuccess(null);
  ApiResult<List<TrainingRef>> trainersResult = const ApiSuccess([(id: 3, name: 'باسل حداد'), (id: 4, name: 'لين سعيد')]);
  ApiResult<MeasurementsPage> measurementsResult = ApiSuccess(measurementsPage());
  ApiResult<BodyMeasurement>? saveMeasurementResult;
  ApiResult<void> deleteMeasurementResult = const ApiSuccess(null);

  final planQueries = <ListQuery>[];
  final saved = <({Json body, int? id, String? key})>[];
  final assigned = <({int id, Json body, String? key})>[];
  final deleted = <int>[];
  final measurementCalls = <({int playerId, int page})>[];
  final savedMeasurements = <({int playerId, Json body, int? id, String? key})>[];
  final deletedMeasurements = <(int, int)>[];
  int memberCalls = 0;

  @override
  Future<ApiResult<Paged<WorkoutPlan>>> plans(ListQuery query) async {
    planQueries.add(query);
    return query.filters[WorkoutFilters.templates] == 1 ? templatePlans : memberPlans;
  }

  @override
  Future<ApiResult<WorkoutPlan>> plan(int id) async =>
      details[id] ??
      switch (id) {
        7 => ApiSuccess(WorkoutPlan.fromJson(workoutJson(id: 7, title: 'مبتدئ · 3 أيام', template: true))),
        2 => ApiSuccess(WorkoutPlan.fromJson(workoutJson(id: 2, title: 'تنشيف', source: 'player', trainer: null))),
        _ => ApiSuccess(WorkoutPlan.fromJson(workoutJson(id: id))),
      };

  @override
  Future<ApiResult<WorkoutPlan>> savePlan(Json body, {int? id, String? idempotencyKey}) async {
    saved.add((body: body, id: id, key: idempotencyKey));
    return saveResult ?? ApiSuccess(WorkoutPlan.fromJson({...workoutJson(id: id ?? 30), 'title': body['title']}));
  }

  @override
  Future<ApiResult<void>> deletePlan(int id) async {
    deleted.add(id);
    return deleteResult;
  }

  @override
  Future<ApiResult<WorkoutPlan>> assign(int id, Json body, {String? idempotencyKey}) async {
    assigned.add((id: id, body: body, key: idempotencyKey));
    return assignResult ?? ApiSuccess(WorkoutPlan.fromJson(workoutJson(id: 40, title: 'مبتدئ · 3 أيام')));
  }

  @override
  Future<ApiResult<List<TrainingRef>>> trainers() async => trainersResult;

  @override
  Future<ApiResult<TrainingMember>> member(int id) async {
    memberCalls++;
    return ApiSuccess((id: id, name: 'عضو تجريبي', memberCode: 'DMO-873152'));
  }

  @override
  Future<ApiResult<MeasurementsPage>> measurements(int playerId, {int page = 1}) async {
    measurementCalls.add((playerId: playerId, page: page));
    return measurementsResult;
  }

  @override
  Future<ApiResult<BodyMeasurement>> saveMeasurement(int playerId, Json body, {int? id, String? idempotencyKey}) async {
    savedMeasurements.add((playerId: playerId, body: body, id: id, key: idempotencyKey));
    return saveMeasurementResult ?? ApiSuccess(BodyMeasurement.fromJson(measurementJson(id: id ?? 9)));
  }

  @override
  Future<ApiResult<void>> deleteMeasurement(int playerId, int id) async {
    deletedMeasurements.add((playerId, id));
    return deleteMeasurementResult;
  }

  static const notFound = ApiFailure<Never>(Failure(type: FailureType.notFound, message: 'العنصر غير موجود.'));
}

/// تسجيلات قسم التدريب بـ GetIt (الهارنس واختبارات الشاشة).
void registerTrainingFakes(FakeTrainingRepository repo) {
  GetIt.instance
    ..registerSingleton<TrainingRepository>(repo)
    ..registerFactoryParam<WorkoutPlansCubit, bool, void>((t, _) => WorkoutPlansCubit(repo, t))
    ..registerFactoryParam<WorkoutPlanCubit, int, void>((id, _) => WorkoutPlanCubit(repo, id))
    ..registerFactory(() => TrainersCubit(repo))
    ..registerFactoryParam<TrainingMemberCubit, int, void>((id, _) => TrainingMemberCubit(repo, id))
    ..registerFactoryParam<MeasurementsCubit, ({int playerId, int page}), void>((a, _) => MeasurementsCubit(repo, a));
}
