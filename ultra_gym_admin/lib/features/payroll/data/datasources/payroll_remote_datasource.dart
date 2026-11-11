import '../../../../core/core.dart';
import '../../domain/models/payroll_models.dart';
import '../repo/payroll_repository.dart';

class PayrollRemoteDataSource implements PayrollRepository {
  PayrollRemoteDataSource(this._api);

  final ApiClient _api;

  static const _base = '/club-admin/payroll';

  @override
  Future<ApiResult<List<PayrollStaff>>> staff() async => (await _api.getPaged(
    '/club-admin/staff-members',
    fromJson: PayrollStaff.fromJson,
    query: const ListQuery(perPage: 100, filters: {'status': 'active'}),
  )).map((p) => p.items);

  @override
  Future<ApiResult<Paged<SalaryPayment>>> salaries(ListQuery query) =>
      _api.getPaged('$_base/salaries', fromJson: SalaryPayment.fromJson, query: query);

  @override
  Future<ApiResult<SalaryPreview>> preview(int staffId, String period) => _api.get(
    '$_base/staff/$staffId/preview',
    query: {'period': period},
    parse: Parse.object(SalaryPreview.fromJson),
  );

  @override
  Future<ApiResult<SalaryPayment>> paySalary(int staffId, Json body, {String? idempotencyKey}) => _api.post(
    '$_base/staff/$staffId/salary',
    body: body,
    idempotencyKey: idempotencyKey,
    parse: Parse.field('salary', SalaryPayment.fromJson),
  );

  @override
  Future<ApiResult<Paged<StaffAdvance>>> advances(ListQuery query) =>
      _api.getPaged('$_base/advances', fromJson: StaffAdvance.fromJson, query: query);

  @override
  Future<ApiResult<StaffAdvance>> addAdvance(Json body, {String? idempotencyKey}) => _api.post(
    '$_base/advances',
    body: body,
    idempotencyKey: idempotencyKey,
    parse: Parse.field('advance', StaffAdvance.fromJson),
  );
}
