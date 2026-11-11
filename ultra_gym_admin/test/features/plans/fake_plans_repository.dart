import 'package:ultra_gym_admin/core/error/failure.dart';
import 'package:ultra_gym_admin/core/networking/api_result.dart';
import 'package:ultra_gym_admin/core/networking/list_query.dart';
import 'package:ultra_gym_admin/core/networking/paged.dart';
import 'package:ultra_gym_admin/core/utils/json_x.dart';
import 'package:ultra_gym_admin/features/plans/data/repo/plans_repository.dart';
import 'package:ultra_gym_admin/features/plans/domain/models/plans_models.dart';

/// خطة بشكل رد الخادم (`ClubPayloads::plan` + `memberships_sold`).
Json planJson({
  int id = 1,
  String name = 'شهري - حديد',
  String type = 'duration',
  int days = 30,
  int? sessions,
  num price = 27.5,
  String scope = 'all',
  List<Json> branches = const [],
  int freezes = 2,
  int freezeDays = 30,
  bool defaultFreeze = true,
  bool personal = false,
  String status = 'active',
  int sold = 12,
  String? description,
}) => {
  'id': id,
  'name': name,
  'description': description,
  'type': type,
  'duration_days': days,
  'sessions_count': sessions,
  'price_usd': price,
  'price_syp': price * 13000,
  'branch_scope': scope,
  'branches': branches,
  'max_freezes': freezes,
  'max_freeze_days': freezeDays,
  'uses_default_freeze_limits': defaultFreeze,
  'is_personal_training': personal,
  'status': status,
  'sort_order': 0,
  'created_at': '2026-11-10T09:30:00Z',
  'memberships_sold': sold,
};

List<Json> planRows() => [
  planJson(description: 'دخول يومي للصالة'),
  planJson(
    id: 2,
    name: '12 جلسة',
    type: 'sessions',
    days: 45,
    sessions: 12,
    price: 30,
    scope: 'selected',
    branches: const [
      {'id': 1, 'name': 'الفرع الرئيسي - المزة'},
    ],
    sold: 0,
  ),
  planJson(id: 3, name: 'تدريب خاص شهري', price: 100, freezes: 1, freezeDays: 7, defaultFreeze: false, personal: true),
  planJson(id: 4, name: 'سنوي قديم', days: 365, price: 280, freezes: 0, defaultFreeze: false, status: 'inactive'),
];

/// كوبون بشكل رد الخادم (`ClubPayloads::coupon`).
Json couponJson({
  int id = 1,
  String code = 'WINTER25',
  String type = 'percent',
  num value = 25,
  int? maxUses = 100,
  int used = 0,
  String? startsOn = '2026-12-01',
  String? endsOn = '2027-02-28',
  List<int> plans = const [1, 2],
  String status = 'active',
  String? note = 'عرض الشتاء',
}) => {
  'id': id,
  'code': code,
  'discount_type': type,
  'discount_value': value,
  'max_uses': maxUses,
  'used_count': used,
  'starts_on': startsOn,
  'ends_on': endsOn,
  'plan_ids': plans,
  'status': status,
  'note': note,
  'created_at': '2026-11-10T09:30:00Z',
};

List<Json> couponRows() => [
  couponJson(),
  couponJson(id: 2, code: 'FRIEND5', type: 'fixed', value: 5, maxUses: null, used: 64, startsOn: null, endsOn: null, plans: const []),
  couponJson(id: 3, code: 'PT10', type: 'fixed', value: 10, maxUses: 20, used: 3, plans: const [3], status: 'inactive'),
];

Paged<T> pageOf<T>(List<T> items) => Paged(
  items: items,
  pagination: Pagination(currentPage: 1, perPage: 15, total: items.length, lastPage: 1),
);

class FakePlansRepository implements PlansRepository {
  ApiResult<Paged<Plan>> plansResult = ApiSuccess(pageOf([for (final j in planRows()) Plan.fromJson(j)]));
  ApiResult<Paged<Plan>> archivedResult = ApiSuccess(
    pageOf([Plan.fromJson(planJson(id: 9, name: 'عرض الصيف', status: 'inactive', sold: 5))]),
  );
  ApiResult<Paged<Coupon>> couponsResult = ApiSuccess(pageOf([for (final j in couponRows()) Coupon.fromJson(j)]));
  ApiResult<Plan>? savePlanResult;
  ApiResult<Coupon>? saveCouponResult;
  ApiResult<void>? deleteCouponResult;

  final planQueries = <ListQuery>[];
  final couponQueries = <ListQuery>[];
  final savedPlans = <({Json body, int? id, String? key})>[];
  final savedCoupons = <({Json body, int? id, String? key})>[];
  final archived = <int>[], restored = <int>[], deletedCoupons = <int>[];

  @override
  Future<ApiResult<Paged<Plan>>> plans(ListQuery query) async {
    planQueries.add(query);
    return query.filter('archived') == 'only' ? archivedResult : plansResult;
  }

  @override
  Future<ApiResult<Plan>> savePlan(Json body, {int? id, String? idempotencyKey}) async {
    savedPlans.add((body: body, id: id, key: idempotencyKey));
    return savePlanResult ??
        ApiSuccess(Plan.fromJson(planJson(id: id ?? 10, name: '${body['name']}')), message: 'تم حفظ الخطة');
  }

  @override
  Future<ApiResult<void>> archivePlan(int id) async {
    archived.add(id);
    return const ApiSuccess(null, message: 'تمت أرشفة خطة الاشتراك.');
  }

  @override
  Future<ApiResult<Plan>> restorePlan(int id) async {
    restored.add(id);
    return ApiSuccess(Plan.fromJson(planJson(id: id, status: 'inactive')));
  }

  @override
  Future<ApiResult<Paged<Coupon>>> coupons(ListQuery query) async {
    couponQueries.add(query);
    return couponsResult;
  }

  @override
  Future<ApiResult<Coupon>> saveCoupon(Json body, {int? id, String? idempotencyKey}) async {
    savedCoupons.add((body: body, id: id, key: idempotencyKey));
    return saveCouponResult ?? ApiSuccess(Coupon.fromJson(couponJson(id: id ?? 10, code: '${body['code']}')));
  }

  @override
  Future<ApiResult<void>> deleteCoupon(int id) async {
    deletedCoupons.add(id);
    return deleteCouponResult ?? const ApiSuccess(null, message: 'تم حذف الكوبون');
  }
}

const couponUsedConflict = ApiFailure<void>(
  Failure(type: FailureType.conflict, code: 'CONFLICT', message: 'الكوبون مستخدم باشتراكات: أوقفه بدل حذفه'),
);
