import '../../../../core/core.dart';
import '../../domain/models/transaction_models.dart';
import '../repo/transactions_repository.dart';

class TransactionsRemoteDataSource implements TransactionsRepository {
  TransactionsRemoteDataSource(this._api);

  final ApiClient _api;

  static const _path = '/club-admin/transactions';

  @override
  Future<ApiResult<Paged<LedgerEntry>>> list(ListQuery query, {int? branchId}) => _api.getPaged(
    _path,
    fromJson: LedgerEntry.fromJson,
    query: query,
    extra: {TransactionFilters.branchId: ?branchId},
  );

  @override
  Future<ApiResult<LedgerEntry>> detail(int id) => _api.getObject('$_path/$id', fromJson: LedgerEntry.fromJson);

  @override
  Future<ApiResult<List<FinanceCategory>>> categories() => _api.getList(
    '/club-admin/finance/categories',
    query: const {'status': 'active', 'per_page': 100},
    fromJson: FinanceCategory.fromJson,
  );

  @override
  Future<ApiResult<LedgerEntry>> record(Json body, {required String idempotencyKey}) =>
      _api.post(_path, body: body, idempotencyKey: idempotencyKey, parse: Parse.object(LedgerEntry.fromJson));

  @override
  Future<ApiResult<LedgerReversal>> reverse(int id, String reason, {required String idempotencyKey}) => _api.post(
    '$_path/$id/reverse',
    body: {'reason': reason},
    idempotencyKey: idempotencyKey,
    parse: Parse.object(LedgerReversal.fromJson),
  );

  @override
  Future<ApiResult<FileBlob>> receipt(int id) => _api.getBytes('$_path/$id/receipt');
}
