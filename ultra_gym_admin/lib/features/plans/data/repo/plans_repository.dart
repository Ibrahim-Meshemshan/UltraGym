import '../../../../core/core.dart';
import '../../domain/models/plans_models.dart';

/// الخطط والكوبونات (`/club-admin/membership-plans`، `/club-admin/coupons`). الخطط تُقرأ للمالك والاستقبال
/// (بفروعه)، وتعديلها والكوبونات كلها للمالك فقط.
abstract interface class PlansRepository {
  /// فلاتر `status`، `type`، `archived` (`only` = المؤرشفة)، `search`؛ الترتيب الافتراضي `sort_order`.
  Future<ApiResult<Paged<Plan>>> plans(ListQuery query);

  /// إضافة (`id` null، بمفتاح منع التكرار) أو تعديل (`PATCH`).
  Future<ApiResult<Plan>> savePlan(Json body, {int? id, String? idempotencyKey});

  /// أرشفة (`DELETE`، تصير موقوفة؛ المباعة لا تتأثر) واسترجاع (موقوفة حتى تُفعَّل).
  Future<ApiResult<void>> archivePlan(int id);
  Future<ApiResult<Plan>> restorePlan(int id);

  /// فلاتر `status`، `search` (بالكود).
  Future<ApiResult<Paged<Coupon>>> coupons(ListQuery query);

  Future<ApiResult<Coupon>> saveCoupon(Json body, {int? id, String? idempotencyKey});

  /// المستعمل يرفضه الخادم بـ `CONFLICT` ("أوقفه بدل حذفه").
  Future<ApiResult<void>> deleteCoupon(int id);
}
