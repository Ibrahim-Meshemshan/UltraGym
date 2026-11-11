import 'package:ultra_gym_admin/core/error/failure.dart';
import 'package:ultra_gym_admin/core/networking/api_result.dart';
import 'package:ultra_gym_admin/core/networking/api_client.dart';
import 'package:ultra_gym_admin/core/networking/list_query.dart';
import 'package:ultra_gym_admin/core/networking/paged.dart';
import 'package:ultra_gym_admin/core/utils/json_x.dart';
import 'package:ultra_gym_admin/features/transactions/data/repo/transactions_repository.dart';
import 'package:ultra_gym_admin/features/transactions/domain/models/transaction_models.dart';

/// حركة بشكل رد الخادم الحقيقي (`ClubPayloads::transaction`).
Json txJson({
  int id = 15,
  String type = 'expense',
  String typeLabel = 'مصروف',
  String direction = 'out',
  String currency = 'SYP',
  num amount = 450000,
  num amountUsd = 34.62,
  int branch = 1,
  Json? category = const {'id': 1, 'name': 'كهرباء ومولدة'},
  Json? player,
  int? membershipId,
  int? dayPassId,
  int? reversalOfId,
  bool reversed = false,
  String description = 'فاتورة المولدة',
}) => {
  'id': id,
  'receipt_number': 'B$branch-2026-${id.toString().padLeft(6, '0')}',
  'type': type,
  'type_label': typeLabel,
  'direction': direction,
  'currency': currency,
  'amount': amount,
  'exchange_rate': 13000,
  'amount_usd': amountUsd,
  'branch': {'id': branch, 'name': branch == 1 ? 'الفرع الرئيسي - المزة' : 'فرع المالكي'},
  'cash_session_id': branch == 1 ? 1 : 2,
  'category': category,
  'membership_id': membershipId,
  'day_pass_id': dayPassId,
  'player': player,
  'staff_member': null,
  'description': description,
  'is_reversed': reversed,
  'reversed_at': reversed ? '2026-11-09T19:34:39Z' : null,
  'reversal_of_id': reversalOfId,
  'business_date': '2026-11-09',
  'occurred_at': '2026-11-09T16:00:00Z',
  'created_by': {'id': 1, 'name': 'سامر الحلبي'},
};

/// صفحة الدفتر كما بالخادم: دفعة اشتراك، مصروف، إيراد، حركة معكوسة وعكسها.
List<Json> ledgerRows() => [
  txJson(
    id: 29,
    type: 'membership_payment',
    typeLabel: 'دفعة اشتراك',
    direction: 'in',
    currency: 'USD',
    amount: 30,
    amountUsd: 30,
    category: null,
    player: {'id': 6, 'name': 'خالد يوسف'},
    membershipId: 17,
    description: 'دفعة اشتراك 3 أشهر',
  ),
  txJson(),
  txJson(
    id: 16,
    type: 'income',
    typeLabel: 'إيراد',
    direction: 'in',
    currency: 'USD',
    amount: 15,
    amountUsd: 15,
    category: {'id': 4, 'name': 'بيع مكملات'},
    description: 'علبة بروتين',
  ),
  txJson(
    id: 25,
    type: 'reversal',
    typeLabel: 'عكس حركة',
    direction: 'out',
    currency: 'USD',
    amount: 5,
    amountUsd: 5,
    category: null,
    dayPassId: 1,
    reversalOfId: 24,
    description: 'عكس الإيصال B1-2026-000024: إلغاء دخول يومي',
  ),
  txJson(
    id: 24,
    type: 'day_pass',
    typeLabel: 'دخول يومي',
    direction: 'in',
    currency: 'USD',
    amount: 5,
    amountUsd: 5,
    category: null,
    dayPassId: 1,
    reversed: true,
    description: 'دخول يومي: زائر تجريبي',
  ),
];

const ledgerMeta = {
  'period': {'from': '2026-10-11', 'to': null, 'is_default': true},
  'totals': {'in_usd': 481, 'out_usd': 39.62, 'net_usd': 441.38},
};

const categoriesJson = [
  {'id': 2, 'kind': 'expense', 'name': 'إيجار', 'status': 'active'},
  {'id': 3, 'kind': 'expense', 'name': 'صيانة أجهزة', 'status': 'active'},
  {'id': 1, 'kind': 'expense', 'name': 'كهرباء ومولدة', 'status': 'active'},
  {'id': 4, 'kind': 'income', 'name': 'بيع مكملات', 'status': 'active'},
];

class FakeTransactionsRepository implements TransactionsRepository {
  ApiResult<Paged<LedgerEntry>> listResult = ApiSuccess(
    Paged(
      items: [for (final j in ledgerRows()) LedgerEntry.fromJson(j)],
      pagination: const Pagination(currentPage: 1, perPage: 15, total: 27, lastPage: 2),
      meta: ledgerMeta,
    ),
  );
  ApiResult<List<FinanceCategory>> categoriesResult = ApiSuccess([
    for (final j in categoriesJson) FinanceCategory.fromJson(j),
  ]);
  ApiResult<LedgerEntry> Function(int id) detailFor = (id) => ApiSuccess(
    LedgerEntry.fromJson({
      ...ledgerRows().firstWhere((j) => j['id'] == id, orElse: () => txJson(id: id)),
      'reversed_by_transaction': id == 24 ? {'id': 25, 'receipt_number': 'B1-2026-000025'} : null,
      'amount_syp_equivalent': 390000,
    }),
  );
  ApiResult<LedgerEntry>? recordResult;
  ApiResult<LedgerReversal>? reverseResult;

  final queries = <({ListQuery query, int? branchId})>[];
  final details = <int>[];
  final records = <({Json body, String key})>[];
  final reversals = <({int id, String reason, String key})>[];
  final receipts = <int>[];
  int categoryCalls = 0;

  @override
  Future<ApiResult<Paged<LedgerEntry>>> list(ListQuery query, {int? branchId}) async {
    queries.add((query: query, branchId: branchId));
    return listResult;
  }

  @override
  Future<ApiResult<LedgerEntry>> detail(int id) async {
    details.add(id);
    return detailFor(id);
  }

  @override
  Future<ApiResult<List<FinanceCategory>>> categories() async {
    categoryCalls++;
    return categoriesResult;
  }

  @override
  Future<ApiResult<LedgerEntry>> record(Json body, {required String idempotencyKey}) async {
    records.add((body: body, key: idempotencyKey));
    return recordResult ??
        ApiSuccess(
          LedgerEntry.fromJson(
            txJson(id: 40, type: '${body['type']}', currency: '${body['currency']}', amount: body['amount'] as num),
          ),
          message: 'تم تسجيل المصروف',
        );
  }

  @override
  Future<ApiResult<LedgerReversal>> reverse(int id, String reason, {required String idempotencyKey}) async {
    reversals.add((id: id, reason: reason, key: idempotencyKey));
    return reverseResult ??
        ApiSuccess(
          LedgerReversal.fromJson({
            'original': txJson(id: id, reversed: true),
            'reversal': txJson(id: 41, type: 'reversal', typeLabel: 'عكس حركة', direction: 'in', reversalOfId: id),
          }),
          message: 'تم عكس الحركة بإيصال B1-2026-000041',
        );
  }

  @override
  Future<ApiResult<FileBlob>> receipt(int id) async {
    receipts.add(id);
    return const ApiFailure(Failure(type: FailureType.server, message: 'تعذّر إنشاء الإيصال'));
  }
}
