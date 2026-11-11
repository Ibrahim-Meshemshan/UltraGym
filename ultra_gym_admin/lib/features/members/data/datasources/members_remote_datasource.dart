import '../../../../core/core.dart';
import '../../domain/models/member_models.dart';
import '../repo/members_repository.dart';

class MembersRemoteDataSource implements MembersRepository {
  MembersRemoteDataSource(this._api);

  final ApiClient _api;

  static const _path = '/club-admin/players';

  @override
  Future<ApiResult<Paged<MemberRow>>> list(ListQuery query, {required MembersTab tab, int? branchId}) => _api.getPaged(
    _path,
    fromJson: MemberRow.fromJson,
    query: query,
    extra: {
      if (tab == MembersTab.archive) 'archived': 'only',
      // فرع الشريط العلوي يغلب فلتر الجدول.
      MemberFilters.branchId: ?branchId,
    },
  );

  @override
  Future<ApiResult<MemberCounts>> counts({int? branchId}) async {
    final results = await Future.wait([
      _total(const {}, branchId),
      _total(const {'archived': 'only'}, branchId),
    ]);
    for (final r in results) {
      if (r case ApiFailure(:final failure)) return ApiFailure(failure);
    }
    final [members, archived] = [for (final r in results) (r as ApiSuccess<int>).data];
    return ApiSuccess(MemberCounts(members: members, archived: archived));
  }

  Future<ApiResult<int>> _total(Json extra, int? branchId) async {
    final r = await _api.getPaged(
      _path,
      fromJson: (j) => j,
      query: const ListQuery(perPage: 1),
      extra: {...extra, MemberFilters.branchId: ?branchId},
    );
    return switch (r) {
      ApiSuccess(:final data) => ApiSuccess(data.pagination.total),
      ApiFailure(:final failure) => ApiFailure(failure),
    };
  }

  @override
  Future<ApiResult<NewMember>> create(Json body, {required String idempotencyKey}) =>
      _api.post(_path, body: body, idempotencyKey: idempotencyKey, parse: Parse.object(NewMember.fromJson));

  @override
  Future<ApiResult<void>> archive(int id) => _api.delete('$_path/$id', parse: Parse.none);

  @override
  Future<ApiResult<void>> restore(int id) => _api.post('$_path/$id/restore', parse: Parse.none);
}
