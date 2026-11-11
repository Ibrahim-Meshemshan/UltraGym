import '../../../../core/core.dart';
import '../../../transactions/domain/models/transaction_models.dart';
import '../../domain/models/finance_settings_models.dart';
import '../repo/finance_settings_repository.dart';

class FinanceSettingsRemoteDataSource implements FinanceSettingsRepository {
  FinanceSettingsRemoteDataSource(this._api);

  final ApiClient _api;

  static const _rate = '/club-admin/finance/exchange-rate', _categories = '/club-admin/finance/categories';

  @override
  Future<ApiResult<Paged<ExchangeRateEntry>>> rates(ListQuery query) =>
      _api.getPaged(_rate, fromJson: ExchangeRateEntry.fromJson, query: query);

  @override
  Future<ApiResult<void>> setRate(Json body, {required String idempotencyKey}) =>
      _api.post(_rate, body: body, idempotencyKey: idempotencyKey, parse: Parse.none);

  @override
  Future<ApiResult<List<FinanceCategory>>> categories() =>
      _api.getList(_categories, query: const {'per_page': 100}, fromJson: FinanceCategory.fromJson);

  @override
  Future<ApiResult<FinanceCategory>> addCategory(Json body, {required String idempotencyKey}) => _api.post(
    _categories,
    body: body,
    idempotencyKey: idempotencyKey,
    parse: Parse.object(FinanceCategory.fromJson),
  );

  @override
  Future<ApiResult<FinanceCategory>> updateCategory(int id, Json body) =>
      _api.patch('$_categories/$id', body: body, parse: Parse.object(FinanceCategory.fromJson));

  @override
  Future<ApiResult<void>> deleteCategory(int id) => _api.delete('$_categories/$id', parse: Parse.none);
}
