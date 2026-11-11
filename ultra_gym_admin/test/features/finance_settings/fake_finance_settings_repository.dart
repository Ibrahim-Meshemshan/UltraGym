import 'package:ultra_gym_admin/core/error/failure.dart';
import 'package:ultra_gym_admin/core/networking/api_result.dart';
import 'package:ultra_gym_admin/core/networking/list_query.dart';
import 'package:ultra_gym_admin/core/networking/paged.dart';
import 'package:ultra_gym_admin/core/utils/json_x.dart';
import 'package:ultra_gym_admin/features/finance_settings/data/repo/finance_settings_repository.dart';
import 'package:ultra_gym_admin/features/finance_settings/domain/models/finance_settings_models.dart';
import 'package:ultra_gym_admin/features/transactions/domain/models/transaction_models.dart';

/// سطر سجل بشكل رد الخادم (`FinanceSetupController::exchangeRates`).
Json rateJson(int id, num rate, {String? note, String at = '2026-09-27T09:00:00Z'}) => {
  'id': id,
  'syp_per_usd': rate,
  'note': note,
  'created_by': {'id': 1, 'name': 'سامر الحلبي'},
  'created_at': at,
};

/// الأحدث أولاً: 13000 (ارتفع 500)، 12500 (انخفض 300)، 12800 (أقدم سطر بالصفحة).
List<Json> rateRows() => [
  rateJson(3, 13000, note: 'سعر السوق'),
  rateJson(2, 12500, at: '2026-09-20T09:00:00Z'),
  rateJson(1, 12800, note: 'أول سعر', at: '2026-09-01T09:00:00Z'),
];

const rateMeta = {
  'current': {'syp_per_usd': 13000, 'updated_at': '2026-09-27T09:00:00Z'},
};

/// التصنيفات بعدد حركاتها (`transactions_count`)، ومتوقف واحد بلا حركات.
const settingsCategoriesJson = [
  {'id': 2, 'kind': 'expense', 'name': 'إيجار', 'status': 'active', 'transactions_count': 2},
  {'id': 3, 'kind': 'expense', 'name': 'صيانة أجهزة', 'status': 'active', 'transactions_count': 3},
  {'id': 5, 'kind': 'expense', 'name': 'ضيافة', 'status': 'inactive', 'transactions_count': 0},
  {'id': 4, 'kind': 'income', 'name': 'بيع مكملات', 'status': 'active', 'transactions_count': 1},
];

Paged<ExchangeRateEntry> ratesPage({List<Json>? rows, Json meta = rateMeta, int page = 1}) => Paged(
  items: [for (final j in rows ?? rateRows()) ExchangeRateEntry.fromJson(j)],
  pagination: Pagination(currentPage: page, perPage: 10, total: 3, lastPage: 1),
  meta: meta,
);

class FakeFinanceSettingsRepository implements FinanceSettingsRepository {
  ApiResult<Paged<ExchangeRateEntry>> ratesResult = ApiSuccess(ratesPage());
  ApiResult<List<FinanceCategory>> categoriesResult = ApiSuccess([
    for (final j in settingsCategoriesJson) FinanceCategory.fromJson(j),
  ]);
  ApiResult<void>? setRateResult, deleteResult;
  ApiResult<FinanceCategory>? addResult, updateResult;

  final rateQueries = <ListQuery>[];
  final rateBodies = <({Json body, String key})>[];
  final added = <({Json body, String key})>[];
  final updates = <({int id, Json body})>[];
  final deleted = <int>[];
  int categoryCalls = 0;

  @override
  Future<ApiResult<Paged<ExchangeRateEntry>>> rates(ListQuery query) async {
    rateQueries.add(query);
    return ratesResult;
  }

  @override
  Future<ApiResult<void>> setRate(Json body, {required String idempotencyKey}) async {
    rateBodies.add((body: body, key: idempotencyKey));
    return setRateResult ?? const ApiSuccess(null, message: 'تم تحديث سعر الصرف');
  }

  @override
  Future<ApiResult<List<FinanceCategory>>> categories() async {
    categoryCalls++;
    return categoriesResult;
  }

  @override
  Future<ApiResult<FinanceCategory>> addCategory(Json body, {required String idempotencyKey}) async {
    added.add((body: body, key: idempotencyKey));
    return addResult ??
        ApiSuccess(
          FinanceCategory.fromJson({'id': 9, 'kind': body['kind'], 'name': body['name'], 'status': 'active'}),
          message: 'تمت إضافة التصنيف',
        );
  }

  @override
  Future<ApiResult<FinanceCategory>> updateCategory(int id, Json body) async {
    updates.add((id: id, body: body));
    return updateResult ??
        ApiSuccess(
          FinanceCategory.fromJson({'id': id, 'kind': 'expense', 'name': body['name'] ?? 'x', 'status': 'active'}),
          message: 'تم تحديث التصنيف',
        );
  }

  @override
  Future<ApiResult<void>> deleteCategory(int id) async {
    deleted.add(id);
    return deleteResult ?? const ApiSuccess(null, message: 'تم حذف التصنيف');
  }
}

const usedCategoryConflict = ApiFailure<void>(
  Failure(type: FailureType.conflict, code: 'CONFLICT', message: 'التصنيف مستخدم بحركات مالية: أوقفه بدل حذفه'),
);
