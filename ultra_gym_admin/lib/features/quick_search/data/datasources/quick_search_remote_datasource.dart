import '../../../../core/core.dart';
import '../../domain/models/quick_search_models.dart';
import '../repo/quick_search_repository.dart';

class QuickSearchRemoteDataSource implements QuickSearchRepository {
  QuickSearchRemoteDataSource(this._api);

  final ApiClient _api;

  @override
  Future<ApiResult<List<LookupPlayer>>> lookup(String q, {int? branchId}) => _api.getList(
    '/club-admin/players/lookup',
    fromJson: LookupPlayer.fromJson,
    query: {'q': q, 'branch_id': ?branchId},
  );
}
