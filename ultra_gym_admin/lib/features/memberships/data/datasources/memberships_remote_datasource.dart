import '../../../../core/core.dart';
import '../../domain/models/memberships_models.dart';
import '../repo/memberships_repository.dart';

class MembershipsRemoteDataSource implements MembershipsRepository {
  MembershipsRemoteDataSource(this._api);

  final ApiClient _api;

  static const _path = '/club-admin/memberships';

  @override
  Future<ApiResult<Paged<MembershipRow>>> list(ListQuery query, {required MembershipsTab tab, int? branchId}) {
    final branch = {MembershipFilters.branchId: ?branchId};
    return switch (tab) {
      MembershipsTab.all => _api.getPaged(_path, fromJson: MembershipRow.fromJson, query: query, extra: branch),
      MembershipsTab.debts => _api.getPaged(
        '$_path/debts',
        fromJson: MembershipRow.fromJson,
        query: query,
        extra: {...branch, 'sort_by': 'due', 'sort_dir': 'desc'},
      ),
      MembershipsTab.expiring => _api.getPaged(
        _path,
        fromJson: MembershipRow.fromJson,
        query: query,
        extra: {
          ...branch,
          'expiring_within_days': MembershipFilters.expiringDays,
          'sort_by': 'ends_on',
          'sort_dir': 'asc',
        },
      ),
    };
  }

  @override
  Future<ApiResult<MembershipStats>> stats({int? branchId}) async {
    final branch = {MembershipFilters.branchId: ?branchId};
    final counts = Future.wait([
      _total({...branch, MembershipFilters.status: 'active'}),
      _total({...branch, MembershipFilters.status: 'frozen'}),
      _total({...branch, 'expiring_within_days': MembershipFilters.expiringDays}),
    ]);
    final debts = _api.getPaged('$_path/debts', fromJson: (j) => j, query: const ListQuery(perPage: 1), extra: branch);
    final [active, frozen, expiring] = await counts;
    final d = await debts;
    for (final r in [active, frozen, expiring]) {
      if (r case ApiFailure(:final failure)) return ApiFailure(failure);
    }
    return switch (d) {
      ApiFailure(:final failure) => ApiFailure(failure),
      ApiSuccess(:final data) => ApiSuccess(
        MembershipStats(
          active: (active as ApiSuccess<int>).data,
          frozen: (frozen as ApiSuccess<int>).data,
          expiring: (expiring as ApiSuccess<int>).data,
          debtUsd: data.summary.dbl('total_due_usd'),
          debtCount: data.summary.intv('memberships_count'),
        ),
      ),
    };
  }

  Future<ApiResult<int>> _total(Json extra) async {
    final r = await _api.getPaged(_path, fromJson: (j) => j, query: const ListQuery(perPage: 1), extra: extra);
    return switch (r) {
      ApiSuccess(:final data) => ApiSuccess(data.pagination.total),
      ApiFailure(:final failure) => ApiFailure(failure),
    };
  }

  @override
  Future<ApiResult<List<PlanOption>>> plans() => _api.getList(
    '/club-admin/membership-plans',
    query: const {'per_page': 100},
    fromJson: (j) => (value: j.intv('id'), label: j.str('name')),
  );
}
