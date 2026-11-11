import '../../../../core/core.dart';
import '../../domain/models/day_pass_models.dart';
import '../repo/day_passes_repository.dart';

class DayPassesRemoteDataSource implements DayPassesRepository {
  DayPassesRemoteDataSource(this._api);

  final ApiClient _api;

  static const _path = '/club-admin/day-passes';

  @override
  Future<ApiResult<Paged<DayPass>>> list(ListQuery query, {int? branchId}) =>
      _api.getPaged(_path, fromJson: DayPass.fromJson, query: query, extra: {DayPassFilters.branchId: ?branchId});

  @override
  Future<ApiResult<DayPassPrice>> price({int? branchId}) =>
      _api.getObject('$_path/price', fromJson: DayPassPrice.fromJson, query: {'branch_id': ?branchId});

  @override
  Future<ApiResult<DayPass>> sell(Json body, {required String idempotencyKey}) =>
      _api.post(_path, body: body, idempotencyKey: idempotencyKey, parse: Parse.object(DayPass.fromJson));

  @override
  Future<ApiResult<DayPass>> detail(int id) => _api.getObject('$_path/$id', fromJson: DayPass.fromJson);

  @override
  Future<ApiResult<DayPass>> cancel(int id, String reason, {required String idempotencyKey}) => _api.post(
    '$_path/$id/cancel',
    body: {'reason': reason},
    idempotencyKey: idempotencyKey,
    parse: Parse.object(DayPass.fromJson),
  );
}
