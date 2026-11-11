import '../../../../core/core.dart';
import '../../domain/models/cash_session_models.dart';
import '../repo/cash_sessions_repository.dart';

class CashSessionsRemoteDataSource implements CashSessionsRepository {
  CashSessionsRemoteDataSource(this._api);

  final ApiClient _api;

  static const _path = '/club-admin/cash-sessions';

  @override
  Future<ApiResult<CashBox>> current({int? branchId}) =>
      _api.getObject('$_path/current', fromJson: CashBox.fromJson, query: {'branch_id': ?branchId});

  @override
  Future<ApiResult<Paged<CashSession>>> list(ListQuery query, {int? branchId, String? status}) => _api.getPaged(
    _path,
    fromJson: CashSession.fromJson,
    query: query,
    extra: {CashSessionFilters.branchId: ?branchId, CashSessionFilters.status: ?status},
  );

  @override
  Future<ApiResult<CashSession>> detail(int id) => _api.getObject('$_path/$id', fromJson: CashSession.fromJson);

  @override
  Future<ApiResult<CashSession>> open(Json body, {required String idempotencyKey}) =>
      _api.post(_path, body: body, idempotencyKey: idempotencyKey, parse: Parse.object(CashSession.fromJson));

  @override
  Future<ApiResult<CashSession>> close(int id, Json body, {required String idempotencyKey}) => _api.post(
    '$_path/$id/close',
    body: body,
    idempotencyKey: idempotencyKey,
    parse: Parse.object(CashSession.fromJson),
  );

  @override
  Future<ApiResult<FileBlob>> report(int id) => _api.getBytes('$_path/$id/report');
}
