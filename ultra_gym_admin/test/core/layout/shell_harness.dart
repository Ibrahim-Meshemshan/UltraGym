import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ultra_gym_admin/core/layout/app_page.dart';
import 'package:ultra_gym_admin/core/layout/app_shell.dart';
import 'package:ultra_gym_admin/core/layout/app_top_bar.dart';
import 'package:ultra_gym_admin/core/layout/nav_config.dart';
import 'package:ultra_gym_admin/core/networking/api_result.dart';
import 'package:ultra_gym_admin/core/networking/auth_interceptor.dart';
import 'package:ultra_gym_admin/features/cash_sessions/presentation/screens/cash_session_detail_screen.dart';
import 'package:ultra_gym_admin/features/cash_sessions/presentation/screens/cash_sessions_screen.dart';
import 'package:ultra_gym_admin/features/club_plan/presentation/bloc/club_plan_cubit.dart';
import 'package:ultra_gym_admin/features/day_passes/data/repo/day_passes_repository.dart';
import 'package:ultra_gym_admin/features/day_passes/presentation/bloc/day_passes_cubit.dart';
import 'package:ultra_gym_admin/features/day_passes/presentation/screens/day_passes_screen.dart';
import 'package:ultra_gym_admin/core/networking/server_clock.dart';
import 'package:ultra_gym_admin/core/router/routes.dart';
import 'package:ultra_gym_admin/core/theme/app_theme.dart';
import 'package:ultra_gym_admin/core/theme/theme_cubit.dart';
import 'package:ultra_gym_admin/features/attendance/data/repo/attendance_repository.dart';
import 'package:ultra_gym_admin/features/attendance/presentation/bloc/attendance_cubit.dart';
import 'package:ultra_gym_admin/features/attendance/presentation/screens/attendance_screen.dart';
import 'package:ultra_gym_admin/features/attendance/presentation/widgets/qr_scan_dialog.dart';
import 'package:ultra_gym_admin/features/auth/domain/models/auth_models.dart';
import 'package:ultra_gym_admin/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ultra_gym_admin/features/branches/presentation/bloc/branch_scope_cubit.dart';
import 'package:ultra_gym_admin/features/dashboard/presentation/bloc/dashboard_cubit.dart';
import 'package:ultra_gym_admin/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:ultra_gym_admin/features/members/domain/models/member_profile_models.dart';
import 'package:ultra_gym_admin/features/members/presentation/bloc/member_profile_cubit.dart';
import 'package:ultra_gym_admin/features/members/presentation/bloc/members_cubit.dart';
import 'package:ultra_gym_admin/features/members/presentation/screens/member_profile_screen.dart';
import 'package:ultra_gym_admin/features/members/presentation/screens/members_screen.dart';
import 'package:ultra_gym_admin/features/memberships/data/repo/membership_detail_repository.dart';
import 'package:ultra_gym_admin/features/memberships/data/repo/sell_membership_repository.dart';
import 'package:ultra_gym_admin/features/memberships/presentation/bloc/membership_detail_cubit.dart';
import 'package:ultra_gym_admin/features/memberships/presentation/bloc/memberships_cubit.dart';
import 'package:ultra_gym_admin/features/memberships/presentation/bloc/sell_membership_cubit.dart';
import 'package:ultra_gym_admin/features/memberships/presentation/screens/membership_detail_screen.dart';
import 'package:ultra_gym_admin/features/memberships/presentation/screens/memberships_screen.dart';
import 'package:ultra_gym_admin/features/memberships/presentation/screens/sell_membership_screen.dart';
import 'package:ultra_gym_admin/features/notifications/presentation/bloc/notifications_list_cubit.dart';
import 'package:ultra_gym_admin/features/notifications/presentation/bloc/unread_count_cubit.dart';
import 'package:ultra_gym_admin/features/quick_search/presentation/bloc/quick_search_cubit.dart';
import 'package:ultra_gym_admin/features/finance_settings/presentation/screens/exchange_rate_screen.dart';
import 'package:ultra_gym_admin/features/finance_settings/presentation/screens/finance_categories_screen.dart';
import 'package:ultra_gym_admin/features/payroll/presentation/screens/payroll_screen.dart';
import 'package:ultra_gym_admin/features/plans/presentation/screens/plans_screen.dart';
import 'package:ultra_gym_admin/features/reports/presentation/screens/reports_screen.dart';
import 'package:ultra_gym_admin/features/training/presentation/screens/training_screen.dart';
import 'package:ultra_gym_admin/features/announcements/presentation/screens/announcements_screen.dart';
import 'package:ultra_gym_admin/features/settings/presentation/screens/settings_screen.dart';
import 'package:ultra_gym_admin/features/staff/presentation/screens/staff_screen.dart';
import 'package:ultra_gym_admin/features/transactions/presentation/screens/transactions_screen.dart';

