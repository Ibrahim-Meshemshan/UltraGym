import '../../../../core/core.dart';
import '../../../members/domain/models/member_profile_models.dart';
import '../../domain/models/sale_models.dart';
import '../repo/sell_membership_repository.dart';

class SellMembershipRemoteDataSource implements SellMembershipRepository {
  SellMembershipRemoteDataSource(this._api);

  final ApiClient _api;

  static const _base = '/club-admin';

  /// خطط وموظفو النادي قليلون: صفحة واحدة بالحد الأقصى تكفي.
  static const _all = 100;

  @override
  Future<ApiResult<List<SalePlan>>> plans({int? branchId}) => _api.getList(
    '$_base/membership-plans',
    fromJson: SalePlan.fromJson,
    query: {'status': 'active', 'per_page': _all, 'sort_by': 'sort_order', 'sort_dir': 'asc', 'branch_id': ?branchId},
  );

  @override
  Future<ApiResult<List<SaleTrainer>>> trainers() => _api.getList(
    '$_base/staff-members',
    fromJson: SaleTrainer.fromJson,
    query: {'type': 'trainer', 'status': 'active', 'per_page': _all},
  );

  @override
  Future<ApiResult<SaleMember>> member(int id) =>
      _api.getObject('$_base/players/$id', fromJson: (j) => SaleMember.fromProfile(MemberProfile.fromJson(j)));

  @override
  Future<ApiResult<MembershipQuote>> quote(Json body) =>
      _api.post('$_base/memberships/quote', body: body, parse: Parse.object(MembershipQuote.fromJson));

  @override
  Future<ApiResult<SaleResult>> sell(Json body, {required String idempotencyKey}) => _api.post(
    '$_base/memberships',
    body: body,
    idempotencyKey: idempotencyKey,
    parse: Parse.object(SaleResult.fromJson),
  );
}
