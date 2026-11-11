import 'package:ultra_gym_admin/core/error/failure.dart';
import 'package:ultra_gym_admin/core/networking/api_client.dart';
import 'package:ultra_gym_admin/core/networking/api_result.dart';
import 'package:ultra_gym_admin/core/networking/list_query.dart';
import 'package:ultra_gym_admin/core/networking/paged.dart';
import 'package:ultra_gym_admin/core/utils/json_x.dart';
import 'package:ultra_gym_admin/features/cash_sessions/data/repo/cash_sessions_repository.dart';
import 'package:ultra_gym_admin/features/cash_sessions/domain/models/cash_session_models.dart';

/// وردية بشكل العقد (`docs/api/club-admin-api.yaml` والرد الحقيقي 2026-11-10).
Json sessionJson({
  int id = 1,
  int branch = 1,
  String status = 'open',
  double? differenceUsd,
  double? differenceSyp,
  bool withBreakdown = false,
}) {
  final open = status == 'open';
  return {
    'id': id,
    'branch': {'id': branch, 'name': branch == 1 ? 'الفرع الرئيسي - المزة' : 'فرع المالكي'},
    'business_date': '2026-11-10',
    'status': status,
    'opening_usd': 50,
    'opening_syp': 500000,
    'expected_usd': open ? null : 436.5,
    'expected_syp': open ? null : 286000,
    'closing_usd': open ? null : 436.5 + (differenceUsd ?? 0),
    'closing_syp': open ? null : 286000 + (differenceSyp ?? 0),
    'difference_usd': open ? null : differenceUsd ?? 0,
    'difference_syp': open ? null : differenceSyp ?? 0,
    'opened_by': {'id': 1, 'name': 'سامر الحلبي'},
    'closed_by': open ? null : {'id': 2, 'name': 'ريم العلي'},
    'opened_at': '2026-11-10T06:00:00Z',
    'closed_at': open ? null : '2026-11-10T20:40:00Z',
    'notes': null,
    'totals': open || withBreakdown
        ? {
            'in_usd': 391.5,
            'out_usd': 5,
            'in_syp': 236000,
            'out_syp': 450000,
            'expected_usd': 436.5,
            'expected_syp': 286000,
          }
        : null,
    if (withBreakdown)
      'breakdown': [
        {
          'type': 'membership_payment',
          'type_label': 'دفعة اشتراك',
          'direction': 'in',
          'currency': 'USD',
          'count': 14,
          'total': 369.5,
          'total_usd': 369.5,
        },
        {
          'type': 'expense',
          'type_label': 'مصروف',
          'direction': 'out',
          'currency': 'SYP',
          'count': 1,
          'total': 450000,
          'total_usd': 34.62,
        },
      ],
  };
}

/// `GET cash-sessions/current`: الرئيسي مفتوح، والمالكي مغلق برصيد مقترح من آخر جرد.
Json boxJson(int branch, {bool open = true}) => {
  'branch': {'id': branch, 'name': branch == 1 ? 'الفرع الرئيسي - المزة' : 'فرع المالكي'},
  'session': open ? sessionJson(id: branch, branch: branch) : null,
  'suggested_opening': open ? {'usd': 0, 'syp': 0} : {'usd': 75, 'syp': 325000},
};

class FakeCashSessionsRepository implements CashSessionsRepository {
  ApiResult<CashBox> Function(int? branchId) currentFor = (b) =>
      ApiSuccess(CashBox.fromJson(boxJson(b ?? 1, open: (b ?? 1) == 1)));

  ApiResult<Paged<CashSession>> listResult = ApiSuccess(
    Paged(
      items: [
        CashSession.fromJson(sessionJson(id: 7, status: 'closed', differenceUsd: -5)),
        CashSession.fromJson(sessionJson(id: 6, branch: 2, status: 'closed', differenceSyp: 10000)),
        CashSession.fromJson(sessionJson(id: 5, status: 'closed')),
      ],
      pagination: const Pagination(total: 3, lastPage: 1, perPage: 15, currentPage: 1),
    ),
  );

  ApiResult<CashSession> Function(int id) detailFor = (id) =>
      ApiSuccess(CashSession.fromJson(sessionJson(id: id, branch: id == 2 ? 2 : 1, withBreakdown: true)));

  ApiResult<CashSession> openResult = ApiSuccess(CashSession.fromJson(sessionJson(id: 8, branch: 2)));
  ApiResult<CashSession> closeResult = ApiSuccess(
    CashSession.fromJson(sessionJson(status: 'closed', differenceUsd: -3, differenceSyp: 5000, withBreakdown: true)),
  );

  final currentCalls = <int?>[];
  final queries = <({ListQuery query, int? branchId, String? status})>[];
  final details = <int>[];
  final opens = <({Json body, String key})>[];
  final closes = <({int id, Json body, String key})>[];
  final reports = <int>[];

  @override
  Future<ApiResult<CashBox>> current({int? branchId}) async {
    currentCalls.add(branchId);
    return currentFor(branchId);
  }

  @override
  Future<ApiResult<Paged<CashSession>>> list(ListQuery query, {int? branchId, String? status}) async {
    queries.add((query: query, branchId: branchId, status: status));
    return listResult;
  }

  @override
  Future<ApiResult<CashSession>> detail(int id) async {
    details.add(id);
    return detailFor(id);
  }

  @override
  Future<ApiResult<CashSession>> open(Json body, {required String idempotencyKey}) async {
    opens.add((body: body, key: idempotencyKey));
    return openResult;
  }

  @override
  Future<ApiResult<CashSession>> close(int id, Json body, {required String idempotencyKey}) async {
    closes.add((id: id, body: body, key: idempotencyKey));
    return closeResult;
  }

  /// بالاختبار (VM) لا متصفح يفتح الملف: يرجع فشلاً تعرضه الواجهة كرسالة.
  @override
  Future<ApiResult<FileBlob>> report(int id) async {
    reports.add(id);
    return const ApiFailure(Failure(type: FailureType.server, message: 'تعذّر تجهيز التقرير'));
  }
}