import '../../features/attendance/fake_attendance_repository.dart';
import '../../features/cash_sessions/fake_cash_sessions_repository.dart';
import '../../features/club_plan/fake_club_plan_repository.dart';
import '../../features/day_passes/fake_day_passes_repository.dart';
import '../../features/auth/fake_auth_repository.dart';
import '../../features/branches/fake_branches_repository.dart';
import '../../features/dashboard/fake_dashboard_repository.dart';
import '../../features/finance_settings/fake_finance_settings_repository.dart';
import '../../features/payroll/fake_payroll_repository.dart';
import '../../features/plans/fake_plans_repository.dart';
import '../../features/reports/fake_reports_repository.dart';
import '../../features/training/fake_training_repository.dart';
import '../../features/announcements/fake_announcements_repository.dart';
import '../../features/settings/fake_settings_repository.dart';
import '../../features/staff/fake_staff_repository.dart';
import '../../features/members/fake_member_profile_repository.dart';
import '../../features/members/fake_members_repository.dart';
import '../../features/memberships/fake_membership_detail_repository.dart';
import '../../features/memberships/fake_memberships_repository.dart';
import '../../features/memberships/fake_sell_membership_repository.dart';
import '../../features/notifications/fake_notifications_repository.dart';
import '../../features/quick_search/fake_quick_search_repository.dart';
import '../../features/transactions/fake_transactions_repository.dart';
import '../../helpers/app_fonts.dart';
import 'shell_admin_fakes.dart';
import 'shell_money_fakes.dart';

const owner = Session(
  user: AuthUser(id: 1, name: 'سامر الحلبي'),
  tenant: TenantRef(id: 1, name: 'نادي القمة التجريبي', slug: 'demo'),
  roles: ['club_owner'],
  permissions: {'can_view_finance': true, 'can_manage_staff': true},
);

const receptionist = Session(
  user: AuthUser(id: 2, name: 'ريم العلي'),
  tenant: TenantRef(id: 1, name: 'نادي القمة التجريبي', slug: 'demo'),
  roles: ['receptionist'],
);

/// صفحة غير مبنية (كل الأقسام مبنية؛ صفحة عنصر بلا شاشة) لاختبارات الهيكل العامة.
final pendingRoute = Routes.child(Routes.billing, 1);

/// تجهيز اختبارات الهيكل: الجلسة والثيم والمستودعات الوهمية بـ GetIt، ثم `pump` بعرض محدد.
class ShellHarness {
  late AuthBloc auth;
  late ThemeCubit theme;
  late GoRouter router;
  late FakeNotificationsRepository notifications;
  late FakeQuickSearchRepository search;
  late FakeDashboardRepository dashboard;
  late FakeMembersRepository members;
  late FakeMemberProfileRepository profile;
  late FakeMembershipsRepository memberships;
  late FakeMembershipDetailRepository membership;
  late FakeSellMembershipRepository sell;
  late FakeAttendanceRepository attendance;
  late FakeQrScanner qr;
  late FakeClubPlanRepository plan;
  late FakeDayPassesRepository dayPasses;
  late FakeCashSessionsRepository cash;
  late FakeTransactionsRepository tx;
  late FakeFinanceSettingsRepository finance;
  late FakePlansRepository plans;
  late FakePayrollRepository payroll;
  late FakeReportsRepository reports;
  late FakeTrainingRepository training;
  late FakeAnnouncementsRepository announcements;
  late FakeSettingsRepository settings;
  late FakeStaffRepository staff;
  late ShellAdminFakes admin;
  late SessionEvents events;

