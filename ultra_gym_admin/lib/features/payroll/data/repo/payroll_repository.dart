import '../../../../core/core.dart';
import '../../domain/models/payroll_models.dart';

/// الرواتب والسلف (للمالك، ميزة `advanced_finance`) + الموظفون الفعّالون لاختيار الموظف.
abstract interface class PayrollRepository {
  /// `GET staff-members?status=active&per_page=100` بترتيب الاسم.
  Future<ApiResult<List<PayrollStaff>>> staff();

  /// `GET payroll/salaries` (فلاتر `period`، `staff_member_id`، `status`).
  Future<ApiResult<Paged<SalaryPayment>>> salaries(ListQuery query);

  /// `GET payroll/staff/{id}/preview?period=YYYY-MM`.
  Future<ApiResult<SalaryPreview>> preview(int staffId, String period);

  /// `POST payroll/staff/{id}/salary` ← الراتب المدفوع (حركة الصرف مع الرد).
  Future<ApiResult<SalaryPayment>> paySalary(int staffId, Json body, {String? idempotencyKey});

  /// `GET payroll/advances` (فلاتر `status`، `staff_member_id`؛ `meta.summary.open_remaining_usd`).
  Future<ApiResult<Paged<StaffAdvance>>> advances(ListQuery query);

  /// `POST payroll/advances` ← السلفة.
  Future<ApiResult<StaffAdvance>> addAdvance(Json body, {String? idempotencyKey});
}
