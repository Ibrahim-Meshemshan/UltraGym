import 'package:ultra_gym_admin/core/networking/api_result.dart';
import 'package:ultra_gym_admin/core/networking/list_query.dart';
import 'package:ultra_gym_admin/core/networking/paged.dart';
import 'package:ultra_gym_admin/core/utils/json_x.dart';
import 'package:ultra_gym_admin/features/memberships/data/repo/memberships_repository.dart';
import 'package:ultra_gym_admin/features/memberships/domain/models/memberships_models.dart';

/// صف حقيقي من `GET club-admin/memberships/debts` (الخادم التجريبي، 2026-11-09).
final Json ahmadDebtJson = {
  'id': 3,
  'player': {'id': 3, 'name': 'أحمد الخطيب'},
  'plan': {'id': 4, 'name': 'تدريب خاص شهري'},
  'type': 'duration',
  'branch': {'id': 1, 'name': 'الفرع الرئيسي - المزة'},
  'starts_on': '2026-10-25',
  'ends_on': '2026-11-23',
  'days_remaining': 15,
  'sessions_total': null,
  'sessions_remaining': null,
  'status': 'active',
  'status_label': 'فعّال',
  'frozen_until': null,
  'price_usd': 60,
  'net_usd': 60,
  'paid_usd': 40,
  'due_usd': 20,
  'due_syp': 260000,
  'trainer': {'id': 1},
};

/// صف حقيقي من `GET club-admin/memberships` (اشتراك جلسات لم يبدأ).
final Json nourJson = {
  'id': 13,
  'player': {'id': 8, 'name': 'نور الدين'},
  'plan': {'id': 3, 'name': '12 جلسة'},
  'type': 'sessions',
  'branch': {'id': 1, 'name': 'الفرع الرئيسي - المزة'},
  'starts_on': '2026-12-09',
  'ends_on': '2027-01-22',
  'days_remaining': 75,
  'sessions_total': 12,
  'sessions_remaining': 12,
  'status': 'upcoming',
  'status_label': 'لم يبدأ',
  'frozen_until': null,
  'net_usd': 18,
  'paid_usd': 18,
  'due_usd': 0,
  'trainer': null,
};

final ahmadDebt = MembershipRow.fromJson(ahmadDebtJson);
final nour = MembershipRow.fromJson(nourJson);

Paged<MembershipRow> rows(List<MembershipRow> items, {int total = 2, int last = 1}) => Paged(
  items: items,
  pagination: Pagination(
    currentPage: 1,
    perPage: 15,
    total: total,
    lastPage: last,
    from: items.isEmpty ? null : 1,
    to: items.isEmpty ? null : items.length,
  ),
);

const demoStats = MembershipStats(active: 8, frozen: 1, expiring: 3, debtUsd: 20, debtCount: 1);

const demoPlans = <PlanOption>[(value: 1, label: 'شهري - كل الفروع'), (value: 3, label: '12 جلسة')];

typedef MembershipsCall = ({MembershipsTab tab, int? branchId, Json params});

class FakeMembershipsRepository implements MembershipsRepository {
  ApiResult<Paged<MembershipRow>> allResult = ApiSuccess(rows([ahmadDebt, nour]));
  ApiResult<Paged<MembershipRow>> debtsResult = ApiSuccess(rows([ahmadDebt], total: 1));
  ApiResult<Paged<MembershipRow>> expiringResult = ApiSuccess(rows(const [], total: 0));
  ApiResult<MembershipStats> statsResult = const ApiSuccess(demoStats);
  ApiResult<List<PlanOption>> plansResult = const ApiSuccess(demoPlans);

  final calls = <MembershipsCall>[];
  final statsCalls = <int?>[];

  @override
  Future<ApiResult<Paged<MembershipRow>>> list(ListQuery query, {required MembershipsTab tab, int? branchId}) async {
    calls.add((tab: tab, branchId: branchId, params: query.toParams()));
    return switch (tab) {
      MembershipsTab.all => allResult,
      MembershipsTab.debts => debtsResult,
      MembershipsTab.expiring => expiringResult,
    };
  }

  @override
  Future<ApiResult<MembershipStats>> stats({int? branchId}) async {
    statsCalls.add(branchId);
    return statsResult;
  }

  @override
  Future<ApiResult<List<PlanOption>>> plans() async => plansResult;
}
