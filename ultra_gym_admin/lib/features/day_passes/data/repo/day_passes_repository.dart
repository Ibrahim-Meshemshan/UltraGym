import '../../../../core/core.dart';
import '../../domain/models/day_pass_models.dart';

/// الدخول اليومي: السجل، السعر بالفرع، البيع، التفاصيل، والإلغاء (للمالك).
abstract interface class DayPassesRepository {
  /// `meta.summary` = `DayPassSummary`.
  Future<ApiResult<Paged<DayPass>>> list(ListQuery query, {int? branchId});

  Future<ApiResult<DayPassPrice>> price({int? branchId});

  Future<ApiResult<DayPass>> sell(Json body, {required String idempotencyKey});

  Future<ApiResult<DayPass>> detail(int id);

  /// يعكس دفعاته بإيصالات عكسية بالوردية المفتوحة.
  Future<ApiResult<DayPass>> cancel(int id, String reason, {required String idempotencyKey});
}
