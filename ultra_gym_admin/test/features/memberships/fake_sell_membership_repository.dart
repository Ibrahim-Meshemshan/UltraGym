import 'dart:async';

import 'package:ultra_gym_admin/core/error/failure.dart';
import 'package:ultra_gym_admin/core/networking/api_result.dart';
import 'package:ultra_gym_admin/core/utils/json_x.dart';
import 'package:ultra_gym_admin/features/memberships/data/repo/sell_membership_repository.dart';
import 'package:ultra_gym_admin/features/memberships/domain/models/sale_models.dart';

/// ردود حقيقية من الخادم التجريبي (2026-11-09): `GET membership-plans?status=active`.
final plansJson = <Json>[
  {
    'id': 1,
    'name': 'شهري - كل الفروع',
    'type': 'duration',
    'duration_days': 30,
    'sessions_count': null,
    'price_usd': 25,
    'price_syp': 325000,
    'branch_scope': 'all',
    'branches': <Json>[],
    'is_personal_training': false,
    'status': 'active',
  },
  {
    'id': 3,
    'name': '12 جلسة',
    'type': 'sessions',
    'duration_days': 45,
    'sessions_count': 12,
    'price_usd': 18,
    'price_syp': 234000,
    'branch_scope': 'all',
    'branches': <Json>[],
    'is_personal_training': false,
  },
  {
    'id': 4,
    'name': 'تدريب خاص شهري',
    'type': 'duration',
    'duration_days': 30,
    'price_usd': 60,
    'price_syp': 780000,
    'branch_scope': 'all',
    'branches': <Json>[],
    'is_personal_training': true,
  },
  {
    'id': 5,
    'name': 'شهري - فرع المالكي',
    'type': 'duration',
    'duration_days': 30,
    'price_usd': 20,
    'price_syp': 260000,
    'branch_scope': 'selected',
    'branches': [
      {'id': 2, 'name': 'فرع المالكي'},
    ],
    'is_personal_training': false,
  },
];

/// `GET staff-members?type=trainer&status=active`.
final trainersJson = <Json>[
  {
    'id': 2,
    'name': 'كابتن لينا',
    'branch': {'id': 2, 'name': 'فرع المالكي'},
  },
  {
    'id': 1,
    'name': 'كابتن مازن',
    'branch': {'id': 1, 'name': 'الفرع الرئيسي - المزة'},
  },
];

/// `POST memberships/quote {plan_id: 1, starts_on: 2026-11-12}` (+ الكوبون WELCOME10 حين يُرسل).
Json saleQuoteJson({String? coupon, double? discount, String startsOn = '2026-11-12', String endsOn = '2026-12-11'}) {
  final off = coupon != null ? 2.5 : (discount ?? 0);
  return {
    'starts_on': startsOn,
    'ends_on': endsOn,
    'price_usd': 25,
    'discount_usd': off,
    'net_usd': 25 - off,
    'net_syp': (25 - off) * 13000,
    'exchange_rate': 13000,
    'coupon': coupon == null ? null : {'id': 1, 'code': coupon},
    'allow_partial_payment': true,
  };
}

/// رد `POST memberships` (شكل العقد): الاشتراك + حركة لكل دفعة.
final saleJson = <String, Object?>{
  'membership': {'id': 21, 'due_usd': 5, 'net_usd': 25, 'paid_usd': 20},
  'transactions': [
    {'id': 31, 'receipt_number': 'B1-2026-000031', 'currency': 'USD', 'amount': 15},
    {'id': 32, 'receipt_number': 'B1-2026-000032', 'currency': 'SYP', 'amount': 65000},
  ],
};

const couponInvalid = Failure(type: FailureType.validation, code: 'COUPON_INVALID', message: 'الكوبون غير موجود');

class FakeSellMembershipRepository implements SellMembershipRepository {
  ApiResult<List<SalePlan>> plansResult = ApiSuccess([for (final p in plansJson) SalePlan.fromJson(p)]);
  ApiResult<List<SaleTrainer>> trainersResult = ApiSuccess([for (final t in trainersJson) SaleTrainer.fromJson(t)]);
  ApiResult<SaleMember> memberResult = const ApiSuccess(
    SaleMember(id: 15, name: 'عضو تجريبي', memberCode: 'DMO-512345', phone: '+963944100015'),
  );

  /// null = تسعير من الجسم المرسل (`saleQuoteJson`).
  ApiResult<MembershipQuote>? quoteResult;
  ApiResult<SaleResult> sellResult = ApiSuccess(
    SaleResult.fromJson(saleJson),
    message: 'تم تسجيل الاشتراك، والمتبقي \$5.00 دين على اللاعب',
  );

  /// يعلّق ردود التسعير حتى يكملها الاختبار (للرد القديم).
  Completer<void>? holdQuote;

  final planCalls = <int?>[];
  final memberCalls = <int>[];
  var trainerCalls = 0;
  final quotes = <Json>[];
  final sales = <({Json body, String key})>[];

  @override
  Future<ApiResult<List<SalePlan>>> plans({int? branchId}) async {
    planCalls.add(branchId);
    return plansResult;
  }

  @override
  Future<ApiResult<List<SaleTrainer>>> trainers() async {
    trainerCalls++;
    return trainersResult;
  }

  @override
  Future<ApiResult<SaleMember>> member(int id) async {
    memberCalls.add(id);
    return memberResult;
  }

  @override
  Future<ApiResult<MembershipQuote>> quote(Json body) async {
    quotes.add(body);
    final gate = holdQuote;
    if (gate != null) await gate.future;
    final coupon = body['coupon_code'] as String?;
    if (coupon != null && coupon != 'WELCOME10') return const ApiFailure(couponInvalid);
    return quoteResult ??
        ApiSuccess(
          MembershipQuote.fromJson(saleQuoteJson(coupon: coupon, discount: (body['discount_usd'] as num?)?.toDouble())),
        );
  }

  @override
  Future<ApiResult<SaleResult>> sell(Json body, {required String idempotencyKey}) async {
    sales.add((body: body, key: idempotencyKey));
    return sellResult;
  }
}
