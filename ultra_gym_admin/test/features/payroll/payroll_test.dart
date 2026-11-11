import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_gym_admin/core/bloc/app_form_cubit.dart';
import 'package:ultra_gym_admin/core/networking/api_result.dart';
import 'package:ultra_gym_admin/features/payroll/domain/models/payroll_models.dart';
import 'package:ultra_gym_admin/features/payroll/presentation/bloc/payroll_cubits.dart';
import 'package:ultra_gym_admin/features/payroll/presentation/widgets/payroll_actions.dart';

import 'fake_payroll_repository.dart';

void main() {
  group('models', () {
    test('staff, preview, salary and advance read the server shape', () {
      final s = PayrollStaff.fromJson(staffRows()[1]);
      expect(s.branchId, 2);
      expect(s.salaryCurrency, 'SYP');
      expect(PayrollTexts.role(s), 'مدرب · فرع المالكي');
      expect(PayrollTexts.role(PayrollStaff.fromJson(staffRows()[0])), 'مدرب كمال أجسام · الفرع الرئيسي - المزة');

      final p = SalaryPreview.fromJson(previewJson());
      expect(p.suggestedNetUsd, 286);
      expect(p.commissionClients, 3);
      expect(p.exchangeRate, 14500);
      expect(SalaryPreview.fromJson(previewJson(rate: null)).exchangeRate, isNull);

      final pay = SalaryPayment.fromJson(salaryJson());
      expect(pay.staffId, 2);
      expect(pay.netUsd, 162.41);
      expect(pay.transactionId, 501);

      final a = StaffAdvance.fromJson(advanceJson());
      expect(a.remainingUsd, 50);
      expect(a.deductedShare, closeTo(0.375, 1e-9));
      expect(StaffAdvance.fromJson(advanceJson(amount: 0, deducted: 0)).deductedShare, 0);
    });

    test('texts: months, recent periods across the year, statuses', () {
      expect(PayrollTexts.month('2026-11'), 'تشرين الثاني 2026');
      expect(PayrollTexts.recentPeriods(DateTime(2027, 2, 3), count: 4), ['2027-02', '2027-01', '2026-12', '2026-11']);
      expect(PayrollTexts.advanceStatus('settled').label, 'مسددة');
      expect(PayrollTexts.type('worker'), 'عامل');
    });
  });

  group('salary body and estimate', () {
    test('only positive extras are sent; base and commission stay with the server', () {
      final f = AppFormCubit(
        initial: {
          PayrollActions.currency: 'SYP',
          PayrollActions.bonus: '1,000.5',
          PayrollActions.deductions: '0',
          PayrollActions.advance: '20',
          PayrollActions.note: '  ',
        },
      );
      addTearDown(f.close);
      expect(PayrollActions.salaryBody(f, '2026-11'), {
        'period': '2026-11',
        'currency': 'SYP',
        'bonus_usd': 1000.5,
        'advance_deduction_usd': 20,
      });
      expect(PayrollActions.netOf(SalaryPreview.fromJson(previewJson()), f), 286 + 1000.5 - 20);
    });
  });

  group('cubits', () {
    test('roster: active staff with the month salaries keyed by staff', () async {
      final repo = FakePayrollRepository();
      final c = PayrollRosterCubit(repo, '2026-11');
      addTearDown(c.close);
      await c.load();
      expect(c.state.data!.staff, hasLength(2));
      expect(c.state.data!.paid.keys, [2]);
      final q = repo.salaryQueries.single;
      expect(q.perPage, 100);
      expect(q.filter('period'), '2026-11');
      expect(q.filter('status'), 'paid');
    });

    test('roster fails when either request fails', () async {
      final repo = FakePayrollRepository()..salariesResult = cashRequired;
      final c = PayrollRosterCubit(repo, '2026-11');
      addTearDown(c.close);
      await c.load();
      expect(c.state.failure?.code, 'CASH_SESSION_REQUIRED');
    });

    test('advances start with every status; stats read totals and the open remaining', () async {
      final repo = FakePayrollRepository();
      final list = AdvancesCubit(repo);
      final stats = AdvanceStatsCubit(repo);
      addTearDown(list.close);
      addTearDown(stats.close);
      await list.load();
      await stats.load();
      expect(repo.advanceQueries.first.filter('status'), isNull);
      expect(list.state.slice.data!.items, hasLength(2));
      expect(stats.state.data, const AdvanceStats(open: 3, openRemainingUsd: 50, settled: 5));
    });

    test('preview asks for the staff and period', () async {
      final repo = FakePayrollRepository();
      final c = SalaryPreviewCubit(repo, (staffId: 1, period: '2026-10'));
      addTearDown(c.close);
      await c.load();
      expect(repo.previews.single, (staffId: 1, period: '2026-10'));
      expect(c.state.data, isA<SalaryPreview>());
      expect(repo.previewResult, isA<ApiSuccess<SalaryPreview>>());
    });
  });
}
