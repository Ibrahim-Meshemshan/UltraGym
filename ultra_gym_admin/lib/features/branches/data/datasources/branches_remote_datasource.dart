import '../../../../core/core.dart';
import '../../domain/models/branch_models.dart';
import '../repo/branches_repository.dart';

class BranchesRemoteDataSource implements BranchesRepository {
  BranchesRemoteDataSource(this._api);

  final ApiClient _api;
  static const _base = '/club-admin/branches';

  @override
  Future<ApiResult<List<Branch>>> list() =>
      _api.getList(_base, fromJson: Branch.fromJson, query: const {'per_page': 100});
}
