import 'package:get_it/get_it.dart';

import '../../features/announcements/data/datasources/announcements_remote_datasource.dart';
import '../../features/announcements/data/repo/announcements_repository.dart';
import '../../features/announcements/presentation/bloc/announcements_cubit.dart';
import '../../features/attendance/data/datasources/attendance_remote_datasource.dart';
import '../../features/attendance/data/repo/attendance_repository.dart';
import '../../features/attendance/presentation/bloc/attendance_cubit.dart';
import '../../features/attendance/presentation/widgets/qr_scan_dialog.dart';
import '../../features/cash_sessions/data/datasources/cash_sessions_remote_datasource.dart';
import '../../features/cash_sessions/data/repo/cash_sessions_repository.dart';
import '../../features/cash_sessions/presentation/bloc/cash_sessions_cubit.dart';
import '../../features/day_passes/data/datasources/day_passes_remote_datasource.dart';
import '../../features/day_passes/data/repo/day_passes_repository.dart';
import '../../features/day_passes/presentation/bloc/day_passes_cubit.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repo/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/login_cubit.dart';
import '../../features/branches/data/datasources/branches_remote_datasource.dart';
import '../../features/branches/data/repo/branches_repository.dart';
import '../../features/branches/presentation/bloc/branch_scope_cubit.dart';
import '../../features/club_plan/data/datasources/club_plan_remote_datasource.dart';
import '../../features/club_plan/data/repo/club_plan_repository.dart';
import '../../features/club_plan/presentation/bloc/club_plan_cubit.dart';
import '../../features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import '../../features/dashboard/data/repo/dashboard_repository.dart';
import '../../features/dashboard/presentation/bloc/dashboard_cubit.dart';
import '../../features/members/data/datasources/member_profile_remote_datasource.dart';
import '../../features/members/data/datasources/members_remote_datasource.dart';
import '../../features/members/data/repo/member_profile_repository.dart';
import '../../features/members/data/repo/members_repository.dart';
import '../../features/members/domain/models/member_profile_models.dart';
import '../../features/members/presentation/bloc/member_profile_cubit.dart';
import '../../features/members/presentation/bloc/members_cubit.dart';
import '../../features/memberships/data/datasources/membership_detail_remote_datasource.dart';
import '../../features/memberships/data/datasources/memberships_remote_datasource.dart';
import '../../features/memberships/data/datasources/sell_membership_remote_datasource.dart';
import '../../features/memberships/data/repo/membership_detail_repository.dart';
import '../../features/memberships/data/repo/memberships_repository.dart';
import '../../features/memberships/data/repo/sell_membership_repository.dart';
import '../../features/memberships/presentation/bloc/membership_detail_cubit.dart';
import '../../features/memberships/presentation/bloc/memberships_cubit.dart';
import '../../features/memberships/presentation/bloc/sell_membership_cubit.dart';
import '../../features/finance_settings/data/datasources/finance_settings_remote_datasource.dart';
import '../../features/finance_settings/data/repo/finance_settings_repository.dart';
import '../../features/finance_settings/presentation/bloc/finance_settings_cubit.dart';
import '../../features/payroll/data/datasources/payroll_remote_datasource.dart';
import '../../features/payroll/data/repo/payroll_repository.dart';
import '../../features/payroll/presentation/bloc/payroll_cubits.dart';
import '../../features/plans/data/datasources/plans_remote_datasource.dart';
import '../../features/settings/data/datasources/settings_remote_datasource.dart';
import '../../features/settings/data/repo/settings_repository.dart';
import '../../features/settings/domain/models/branch_draft.dart';
import '../../features/settings/presentation/bloc/settings_cubits.dart';
import '../../features/billing/data/datasources/billing_remote_datasource.dart';
import '../../features/billing/data/repo/billing_repository.dart';
import '../../features/billing/presentation/bloc/billing_cubits.dart';
import '../../features/reception_devices/data/datasources/reception_devices_remote_datasource.dart';
import '../../features/reception_devices/data/repo/reception_devices_repository.dart';
import '../../features/reception_devices/presentation/bloc/reception_devices_cubit.dart';
import '../../features/staff/data/datasources/staff_remote_datasource.dart';
import '../../features/staff/data/repo/staff_repository.dart';
import '../../features/staff/presentation/bloc/staff_cubits.dart';
import '../../features/plans/data/repo/plans_repository.dart';
import '../../features/plans/presentation/bloc/plans_cubit.dart';
import '../../features/reports/data/datasources/reports_remote_datasource.dart';
import '../../features/reports/data/repo/reports_repository.dart';
import '../../features/reports/domain/models/reports_models.dart';
import '../../features/reports/presentation/bloc/reports_cubits.dart';
import '../../features/training/data/datasources/training_remote_datasource.dart';
import '../../features/training/data/repo/training_repository.dart';
import '../../features/training/presentation/bloc/training_cubits.dart';
import '../../features/transactions/data/datasources/transactions_remote_datasource.dart';
import '../../features/transactions/data/repo/transactions_repository.dart';
import '../../features/transactions/presentation/bloc/transactions_cubit.dart';
import '../../features/notifications/data/datasources/notifications_remote_datasource.dart';
import '../../features/notifications/data/repo/notifications_repository.dart';
import '../../features/notifications/presentation/bloc/notifications_list_cubit.dart';
import '../../features/notifications/presentation/bloc/unread_count_cubit.dart';
import '../../features/quick_search/data/datasources/quick_search_remote_datasource.dart';
import '../../features/quick_search/data/repo/quick_search_repository.dart';
import '../../features/quick_search/presentation/bloc/quick_search_cubit.dart';

