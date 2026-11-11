import '../../../../core/core.dart';
import '../../domain/models/dashboard_models.dart';
import '../repo/dashboard_repository.dart';

class DashboardRemoteDataSource implements DashboardRepository {
  DashboardRemoteDataSource(this._api);

  final ApiClient _api;

  @override
  Future<ApiResult<DashboardData>> summary({int? branchId}) =>
      _api.getObject('/club-admin/dashboard', fromJson: DashboardData.fromJson, query: {'branch_id': ?branchId});

  @override
  Future<ApiResult<List<ExpiringMembership>>> expiring({int? branchId, int days = 7, int limit = 5}) async {
    final r = await _api.getPaged(
      '/club-admin/memberships',
      fromJson: ExpiringMembership.fromJson,
      query: ListQuery(perPage: limit, sortBy: 'ends_on', sortDir: SortDir.asc),
      extra: {'expiring_within_days': days, 'branch_id': ?branchId},
    );
    return switch (r) {
      ApiSuccess(:final data, :final message, :final meta) => ApiSuccess(data.items, message: message, meta: meta),
      ApiFailure(:final failure) => ApiFailure(failure),
    };
  }
}
