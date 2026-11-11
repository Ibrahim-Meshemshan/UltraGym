import 'package:ultra_gym_admin/core/networking/api_result.dart';
import 'package:ultra_gym_admin/core/utils/json_x.dart';
import 'package:ultra_gym_admin/features/club_plan/data/repo/club_plan_repository.dart';
import 'package:ultra_gym_admin/features/club_plan/domain/models/club_plan_models.dart';

/// رد حقيقي من الخادم التجريبي (2026-11-09): `GET tenant/entitlements`.
final entitlementsJson = <String, Object?>{
  'limits': {'players': null, 'staff': null, 'branches': 10, 'storage_mb': 1024},
  'features': {
    'player_app': true,
    'qr_attendance': true,
    'offline_reception': true,
    'advanced_finance': true,
    'advanced_reports': true,
    'reports_export': true,
    'custom_branding': false,
    'priority_support': false,
  },
};

/// نفس الرد مع ميزات مطفأة.
Entitlements entitlementsWithout(Set<String> off) {
  final j = Map<String, Object?>.of(entitlementsJson);
  j['features'] = {for (final e in asJson(j['features']).entries) e.key: e.value == true && !off.contains(e.key)};
  return Entitlements.fromJson(j);
}

/// `billing/subscription.current` بشكل العقد.
Json subscriptionJson(String status) => {
  'id': 4,
  'plan': {'id': 2, 'name': 'Pro'},
  'status': status,
  'is_trial': false,
  'is_current': true,
  'billing_cycle': 'monthly',
  'starts_at': '2026-10-01',
  'ends_at': '2026-11-04',
  'grace_ends_at': '2026-11-11',
};

class FakeClubPlanRepository implements ClubPlanRepository {
  ApiResult<Entitlements> entitlementsResult = ApiSuccess(Entitlements.fromJson(entitlementsJson));
  ApiResult<ClubSubscription?> subscriptionResult = const ApiSuccess(null);
  int entitlementsCalls = 0, subscriptionCalls = 0;

  @override
  Future<ApiResult<Entitlements>> entitlements() async {
    entitlementsCalls++;
    return entitlementsResult;
  }

  @override
  Future<ApiResult<ClubSubscription?>> subscription() async {
    subscriptionCalls++;
    return subscriptionResult;
  }
}
