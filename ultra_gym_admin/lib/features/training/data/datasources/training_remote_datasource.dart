import '../../../../core/core.dart';
import '../../domain/models/training_models.dart';
import '../repo/training_repository.dart';

class TrainingRemoteDataSource implements TrainingRepository {
  TrainingRemoteDataSource(this._api);

  final ApiClient _api;

  static const _base = '/club-admin', _plans = '$_base/workout-plans';

  /// قياسات العضو بصفحات كبيرة: الرسم والجدول من نفس الصفحة.
  static const measurementsPerPage = 50;

  @override
  Future<ApiResult<Paged<WorkoutPlan>>> plans(ListQuery query) =>
      _api.getPaged(_plans, fromJson: WorkoutPlan.fromJson, query: query);

  @override
  Future<ApiResult<WorkoutPlan>> plan(int id) => _api.getObject('$_plans/$id', fromJson: WorkoutPlan.fromJson);

  @override
  Future<ApiResult<WorkoutPlan>> savePlan(Json body, {int? id, String? idempotencyKey}) => id == null
      ? _api.post(_plans, body: body, idempotencyKey: idempotencyKey, parse: Parse.object(WorkoutPlan.fromJson))
      : _api.patch('$_plans/$id', body: body, parse: Parse.object(WorkoutPlan.fromJson));

  @override
  Future<ApiResult<void>> deletePlan(int id) => _api.delete('$_plans/$id', parse: Parse.none);

  @override
  Future<ApiResult<WorkoutPlan>> assign(int id, Json body, {String? idempotencyKey}) => _api.post(
    '$_plans/$id/assign',
    body: body,
    idempotencyKey: idempotencyKey,
    parse: Parse.object(WorkoutPlan.fromJson),
  );

  @override
  Future<ApiResult<List<TrainingRef>>> trainers() => _api.getList(
    '$_base/staff-members',
    fromJson: (j) => (id: j.intv('id'), name: j.str('name')),
    query: {'type': 'trainer', 'status': 'active', 'per_page': 100},
  );

  @override
  Future<ApiResult<TrainingMember>> member(int id) => _api.getObject(
    '$_base/players/$id',
    fromJson: (j) => (id: j.intv('id'), name: j.str('name'), memberCode: j.strOrNull('member_code')),
  );

  @override
  Future<ApiResult<MeasurementsPage>> measurements(int playerId, {int page = 1}) async {
    final r = await _api.getPaged(
      '$_base/players/$playerId/measurements',
      fromJson: BodyMeasurement.fromJson,
      query: ListQuery(page: page, perPage: measurementsPerPage),
    );
    return r.map(MeasurementsPage.from);
  }

  @override
  Future<ApiResult<BodyMeasurement>> saveMeasurement(int playerId, Json body, {int? id, String? idempotencyKey}) {
    final path = '$_base/players/$playerId/measurements';
    final parse = Parse.object(BodyMeasurement.fromJson);
    return id == null
        ? _api.post(path, body: body, idempotencyKey: idempotencyKey, parse: parse)
        : _api.patch('$path/$id', body: body, parse: parse);
  }

  @override
  Future<ApiResult<void>> deleteMeasurement(int playerId, int id) =>
      _api.delete('$_base/players/$playerId/measurements/$id', parse: Parse.none);
}
