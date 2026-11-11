import '../../../../core/core.dart';
import '../../domain/models/club_plan_models.dart';

/// باقة النادي: الميزات والحدود، واشتراك النادي بالمنصة.
abstract interface class ClubPlanRepository {
  Future<ApiResult<Entitlements>> entitlements();

  /// `null` = لا اشتراك حالي مسجّل (نادٍ تجريبي محلي مثلاً).
  Future<ApiResult<ClubSubscription?>> subscription();
}
