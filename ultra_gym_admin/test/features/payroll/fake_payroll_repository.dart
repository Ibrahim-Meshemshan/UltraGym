import 'package:ultra_gym_admin/core/error/failure.dart';
import 'package:ultra_gym_admin/core/networking/api_result.dart';
import 'package:ultra_gym_admin/core/networking/list_query.dart';
import 'package:ultra_gym_admin/core/networking/paged.dart';
import 'package:ultra_gym_admin/core/utils/json_x.dart';
import 'package:ultra_gym_admin/features/payroll/data/repo/payroll_repository.dart';
import 'package:ultra_gym_admin/features/payroll/domain/models/payroll_models.dart';

/// موظف بشكل `ClubPayloads::staffMember` (من رد حقيقي).
Json staffJson({
  int id = 1,
  String name = 'كابتن مازن',
  String type = 'trainer',
  String? jobTitle = 'مدرب كمال أجسام',
  int branchId = 1,
  String branchName = 'الفرع الرئيسي - المزة',
  String currency = 'USD',
  num salary = 250,
  num openAdvances = 0,
}) => {
  'id': id,
  'name': name,
  'phone': '+963955111222',
  'type': type,
  'job_title': jobTitle,
  'branch': {'id': branchId, 'name': branchName},
  'salary_currency': currency,
  'salary_amount': salary,
  'commission_type': 'percent',
  'commission_percent': 20,
  'commission_fixed_usd': 0,
  'status': 'active',
  'hired_on': null,
  'notes': null,
  'open_advances_usd': openAdvances,
  'created_at': '2026-09-27T09:00:00Z',
};

List<Json> staffRows() => [
  staffJson(openAdvances: 50),
  staffJson(
    id: 2,
    name: 'كابتن لينا',
    jobTitle: null,
    branchId: 2,
    branchName: 'فرع المالكي',
    currency: 'SYP',
    salary: 2500000,
  ),
];

/// معاينة بشكل `PayrollController::computation`.
Json previewJson({
  int staffId = 1,
  String period = '2026-11',
  num base = 250,
  num commission = 36,
  int clients = 3,
  num open = 50,
  bool paid = false,
  num? rate = 14500,
}) => {
  'staff_member': staffJson(id: staffId, openAdvances: open),
  'period': period,
  'base_usd': base,
  'commission_usd': commission,
  'commission_clients': clients,
  'open_advances_usd': open,
  'suggested_net_usd': base + commission,
  'already_paid': paid,
  'exchange_rate': rate,
  'today': '2026-11-10',
};

/// راتب بشكل `salaryPayload`.
Json salaryJson({
  int id = 7,
  int staffId = 2,
  String staffName = 'كابتن لينا',
  String period = '2026-11',
  num net = 162.41,
  int? tx = 501,
}) => {
  'id': id,
  'staff_member': {'id': staffId, 'name': staffName},
  'period': period,
  'base_usd': 172.41,
  'commission_usd': 0,
  'bonus_usd': 10,
  'deductions_usd': 20,
  'advance_deduction_usd': 0,
  'net_usd': net,
  'status': 'paid',
  'note': 'خصم تأخير',
  'transaction_id': tx,
  'created_at': '2026-11-05T10:00:00Z',
};

/// سلفة بشكل `advancePayload`.
Json advanceJson({
  int id = 1,
  int staffId = 1,
  String staffName = 'كابتن مازن',
  num amount = 80,
  num deducted = 30,
  String status = 'open',
  String? note = 'سلفة طارئة',
  int? tx = 400,
}) => {
  'id': id,
  'staff_member': {'id': staffId, 'name': staffName},
  'amount_usd': amount,
  'deducted_usd': deducted,
  'remaining_usd': amount - deducted,
  'status': status,
  'note': note,
  'transaction_id': tx,
  'created_at': '2026-11-02T08:00:00Z',
};

Paged<T> pageOf<T>(List<T> items, {Json summary = const {}, int? total}) => Paged(
  items: items,
  pagination: Pagination(currentPage: 1, perPage: 15, total: total ?? items.length, lastPage: 1),
  summary: summary,
);

class FakePayrollRepository implements PayrollRepository {
  ApiResult<List<PayrollStaff>> staffResult = ApiSuccess([for (final j in staffRows()) PayrollStaff.fromJson(j)]);
  ApiResult<Paged<SalaryPayment>> salariesResult = ApiSuccess(pageOf([SalaryPayment.fromJson(salaryJson())]));
  ApiResult<SalaryPreview> previewResult = ApiSuccess(SalaryPreview.fromJson(previewJson()));
  ApiResult<SalaryPayment>? payResult;
  ApiResult<Paged<StaffAdvance>>? advancesResult;
  ApiResult<StaffAdvance>? addResult;

  final salaryQueries = <ListQuery>[];
  final previews = <({int staffId, String period})>[];
  final paid = <({int staffId, Json body, String? key})>[];
  final advanceQueries = <ListQuery>[];
  final added = <({Json body, String? key})>[];

  @override
  Future<ApiResult<List<PayrollStaff>>> staff() async => staffResult;

  @override
  Future<ApiResult<Paged<SalaryPayment>>> salaries(ListQuery query) async {
    salaryQueries.add(query);
    return salariesResult;
  }

  @override
  Future<ApiResult<SalaryPreview>> preview(int staffId, String period) async {
    previews.add((staffId: staffId, period: period));
    return previewResult;
  }

  @override
  Future<ApiResult<SalaryPayment>> paySalary(int staffId, Json body, {String? idempotencyKey}) async {
    paid.add((staffId: staffId, body: body, key: idempotencyKey));
    final r = payResult ?? ApiSuccess(SalaryPayment.fromJson(salaryJson(staffId: staffId)), message: 'تم دفع الراتب');
    if (r is ApiSuccess) {
      salariesResult = ApiSuccess(
        pageOf([
          SalaryPayment.fromJson(salaryJson()),
          SalaryPayment.fromJson(salaryJson(id: 8, staffId: staffId, staffName: 'كابتن مازن', net: 316)),
        ]),
      );
    }
    return r;
  }

  @override
  Future<ApiResult<Paged<StaffAdvance>>> advances(ListQuery query) async {
    advanceQueries.add(query);
    if (advancesResult case final r?) return r;
    final status = query.filter('status');
    final rows = [
      StaffAdvance.fromJson(advanceJson()),
      StaffAdvance.fromJson(advanceJson(id: 2, staffId: 2, staffName: 'كابتن لينا', amount: 40, deducted: 40, status: 'settled', note: null)),
    ].where((a) => status == null || a.status == status).toList();
    return ApiSuccess(
      pageOf(rows, summary: {'open_remaining_usd': 50}, total: query.perPage == 1 ? (status == 'open' ? 3 : 5) : null),
    );
  }

  @override
  Future<ApiResult<StaffAdvance>> addAdvance(Json body, {String? idempotencyKey}) async {
    added.add((body: body, key: idempotencyKey));
    return addResult ?? ApiSuccess(StaffAdvance.fromJson(advanceJson(id: 9)), message: 'تم تسجيل السلفة');
  }
}

const cashRequired = ApiFailure<Never>(
  Failure(type: FailureType.conflict, code: 'CASH_SESSION_REQUIRED', message: 'لا توجد وردية صندوق مفتوحة لهذا الفرع'),
);
