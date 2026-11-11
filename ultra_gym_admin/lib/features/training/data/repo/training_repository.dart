import '../../../../core/core.dart';
import '../../domain/models/training_models.dart';

/// برامج التدريب وقياسات الأعضاء (`club-admin/workout-plans`، `club-admin/players/{id}/measurements`).
abstract interface class TrainingRepository {
  /// `GET workout-plans` (فلاتر `templates` 1|0، `status`، `search` بالعنوان)، الأحدث أولاً، بلا الأيام.
  Future<ApiResult<Paged<WorkoutPlan>>> plans(ListQuery query);

  /// `GET workout-plans/{id}` بالأيام والتمارين.
  Future<ApiResult<WorkoutPlan>> plan(int id);

  /// `POST workout-plans` (بمفتاح منع التكرار) أو `PATCH workout-plans/{id}`.
  Future<ApiResult<WorkoutPlan>> savePlan(Json body, {int? id, String? idempotencyKey});

  Future<ApiResult<void>> deletePlan(int id);

  /// `POST workout-plans/{id}/assign {player_id, starts_on?, ends_on?}` ← نسخة جديدة للعضو.
  Future<ApiResult<WorkoutPlan>> assign(int id, Json body, {String? idempotencyKey});

  /// المدربون الفعّالون `GET staff-members?type=trainer&status=active` (القائمة متاحة للاستقبال).
  Future<ApiResult<List<TrainingRef>>> trainers();

  /// اسم العضو ومعرّفه لرابط `?player_id=` (`GET players/{id}`).
  Future<ApiResult<TrainingMember>> member(int id);

  /// `GET players/{id}/measurements` (الأحدث أولاً) + `meta.progress`.
  Future<ApiResult<MeasurementsPage>> measurements(int playerId, {int page = 1});

  /// `POST` (بمفتاح) أو `PATCH players/{id}/measurements/{measurement_id}`.
  Future<ApiResult<BodyMeasurement>> saveMeasurement(int playerId, Json body, {int? id, String? idempotencyKey});

  Future<ApiResult<void>> deleteMeasurement(int playerId, int id);
}
