import '../../../../core/core.dart';
import '../../domain/models/club_plan_models.dart';
import '../repo/club_plan_repository.dart';

class ClubPlanRemoteDataSource implements ClubPlanRepository {
  ClubPlanRemoteDataSource(this._api);

  final ApiClient _api;

  @override
  Future<ApiResult<Entitlements>> entitlements() =>
      _api.getObject('/tenant/entitlements', fromJson: Entitlements.fromJson);

  @override
  Future<ApiResult<ClubSubscription?>> subscription() => _api.get(
    '/club-admin/billing/subscription',
    parse: (raw) => switch (asJson(raw).objOrNull('current')) {
      final c? => ClubSubscription.fromJson(c),
      null => null,
    },
  );
}
