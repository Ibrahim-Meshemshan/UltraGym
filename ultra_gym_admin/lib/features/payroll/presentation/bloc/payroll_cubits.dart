import 'dart:async';

import '../../../../core/core.dart';
import '../../data/repo/payroll_repository.dart';
import '../../domain/models/payroll_models.dart';

/// قائمة رواتب شهر: الموظفون الفعّالون ورواتب الشهر المدفوعة بالتوازي (حتى 100 موظف).
class PayrollRosterCubit extends LoadCubit<PayrollRoster> {
  PayrollRosterCubit(PayrollRepository repo, String period)
    : super(() async {
        final (staff, salaries) = await (
          repo.staff(),
          repo.salaries(ListQuery(perPage: 100, filters: {'period': period, 'status': 'paid'})),
        ).wait;
        return switch ((staff, salaries)) {
          (ApiSuccess(data: final s), ApiSuccess(data: final p)) => ApiSuccess(
            PayrollRoster(staff: s, paid: {for (final x in p.items) x.staffId: x}),
          ),
          (ApiFailure(:final failure), _) || (_, ApiFailure(:final failure)) => ApiFailure(failure),
        };
      });
}

/// معاينة راتب موظف لشهر (تُطلب فقط لمن لم يُصرف راتبه).
class SalaryPreviewCubit extends LoadCubit<SalaryPreview> {
  SalaryPreviewCubit(PayrollRepository repo, ({int staffId, String period}) args)
    : super(() => repo.preview(args.staffId, args.period));
}

/// جدول السلف (الأحدث أولاً) بكل الحالات، فنادٍ بلا سلف يرى الدعوة لا "لا نتائج".
class AdvancesCubit extends ListCubit<StaffAdvance> {
  AdvancesCubit(PayrollRepository repo) : super((q) => repo.advances(q));
}

/// أرقام السلف: عدد المفتوحة والمسددة (صف واحد لكل طلب) والمتبقي للخصم من `meta.summary`.
class AdvanceStatsCubit extends LoadCubit<AdvanceStats> {
  AdvanceStatsCubit(PayrollRepository repo)
    : super(() async {
        ListQuery one(String status) => ListQuery(perPage: 1, filters: {AdvanceFilters.status: status});
        final (open, settled) = await (repo.advances(one('open')), repo.advances(one('settled'))).wait;
        return switch ((open, settled)) {
          (ApiSuccess(data: final o), ApiSuccess(data: final s)) => ApiSuccess(
            AdvanceStats(
              open: o.pagination.total,
              settled: s.pagination.total,
              openRemainingUsd: o.summary.dbl('open_remaining_usd'),
            ),
          ),
          (ApiFailure(:final failure), _) || (_, ApiFailure(:final failure)) => ApiFailure(failure),
        };
      });
}

/// الموظفون الفعّالون (نافذة السلفة وفلتر الجدول).
class PayrollStaffCubit extends LoadCubit<List<PayrollStaff>> {
  PayrollStaffCubit(PayrollRepository repo) : super(repo.staff);
}

abstract final class AdvanceFilters {
  static const status = 'status', staff = 'staff_member_id';
}
