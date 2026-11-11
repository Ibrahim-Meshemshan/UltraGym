import 'dart:async';

import 'package:ultra_gym_admin/core/networking/api_result.dart';
import 'package:ultra_gym_admin/core/networking/list_query.dart';
import 'package:ultra_gym_admin/core/networking/paged.dart';
import 'package:ultra_gym_admin/core/utils/json_x.dart';
import 'package:ultra_gym_admin/features/day_passes/data/repo/day_passes_repository.dart';
import 'package:ultra_gym_admin/features/day_passes/domain/models/day_pass_models.dart';

/// دخول يومي بشكل العقد (`docs/api/club-admin-api.yaml`، مثال الزائر).
Json dayPassJson({
  int id = 1,
  String kind = 'visitor',
  String name = 'خالد الأحمد',
  String status = 'active',
  double price = 5,
  bool withPayment = true,
}) => {
  'id': id,
  'kind': kind,
  'name': name,
  'phone': kind == 'visitor' ? '+963933556677' : '+963944100005',
  'gender': null,
  'player': kind == 'player' ? {'id': 7, 'name': name} : null,
  'branch': {'id': 1, 'name': 'الفرع الرئيسي - المزة'},
  'business_date': '2026-11-09',
  'checked_in_at': '2026-11-09T09:30:00Z',
  'price_usd': price,
  'paid_usd': withPayment ? price : 0,
  'is_free': price == 0,
  'status': status,
  'cancelled_at': status == 'cancelled' ? '2026-11-09T10:00:00Z' : null,
  'cancellation_reason': status == 'cancelled' ? 'سُجّل بالخطأ' : null,
  'attendance_record_id': kind == 'player' ? 50 : null,
  'is_offline': false,
  'notes': null,
  'created_by': {'id': 2, 'name': 'ريم العلي'},
  'created_at': '2026-11-09T09:30:00Z',
  'transactions': [
    if (withPayment && price > 0)
      {
        'id': 7,
        'receipt_number': 'B1-2026-000007',
        'type': 'day_pass',
        'type_label': 'دخول يومي',
        'direction': 'in',
        'currency': 'USD',
        'amount': price,
        'amount_usd': price,
        'is_reversed': status == 'cancelled',
        'business_date': '2026-11-09',
        'occurred_at': '2026-11-09T09:30:00Z',
      },
  ],
};

/// `GET day-passes/price` بشكل الرد الحقيقي (2026-11-09) مع سعر.
Json priceJson({double? price = 5, bool enabled = true, bool canChange = true, bool gender = false, int branch = 1}) =>
    {
      'enabled': enabled,
      'branch': {'id': branch, 'name': branch == 1 ? 'الفرع الرئيسي - المزة' : 'فرع المالكي'},
      'price_usd': price,
      'price_syp': price == null ? null : (price * 13000).round(),
      'source': price == null ? null : 'club',
      'exchange_rate': 13000,
      'can_change_price': canChange,
      'gender_required': gender,
    };

class FakeDayPassesRepository implements DayPassesRepository {
  ApiResult<Paged<DayPass>> listResult = ApiSuccess(
    Paged(
      items: [
        DayPass.fromJson(dayPassJson()),
        DayPass.fromJson(dayPassJson(id: 2, kind: 'player', name: 'رامي العمر')),
        DayPass.fromJson(dayPassJson(id: 3, name: 'مروان (يوم تجربة)', price: 0, withPayment: false)),
      ],
      pagination: const Pagination(total: 3, lastPage: 1, perPage: 15, currentPage: 1),
      summary: const {'count': 3, 'visitors': 2, 'players': 1, 'revenue_usd': 10},
      meta: const {
        'period': {'from': '2026-10-10', 'to': null, 'is_default': true},
      },
    ),
  );

  /// السعر لكل فرع (null = الفرع الافتراضي عند الخادم).
  ApiResult<DayPassPrice> Function(int? branchId) priceFor = (b) =>
      ApiSuccess(DayPassPrice.fromJson(priceJson(branch: b ?? 1, gender: b == 2)));
  ApiResult<DayPass> sellResult = ApiSuccess(DayPass.fromJson(dayPassJson(id: 9, name: 'زائر تجريبي')));
  ApiResult<DayPass> cancelResult = ApiSuccess(DayPass.fromJson(dayPassJson(status: 'cancelled')));

  /// يعلّق رد السعر حتى يُكمله الاختبار.
  Completer<void>? holdPrice;

  final queries = <({ListQuery query, int? branchId})>[];
  final priceCalls = <int?>[];
  final sales = <({Json body, String key})>[];
  final cancels = <({int id, String reason})>[];

  @override
  Future<ApiResult<Paged<DayPass>>> list(ListQuery query, {int? branchId}) async {
    queries.add((query: query, branchId: branchId));
    return listResult;
  }

  @override
  Future<ApiResult<DayPassPrice>> price({int? branchId}) async {
    priceCalls.add(branchId);
    final gate = holdPrice;
    if (gate != null) await gate.future;
    return priceFor(branchId);
  }

  @override
  Future<ApiResult<DayPass>> sell(Json body, {required String idempotencyKey}) async {
    sales.add((body: body, key: idempotencyKey));
    return sellResult;
  }

  @override
  Future<ApiResult<DayPass>> detail(int id) async => ApiSuccess(DayPass.fromJson(dayPassJson(id: id)));

  @override
  Future<ApiResult<DayPass>> cancel(int id, String reason, {required String idempotencyKey}) async {
    cancels.add((id: id, reason: reason));
    return cancelResult;
  }
}
