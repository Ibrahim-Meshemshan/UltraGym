import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/announcements/presentation/screens/announcements_screen.dart';
import '../../features/attendance/presentation/screens/attendance_screen.dart';
import '../../features/billing/presentation/screens/billing_screen.dart';
import '../../features/cash_sessions/presentation/screens/cash_session_detail_screen.dart';
import '../../features/cash_sessions/presentation/screens/cash_sessions_screen.dart';
import '../../features/day_passes/presentation/screens/day_passes_screen.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/screens/blocked_screen.dart';
import '../../features/auth/presentation/screens/change_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/offline_screen.dart';
import '../../features/auth/presentation/screens/update_required_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/finance_settings/presentation/screens/exchange_rate_screen.dart';
import '../../features/finance_settings/presentation/screens/finance_categories_screen.dart';
import '../../features/members/presentation/screens/member_profile_screen.dart';
import '../../features/members/presentation/screens/members_screen.dart';
import '../../features/memberships/presentation/screens/membership_detail_screen.dart';
import '../../features/memberships/presentation/screens/memberships_screen.dart';
import '../../features/memberships/presentation/screens/sell_membership_screen.dart';
import '../../features/payroll/presentation/screens/payroll_screen.dart';
import '../../features/plans/presentation/screens/plans_screen.dart';
import '../../features/reception_devices/presentation/screens/reception_devices_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/staff/presentation/screens/staff_screen.dart';
import '../../features/training/presentation/screens/training_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/transactions/presentation/screens/transactions_screen.dart';
import '../layout/app_page.dart';
import '../layout/app_shell.dart';
import '../layout/nav_config.dart';
import '../theme/app_tokens.dart';
import 'routes.dart';

/// الراوتر الوحيد: يتبع `AuthBloc` ويعيد التوجيه حسب `AuthStatus`، والصفحة المطلوبة تُحفظ بـ `?from=`.
GoRouter buildRouter(AuthBloc auth) => GoRouter(
  initialLocation: Routes.splash,
  refreshListenable: StreamListenable(auth.stream),
  redirect: (context, state) => authRedirect(auth.state.status, state.uri),
  routes: [
    GoRoute(path: Routes.splash, pageBuilder: (c, s) => fadePage(s, const SplashScreen())),
    GoRoute(path: Routes.login, pageBuilder: (c, s) => fadePage(s, const LoginScreen())),
    GoRoute(path: Routes.changePassword, pageBuilder: (c, s) => fadePage(s, const ChangePasswordScreen())),
    GoRoute(path: Routes.offline, pageBuilder: (c, s) => fadePage(s, const OfflineScreen())),
    GoRoute(path: Routes.blocked, pageBuilder: (c, s) => fadePage(s, const BlockedScreen())),
    GoRoute(path: Routes.updateRequired, pageBuilder: (c, s) => fadePage(s, const UpdateRequiredScreen())),
    ShellRoute(
      builder: (context, state, child) => AppShell(location: state.uri.path, child: child),
      routes: [
        for (final e in AdminNav.all)
          GoRoute(
            path: e.route,
            redirect: (context, state) => sectionGuard(auth, e),
            pageBuilder: (c, s) => fadePage(s, _sectionPage(e)),
            // صفحة عنصر بالقسم (`/members/12`): من الجداول والبحث والإشعارات
            routes: [
              if (e.route == Routes.memberships)
                GoRoute(
                  path: 'new',
                  pageBuilder: (c, s) => fadePage(
                    s,
                    SellMembershipScreen(
                      key: ValueKey(s.uri.query),
                      playerId: int.tryParse(s.uri.queryParameters['player_id'] ?? ''),
                    ),
                  ),
                ),
              if (e.route == Routes.cashSessions) ...[
                GoRoute(path: 'transactions', pageBuilder: (c, s) => fadePage(s, const TransactionsScreen())),
                GoRoute(path: 'exchange-rate', pageBuilder: (c, s) => fadePage(s, const ExchangeRateScreen())),
                GoRoute(path: 'categories', pageBuilder: (c, s) => fadePage(s, const FinanceCategoriesScreen())),
              ],
              GoRoute(
                path: ':id',
                pageBuilder: (c, s) => fadePage(s, _itemPage(e, int.tryParse(s.pathParameters['id'] ?? ''))),
              ),
            ],
          ),
      ],
    ),
  ],
);

