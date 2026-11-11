import '../../../../core/core.dart';
import '../../domain/models/dashboard_models.dart';

/// الرئيسية: الأرقام المجمّعة، والاشتراكات التي تنتهي قريباً. `branchId` = null ← كل الفروع المسموحة.
abstract interface class DashboardRepository {
  Future<ApiResult<DashboardData>> summary({int? branchId});

  /// الأقرب انتهاءً أولاً، بحد `limit`.
  Future<ApiResult<List<ExpiringMembership>>> expiring({int? branchId, int days = 7, int limit = 5});
}
