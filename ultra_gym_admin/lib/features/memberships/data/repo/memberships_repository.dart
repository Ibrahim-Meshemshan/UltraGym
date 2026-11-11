import '../../../../core/core.dart';
import '../../domain/models/memberships_models.dart';

abstract interface class MembershipsRepository {
  /// تبويب واحد بفرع الشريط العلوي: `GET memberships` بالفلاتر، أو `/debts`، أو `expiring_within_days=7`.
  Future<ApiResult<Paged<MembershipRow>>> list(ListQuery query, {required MembershipsTab tab, int? branchId});

  /// أرقام الرأس: ثلاثة طلبات بصف واحد + ملخص الديون، بالتوازي.
  Future<ApiResult<MembershipStats>> stats({int? branchId});

  /// خطط الاشتراك لقائمة الفلتر (`GET membership-plans`).
  Future<ApiResult<List<PlanOption>>> plans();
}
