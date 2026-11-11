import '../../../../core/core.dart';
import '../../domain/models/sale_models.dart';

/// بيع اشتراك: الخطط والمدربون والعضو المختار، ثم التسعير والبيع.
abstract interface class SellMembershipRepository {
  /// الخطط الفعّالة (`branchId` = الخطط التي تشمل فرع البيع؛ null = كلها).
  Future<ApiResult<List<SalePlan>>> plans({int? branchId});

  /// المدربون الفعّالون لخطة التدريب الخاص.
  Future<ApiResult<List<SaleTrainer>>> trainers();

  /// العضو المفتوح من رابط (`?player_id=`).
  Future<ApiResult<SaleMember>> member(int id);

  /// `POST memberships/quote {plan_id, starts_on?, coupon_code?, discount_usd?}`.
  Future<ApiResult<MembershipQuote>> quote(Json body);

  /// `POST memberships` (+ `Idempotency-Key`).
  Future<ApiResult<SaleResult>> sell(Json body, {required String idempotencyKey});
}