  Future<void> setUp() async {
    await loadAppFonts();
    notifications = FakeNotificationsRepository();
    search = FakeQuickSearchRepository();
    dashboard = FakeDashboardRepository();
    members = FakeMembersRepository();
    profile = FakeMemberProfileRepository();
    memberships = FakeMembershipsRepository();
    membership = FakeMembershipDetailRepository();
    sell = FakeSellMembershipRepository();
    attendance = FakeAttendanceRepository();
    qr = FakeQrScanner();
    plan = FakeClubPlanRepository();
    dayPasses = FakeDayPassesRepository();
    cash = FakeCashSessionsRepository();
    tx = FakeTransactionsRepository();
    finance = FakeFinanceSettingsRepository();
    plans = FakePlansRepository();
    payroll = FakePayrollRepository();
    reports = FakeReportsRepository();
    training = FakeTrainingRepository();
    announcements = FakeAnnouncementsRepository();
    settings = FakeSettingsRepository();
    staff = FakeStaffRepository();
    admin = ShellAdminFakes()..register();
    events = SessionEvents();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    theme = ThemeCubit(prefs);
    auth = AuthBloc(FakeAuthRepository(), events);
    registerMoneyFakes(cash: cash, tx: tx, finance: finance, plans: plans, payroll: payroll, reports: reports);
    registerTrainingFakes(training);
    registerAnnouncementsFakes(announcements);
    registerSettingsFakes(settings);
    registerStaffFakes(staff);
    GetIt.instance
      ..registerSingleton(ServerClock())
      ..registerFactoryParam<BranchScopeCubit, String, void>(
        (key, _) => BranchScopeCubit(
          FakeBranchesRepository([
            const ApiSuccess([mainBranch, malkiBranch]),
          ]),
          prefs,
          storageKey: key,
        ),
      )
      ..registerFactoryParam<ClubPlanCubit, bool, void>((owner, _) => ClubPlanCubit(plan, events, owner: owner))
      ..registerFactory(() => UnreadCountCubit(notifications))
      ..registerFactory(() => NotificationsListCubit(notifications))
      ..registerFactoryParam<QuickSearchCubit, int?, void>(
        (branchId, _) => QuickSearchCubit(search, branchId: branchId, delay: Duration.zero),
      )
      ..registerFactoryParam<DashboardCubit, int?, void>((branchId, _) => DashboardCubit(dashboard, branchId: branchId))
      ..registerFactoryParam<MembersListCubit, MembersArgs, void>((args, _) => MembersListCubit(members, args))
      ..registerFactoryParam<MemberCountsCubit, int?, void>(
        (branchId, _) => MemberCountsCubit(members, branchId: branchId),
      )
      ..registerFactoryParam<MembershipsListCubit, MembershipsArgs, void>(
        (args, _) => MembershipsListCubit(memberships, args),
      )
      ..registerFactoryParam<MembershipStatsCubit, int?, void>(
        (branchId, _) => MembershipStatsCubit(memberships, branchId: branchId),
      )
      ..registerFactory(() => PlanOptionsCubit(memberships))
      ..registerSingleton<AttendanceRepository>(attendance)
      ..registerSingleton<QrScanner>(qr)
      ..registerFactoryParam<AttendanceListCubit, AttendanceArgs, void>((a, _) => AttendanceListCubit(attendance, a))
      ..registerFactoryParam<AttendanceTodayCubit, int?, void>(
        (branchId, _) => AttendanceTodayCubit(attendance, branchId: branchId),
      )
      ..registerSingleton<DayPassesRepository>(dayPasses)
      ..registerFactoryParam<DayPassesListCubit, DayPassesArgs, void>((a, _) => DayPassesListCubit(dayPasses, a))
      ..registerFactoryParam<DayPassPriceCubit, int?, void>((b, _) => DayPassPriceCubit(dayPasses, branchId: b))
      ..registerSingleton<SellMembershipRepository>(sell)
      ..registerFactoryParam<SellMembershipCubit, SellArgs, void>((a, _) => SellMembershipCubit(sell, a))
      ..registerSingleton<MembershipDetailRepository>(membership)
      ..registerFactoryParam<MembershipDetailCubit, int, void>((id, _) => MembershipDetailCubit(membership, id))
      ..registerFactoryParam<MembershipAttendanceCubit, MembershipAttendanceArgs, void>(
        (a, _) => MembershipAttendanceCubit(membership, a),
      )
      ..registerFactoryParam<MemberProfileCubit, int, void>((id, _) => MemberProfileCubit(profile, id))
      ..registerFactoryParam<MemberHistoryCubit<MembershipItem>, int, void>(
        (id, _) => MemberHistoryCubit((q) => profile.memberships(id, q)),
      )
      ..registerFactoryParam<MemberHistoryCubit<AttendanceEntry>, int, void>(
        (id, _) => MemberHistoryCubit((q) => profile.attendance(id, q)),
      )
      ..registerFactoryParam<MemberHistoryCubit<PaymentEntry>, int, void>(
        (id, _) => MemberHistoryCubit((q) => profile.payments(id, q)),
      );
  }

