import 'package:get_it/get_it.dart';
import 'package:ultra_gym_admin/features/cash_sessions/data/repo/cash_sessions_repository.dart';
import 'package:ultra_gym_admin/features/cash_sessions/presentation/bloc/cash_sessions_cubit.dart';
import 'package:ultra_gym_admin/features/finance_settings/data/repo/finance_settings_repository.dart';
import 'package:ultra_gym_admin/features/finance_settings/presentation/bloc/finance_settings_cubit.dart';
import 'package:ultra_gym_admin/features/payroll/data/repo/payroll_repository.dart';
import 'package:ultra_gym_admin/features/payroll/presentation/bloc/payroll_cubits.dart';
import 'package:ultra_gym_admin/features/plans/data/repo/plans_repository.dart';
import 'package:ultra_gym_admin/features/plans/presentation/bloc/plans_cubit.dart';
import 'package:ultra_gym_admin/features/reports/data/repo/reports_repository.dart';
import 'package:ultra_gym_admin/features/reports/domain/models/reports_models.dart';
import 'package:ultra_gym_admin/features/reports/presentation/bloc/reports_cubits.dart';
import 'package:ultra_gym_admin/features/transactions/data/repo/transactions_repository.dart';
import 'package:ultra_gym_admin/features/transactions/presentation/bloc/transactions_cubit.dart';

import '../../features/cash_sessions/fake_cash_sessions_repository.dart';
import '../../features/finance_settings/fake_finance_settings_repository.dart';
import '../../features/payroll/fake_payroll_repository.dart';
import '../../features/plans/fake_plans_repository.dart';
import '../../features/reports/fake_reports_repository.dart';
import '../../features/transactions/fake_transactions_repository.dart';

/// أقسام المال بـ ShellHarness (الصندوق، الدفتر، الإعدادات المالية، الخطط، الرواتب، التقارير): مستودعاتها الوهمية وCubitاتها.
void registerMoneyFakes({
  required FakeCashSessionsRepository cash,
  required FakeTransactionsRepository tx,
  required FakeFinanceSettingsRepository finance,
  required FakePlansRepository plans,
  required FakePayrollRepository payroll,
  required FakeReportsRepository reports,
}) {
  GetIt.instance
    ..registerSingleton<CashSessionsRepository>(cash)
    ..registerFactoryParam<CashBoxCubit, int, void>((b, _) => CashBoxCubit(cash, b))
    ..registerFactoryParam<CashHistoryCubit, CashHistoryArgs, void>((a, _) => CashHistoryCubit(cash, a))
    ..registerFactoryParam<CashSessionDetailCubit, int, void>((id, _) => CashSessionDetailCubit(cash, id))
    ..registerSingleton<TransactionsRepository>(tx)
    ..registerFactoryParam<LedgerCubit, LedgerArgs, void>((a, _) => LedgerCubit(tx, a))
    ..registerFactoryParam<LedgerEntryCubit, int, void>((id, _) => LedgerEntryCubit(tx, id))
    ..registerSingleton<FinanceSettingsRepository>(finance)
    ..registerFactory(() => ExchangeRatesCubit(finance))
    ..registerFactory(() => FinanceCategoriesCubit(finance))
    ..registerSingleton<PlansRepository>(plans)
    ..registerFactoryParam<PlansListCubit, bool, void>((a, _) => PlansListCubit(plans, archived: a))
    ..registerFactory(() => CouponsCubit(plans))
    ..registerFactory(() => CouponPlansCubit(plans))
    ..registerSingleton<PayrollRepository>(payroll)
    ..registerFactoryParam<PayrollRosterCubit, String, void>((p, _) => PayrollRosterCubit(payroll, p))
    ..registerFactoryParam<SalaryPreviewCubit, ({int staffId, String period}), void>(
      (a, _) => SalaryPreviewCubit(payroll, a),
    )
    ..registerFactory(() => AdvancesCubit(payroll))
    ..registerFactory(() => AdvanceStatsCubit(payroll))
    ..registerFactory(() => PayrollStaffCubit(payroll))
    ..registerSingleton<ReportsRepository>(reports)
    ..registerFactory(() => ReportCatalogCubit(reports))
    ..registerFactoryParam<ReportCubit, ReportQuery, void>((q, _) => ReportCubit(reports, q));
}
