import '../../../../core/core.dart';
import '../../domain/models/plans_models.dart';
import '../repo/plans_repository.dart';

class PlansRemoteDataSource implements PlansRepository {
  PlansRemoteDataSource(this._api);

  final ApiClient _api;

  static const _plans = '/club-admin/membership-plans', _coupons = '/club-admin/coupons';

  @override
  Future<ApiResult<Paged<Plan>>> plans(ListQuery query) => _api.getPaged(_plans, fromJson: Plan.fromJson, query: query);

  @override
  Future<ApiResult<Plan>> savePlan(Json body, {int? id, String? idempotencyKey}) => id == null
      ? _api.post(_plans, body: body, idempotencyKey: idempotencyKey, parse: Parse.object(Plan.fromJson))
      : _api.patch('$_plans/$id', body: body, parse: Parse.object(Plan.fromJson));

  @override
  Future<ApiResult<void>> archivePlan(int id) => _api.delete('$_plans/$id', parse: Parse.none);

  @override
  Future<ApiResult<Plan>> restorePlan(int id) =>
      _api.post('$_plans/$id/restore', parse: Parse.object(Plan.fromJson));

  @override
  Future<ApiResult<Paged<Coupon>>> coupons(ListQuery query) =>
      _api.getPaged(_coupons, fromJson: Coupon.fromJson, query: query);

  @override
  Future<ApiResult<Coupon>> saveCoupon(Json body, {int? id, String? idempotencyKey}) => id == null
      ? _api.post(_coupons, body: body, idempotencyKey: idempotencyKey, parse: Parse.object(Coupon.fromJson))
      : _api.patch('$_coupons/$id', body: body, parse: Parse.object(Coupon.fromJson));

  @override
  Future<ApiResult<void>> deleteCoupon(int id) => _api.delete('$_coupons/$id', parse: Parse.none);
}