  Future<void> tearDown() async {
    await GetIt.instance.reset();
    await auth.close();
    await theme.close();
  }

  /// `at` = المسار الأول (الرئيسية والأعضاء وملف العضو والاشتراكات بشاشاتها الحقيقية، وباقي الأقسام `PendingSection`).
  Future<void> pump(WidgetTester tester, double width, {Session session = owner, String at = Routes.members}) async {
    tester.view.physicalSize = Size(width, 820);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    auth.add(AuthLoggedIn(session));
    await tester.pump();
    router = GoRouter(
      initialLocation: at,
      routes: [
        ShellRoute(
          builder: (c, s, child) => AppShell(location: s.uri.path, child: child),
          routes: [
            for (final e in AdminNav.all)
              GoRoute(
                path: e.route,
                builder: (c, s) => switch (e.route) {
                  Routes.dashboard => const DashboardScreen(),
                  Routes.members => const MembersScreen(),
                  Routes.memberships => const MembershipsScreen(),
                  Routes.attendance => const AttendanceScreen(),
                  Routes.dayPasses => const DayPassesScreen(),
                  Routes.cashSessions => const CashSessionsScreen(),
                  Routes.payroll => const PayrollScreen(),
                  Routes.reports => const ReportsScreen(),
                  Routes.plans => const PlansScreen(),
                  Routes.training => const TrainingScreen(),
                  Routes.announcements => const AnnouncementsScreen(),
                  Routes.settings => const SettingsScreen(),
                  Routes.staff => const StaffScreen(),
                  _ => ShellAdminFakes.page(e.route) ?? PendingSection(title: e.label),
                },
                routes: [
                  if (e.route == Routes.memberships)
                    GoRoute(
                      path: 'new',
                      builder: (c, s) =>
                          SellMembershipScreen(playerId: int.tryParse(s.uri.queryParameters['player_id'] ?? '')),
                    ),
                  if (e.route == Routes.cashSessions) ...[
                    GoRoute(path: 'transactions', builder: (c, s) => const TransactionsScreen()),
                    GoRoute(path: 'exchange-rate', builder: (c, s) => const ExchangeRateScreen()),
                    GoRoute(path: 'categories', builder: (c, s) => const FinanceCategoriesScreen()),
                  ],
                  GoRoute(
                    path: ':id',
                    builder: (c, s) => switch ((e.route, int.tryParse(s.pathParameters['id'] ?? ''))) {
                      (Routes.members, final id) => MemberProfileScreen(id: id),
                      (Routes.memberships, final id) => MembershipDetailScreen(id: id),
                      (Routes.cashSessions, final id) => CashSessionDetailScreen(id: id),
                      _ => PendingSection(title: e.label),
                    },
                  ),
                ],
              ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: auth),
          BlocProvider.value(value: theme),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (context, child) =>
              MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: true), child: child!),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  String get location => router.routerDelegate.currentConfiguration.uri.path;

  /// عنوان الشريط العلوي (أول نص بالشريط).
  String topTitle(WidgetTester tester) =>
      tester.widget<Text>(find.descendant(of: find.byType(AppTopBar), matching: find.byType(Text)).first).data!;
}