/// تسجيل الميزات: المستودع `registerLazySingleton<XRepository>(() => XRemoteDataSource(sl()))`،
/// وحالة الجلسة المشتركة lazySingleton، و Bloc الشاشة `registerFactory`.
void registerFeatures(GetIt sl) {
  sl
    // الدخول والجلسة
    ..registerLazySingleton<AuthRepository>(() => AuthRemoteDataSource(sl(), sl()))
    ..registerLazySingleton<AuthBloc>(() => AuthBloc(sl(), sl()))
    ..registerFactory<LoginCubit>(() => LoginCubit(sl()))
    // الفروع: الفرع الحالي بعمر الهيكل (يُنشأ بـ AppShell بمفتاح المستخدم والنادي)
    ..registerLazySingleton<BranchesRepository>(() => BranchesRemoteDataSource(sl()))
    ..registerFactoryParam<BranchScopeCubit, String, void>((key, _) => BranchScopeCubit(sl(), sl(), storageKey: key))
    // باقة النادي بعمر الهيكل (param1 = المالك؟ لاشتراك النادي بالمنصة)
    ..registerLazySingleton<ClubPlanRepository>(() => ClubPlanRemoteDataSource(sl()))
    ..registerFactoryParam<ClubPlanCubit, bool, void>((owner, _) => ClubPlanCubit(sl(), sl(), owner: owner))
    // البحث السريع: نافذة جديدة بالفرع المحدد حالياً (param1 = branchId أو null)
    ..registerLazySingleton<QuickSearchRepository>(() => QuickSearchRemoteDataSource(sl()))
    ..registerFactoryParam<QuickSearchCubit, int?, void>((branchId, _) => QuickSearchCubit(sl(), branchId: branchId))
    // الرئيسية: Cubit لكل فرع مختار (param1 = branchId أو null)
    ..registerLazySingleton<DashboardRepository>(() => DashboardRemoteDataSource(sl()))
    ..registerFactoryParam<DashboardCubit, int?, void>((branchId, _) => DashboardCubit(sl(), branchId: branchId))
    // الأعضاء: قائمة لكل (تبويب، فرع، فلتر أولي)، والعدّادان لكل فرع
    ..registerLazySingleton<MembersRepository>(() => MembersRemoteDataSource(sl()))
    ..registerFactoryParam<MembersListCubit, MembersArgs, void>((args, _) => MembersListCubit(sl(), args))
    ..registerFactoryParam<MemberCountsCubit, int?, void>((branchId, _) => MemberCountsCubit(sl(), branchId: branchId))
    // الاشتراكات: قائمة لكل (تبويب، فرع، فلتر أولي)، والأرقام لكل فرع، والخطط للفلتر
    ..registerLazySingleton<MembershipsRepository>(() => MembershipsRemoteDataSource(sl()))
    ..registerFactoryParam<MembershipsListCubit, MembershipsArgs, void>((args, _) => MembershipsListCubit(sl(), args))
    ..registerFactoryParam<MembershipStatsCubit, int?, void>(
      (branchId, _) => MembershipStatsCubit(sl(), branchId: branchId),
    )
    ..registerFactory<PlanOptionsCubit>(() => PlanOptionsCubit(sl()))
    // صفحة الاشتراك: Cubit لكل معرّف، وزيارات فترته
    ..registerLazySingleton<SellMembershipRepository>(() => SellMembershipRemoteDataSource(sl()))
    ..registerFactoryParam<SellMembershipCubit, SellArgs, void>((a, _) => SellMembershipCubit(sl(), a))
    ..registerLazySingleton<MembershipDetailRepository>(() => MembershipDetailRemoteDataSource(sl()))
    ..registerFactoryParam<MembershipDetailCubit, int, void>((id, _) => MembershipDetailCubit(sl(), id))
    ..registerFactoryParam<MembershipAttendanceCubit, MembershipAttendanceArgs, void>(
      (a, _) => MembershipAttendanceCubit(sl(), a),
    )
    // ملف العضو: Cubit لكل معرّف، وسجل لكل تبويب (param1 = معرّف العضو)
    ..registerLazySingleton<MemberProfileRepository>(() => MemberProfileRemoteDataSource(sl()))
    ..registerFactoryParam<MemberProfileCubit, int, void>((id, _) => MemberProfileCubit(sl(), id))
    ..registerFactoryParam<MemberHistoryCubit<MembershipItem>, int, void>(
      (id, _) => MemberHistoryCubit((q) => sl<MemberProfileRepository>().memberships(id, q)),
    )
    ..registerFactoryParam<MemberHistoryCubit<AttendanceEntry>, int, void>(
      (id, _) => MemberHistoryCubit((q) => sl<MemberProfileRepository>().attendance(id, q)),
    )
    ..registerFactoryParam<MemberHistoryCubit<PaymentEntry>, int, void>(
      (id, _) => MemberHistoryCubit((q) => sl<MemberProfileRepository>().payments(id, q)),
    )
    // الحضور: السجل لكل (فرع، فلتر أولي)، وأرقام اليوم لكل فرع
    ..registerLazySingleton<AttendanceRepository>(() => AttendanceRemoteDataSource(sl()))
    // مسح QR بالكاميرا بنافذة تسجيل الدخول (الاختبارات تستبدله)
    ..registerLazySingleton<QrScanner>(() => const CameraQrScanner())
    ..registerFactoryParam<AttendanceListCubit, AttendanceArgs, void>((args, _) => AttendanceListCubit(sl(), args))
    ..registerFactoryParam<AttendanceTodayCubit, int?, void>(
      (branchId, _) => AttendanceTodayCubit(sl(), branchId: branchId),
    )
    // الدخول اليومي: السجل لكل (فرع، فلتر أولي)؛ نافذتا البيع والتفاصيل تنشئان Cubitيهما مباشرة
    ..registerLazySingleton<DayPassesRepository>(() => DayPassesRemoteDataSource(sl()))
    ..registerFactoryParam<DayPassesListCubit, DayPassesArgs, void>((args, _) => DayPassesListCubit(sl(), args))
    ..registerFactoryParam<DayPassPriceCubit, int?, void>((branchId, _) => DayPassPriceCubit(sl(), branchId: branchId))
    // الصندوق: صندوق لكل فرع، السجل لكل (فرع، فلتر أولي)، والتفاصيل بالمعرّف
    ..registerLazySingleton<CashSessionsRepository>(() => CashSessionsRemoteDataSource(sl()))
    ..registerFactoryParam<CashBoxCubit, int, void>((branchId, _) => CashBoxCubit(sl(), branchId))
    ..registerFactoryParam<CashHistoryCubit, CashHistoryArgs, void>((args, _) => CashHistoryCubit(sl(), args))
    ..registerFactoryParam<CashSessionDetailCubit, int, void>((id, _) => CashSessionDetailCubit(sl(), id))
    // دفتر الحركات: الدفتر لكل (فرع، فلتر أولي)، وتفاصيل الحركة بالمعرّف
    ..registerLazySingleton<TransactionsRepository>(() => TransactionsRemoteDataSource(sl()))
    ..registerFactoryParam<LedgerCubit, LedgerArgs, void>((args, _) => LedgerCubit(sl(), args))
    ..registerFactoryParam<LedgerEntryCubit, int, void>((id, _) => LedgerEntryCubit(sl(), id))
    // الإعدادات المالية: سجل سعر الصرف والتصنيفات
    ..registerLazySingleton<FinanceSettingsRepository>(() => FinanceSettingsRemoteDataSource(sl()))
    ..registerFactory<ExchangeRatesCubit>(() => ExchangeRatesCubit(sl()))
    ..registerFactory<FinanceCategoriesCubit>(() => FinanceCategoriesCubit(sl()))
    // الخطط والكوبونات: الخطط (أو أرشيفها)، الكوبونات، وكل الخطط لاختيار ما يشمله الكوبون
    ..registerLazySingleton<PlansRepository>(() => PlansRemoteDataSource(sl()))
    ..registerFactoryParam<PlansListCubit, bool, void>((archived, _) => PlansListCubit(sl(), archived: archived))
    ..registerFactory<CouponsCubit>(() => CouponsCubit(sl()))
    ..registerFactory<CouponPlansCubit>(() => CouponPlansCubit(sl()))
    // الرواتب والسلف: قائمة الشهر، معاينة راتب، جدول السلف وأرقامها، والموظفون الفعّالون
    ..registerLazySingleton<PayrollRepository>(() => PayrollRemoteDataSource(sl()))
    ..registerFactoryParam<PayrollRosterCubit, String, void>((period, _) => PayrollRosterCubit(sl(), period))
    ..registerFactoryParam<SalaryPreviewCubit, ({int staffId, String period}), void>(
      (args, _) => SalaryPreviewCubit(sl(), args),
    )
    ..registerFactory<AdvancesCubit>(() => AdvancesCubit(sl()))
    ..registerFactory<AdvanceStatsCubit>(() => AdvanceStatsCubit(sl()))
    ..registerFactory<PayrollStaffCubit>(() => PayrollStaffCubit(sl()))
    // التقارير: القائمة المتاحة وصيغها، وتقرير لكل طلب
    ..registerLazySingleton<ReportsRepository>(() => ReportsRemoteDataSource(sl()))
    ..registerFactory<ReportCatalogCubit>(() => ReportCatalogCubit(sl()))
    ..registerFactoryParam<ReportCubit, ReportQuery, void>((q, _) => ReportCubit(sl(), q))
    // التدريب: البرامج والقوالب، المدربون، والقياسات (صفحة لكل Cubit)
    ..registerLazySingleton<TrainingRepository>(() => TrainingRemoteDataSource(sl()))
    ..registerFactoryParam<WorkoutPlansCubit, bool, void>((templates, _) => WorkoutPlansCubit(sl(), templates))
    ..registerFactoryParam<WorkoutPlanCubit, int, void>((id, _) => WorkoutPlanCubit(sl(), id))
    ..registerFactory<TrainersCubit>(() => TrainersCubit(sl()))
    ..registerFactoryParam<TrainingMemberCubit, int, void>((id, _) => TrainingMemberCubit(sl(), id))
    ..registerFactoryParam<MeasurementsCubit, ({int playerId, int page}), void>((a, _) => MeasurementsCubit(sl(), a))
    // الإعلانات: قائمة بفلتر الحالة، والنشر والتعديل والحذف للمالك
    ..registerLazySingleton<AnnouncementsRepository>(() => AnnouncementsRemoteDataSource(sl()))
    ..registerFactory<AnnouncementsCubit>(() => AnnouncementsCubit(sl()))
    // الإعدادات والفروع: ملف النادي وإعداداته، أنواع الإشعارات، كل الفروع، ومحرر الفرع
    ..registerLazySingleton<SettingsRepository>(() => SettingsRemoteDataSource(sl()))
    ..registerFactory<ClubCubit>(() => ClubCubit(sl()))
    ..registerFactory<NotificationCatalogCubit>(() => NotificationCatalogCubit(sl()))
    ..registerFactory<SettingsBranchesCubit>(() => SettingsBranchesCubit(sl()))
    ..registerFactoryParam<BranchEditorCubit, BranchDraft, void>((d, _) => BranchEditorCubit(sl(), d))
    // الموظفون والحسابات: حد الباقة، الاستقبال، المدربون والعمال، وكل الحسابات
    ..registerLazySingleton<StaffRepository>(() => StaffRemoteDataSource(sl()))
    ..registerFactory<StaffUsageCubit>(() => StaffUsageCubit(sl()))
    ..registerFactory<ReceptionistsCubit>(() => ReceptionistsCubit(sl()))
    ..registerFactory<StaffMembersCubit>(() => StaffMembersCubit(sl()))
    ..registerFactory<AccountsCubit>(() => AccountsCubit(sl()))
    // أجهزة الاستقبال: القائمة لفرع الشريط العلوي (null = كل الفروع)
    ..registerLazySingleton<ReceptionDevicesRepository>(() => ReceptionDevicesRemoteDataSource(sl()))
    ..registerFactoryParam<ReceptionDevicesCubit, int?, void>((b, _) => ReceptionDevicesCubit(sl(), branchId: b))
    // اشتراك النادي والدعم وسجل النشاط (نوافذ التفاصيل والمحادثة تنشئ Cubitها من المستودع مباشرة)
    ..registerLazySingleton<BillingRepository>(() => BillingRemoteDataSource(sl()))
    ..registerLazySingleton<SupportRepository>(() => SupportRemoteDataSource(sl()))
    ..registerLazySingleton<ActivityLogRepository>(() => ActivityLogRemoteDataSource(sl()))
    ..registerFactory<BillingOverviewCubit>(() => BillingOverviewCubit(sl()))
    ..registerFactory<PlanUsageCubit>(() => PlanUsageCubit(sl()))
    ..registerFactory<InvoicesCubit>(() => InvoicesCubit(sl()))
    ..registerFactory<SupportTicketsCubit>(() => SupportTicketsCubit(sl()))
    ..registerFactory<ActivityLogCubit>(() => ActivityLogCubit(sl()))
    ..registerFactory<ActivityUsersCubit>(() => ActivityUsersCubit(sl()))
    // الجرس: العدّاد بعمر الهيكل (يُنشأ بـ AppShell)، والقائمة مع كل فتح
    ..registerLazySingleton<NotificationsRepository>(() => NotificationsRemoteDataSource(sl()))
    ..registerFactory<UnreadCountCubit>(() => UnreadCountCubit(sl()))
    ..registerFactory<NotificationsListCubit>(() => NotificationsListCubit(sl()));
}