/// شاشة كل قسم. ما لم يُبنَ بعد يعرض `PendingSection` حتى تحل شاشته محله.
Widget _sectionPage(NavEntry e) => switch (e.route) {
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
  Routes.receptionDevices => const ReceptionDevicesScreen(),
  Routes.billing => const BillingScreen(),
  _ => PendingSection(title: e.label),
};

/// صفحة عنصر بالقسم. ما لم تُبنَ شاشة تفاصيله يعرض `PendingSection`.
Widget _itemPage(NavEntry e, int? id) => switch (e.route) {
  Routes.members => MemberProfileScreen(key: ValueKey(id), id: id),
  Routes.memberships => MembershipDetailScreen(key: ValueKey(id), id: id),
  Routes.cashSessions => CashSessionDetailScreen(key: ValueKey(id), id: id),
  _ => PendingSection(title: e.label),
};

/// قسم لا تسمح به الجلسة (رابط مكتوب يدوياً مثلاً) ← الرئيسية. الخادم يرفض على أي حال بـ 403.
String? sectionGuard(AuthBloc auth, NavEntry e) {
  final s = auth.state.session;
  return s == null || e.allowed(s) ? null : Routes.dashboard;
}

/// مسارات ما قبل الدخول: لا تُحفظ كـ `from`.
const _gates = {
  Routes.splash,
  Routes.login,
  Routes.changePassword,
  Routes.offline,
  Routes.blocked,
  Routes.updateRequired,
};

/// قرار التوجيه (منفصل للاختبار): null = ابقَ حيث أنت.
String? authRedirect(AuthStatus status, Uri uri) {
  final here = uri.path;
  final requested = uri.queryParameters['from'];
  final from = _gates.contains(here) ? _safe(requested) : _safe(uri.toString());

  String? go(String target) {
    if (here == target) return null;
    return Uri(path: target, queryParameters: from == null ? null : {'from': from}).toString();
  }

  return switch (status) {
    AuthStatus.unknown => go(Routes.splash),
    AuthStatus.updateRequired => go(Routes.updateRequired),
    AuthStatus.unauthenticated => go(Routes.login),
    AuthStatus.passwordChangeRequired => go(Routes.changePassword),
    AuthStatus.offline => go(Routes.offline),
    AuthStatus.blocked => go(Routes.blocked),
    AuthStatus.authenticated => _gates.contains(here) ? (from ?? Routes.dashboard) : null,
  };
}

/// يقبل مساراً داخلياً فقط (لا رابط خارجي عبر `from`).
String? _safe(String? path) =>
    path != null && path.startsWith('/') && !path.startsWith('//') && !_gates.contains(Uri.parse(path).path)
    ? path
    : null;

/// يحوّل stream حالة الـ Bloc لـ Listenable يحدّث الراوتر.
class StreamListenable extends ChangeNotifier {
  StreamListenable(Stream<Object?> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<Object?> _sub;

  @override
  void dispose() {
    unawaited(_sub.cancel());
    super.dispose();
  }
}

/// انتقال الشاشات العامة: تلاشٍ بمدة `AppMotion.slow`، ويُلغى مع "تقليل الحركة".
CustomTransitionPage<void> fadePage(GoRouterState state, Widget child) => CustomTransitionPage<void>(
  key: state.pageKey,
  child: child,
  transitionDuration: AppMotion.slow,
  reverseTransitionDuration: AppMotion.slow,
  transitionsBuilder: (context, animation, _, child) => AppMotion.reduced(context)
      ? child
      : FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: AppMotion.curve),
          child: child,
        ),
);
