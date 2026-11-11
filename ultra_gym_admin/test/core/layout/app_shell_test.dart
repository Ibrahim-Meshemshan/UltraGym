import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_gym_admin/core/layout/nav_config.dart';
import 'package:ultra_gym_admin/core/networking/auth_interceptor.dart';
import 'package:ultra_gym_admin/core/router/app_router.dart';
import 'package:ultra_gym_admin/core/router/routes.dart';
import 'package:ultra_gym_admin/features/auth/domain/models/auth_models.dart';
import 'package:ultra_gym_admin/features/auth/presentation/bloc/auth_bloc.dart';

import '../../features/auth/fake_auth_repository.dart';
import 'shell_harness.dart';

List<String> routesOf(Session s) => [
  for (final g in AdminNav.visibleFor(s))
    for (final e in g.entries) e.route,
];

void main() {
  group('AdminNav', () {
    test('owner with staff permission sees every section', () {
      expect(routesOf(owner), [for (final e in AdminNav.all) e.route]);
      expect(AdminNav.visibleFor(owner).map((g) => g.title), [null, 'التشغيل', 'المالية', 'النادي', 'الإدارة']);
    });

    test('receptionist sees operations only, and the admin group disappears', () {
      expect(routesOf(receptionist), [
        Routes.dashboard,
        Routes.members,
        Routes.memberships,
        Routes.attendance,
        Routes.dayPasses,
        Routes.cashSessions,
        Routes.reports,
        Routes.plans,
        Routes.training,
      ]);
      expect(AdminNav.visibleFor(receptionist).map((g) => g.title), isNot(contains('الإدارة')));
      final plans = AdminNav.entryFor(Routes.plans)!;
      expect(plans.labelFor(receptionist), 'الخطط');
      expect(plans.labelFor(owner), 'الخطط والكوبونات');
    });

    test('owner without staff permission loses payroll and staff', () {
      const limited = Session(
        user: AuthUser(id: 3, name: 'م'),
        roles: ['club_owner'],
      );
      expect(routesOf(limited), isNot(contains(Routes.payroll)));
      expect(routesOf(limited), isNot(contains(Routes.staff)));
      expect(routesOf(limited), contains(Routes.settings));
    });

    test('entryFor matches child paths and nothing outside the shell', () {
      expect(AdminNav.entryFor(Routes.child(Routes.members, 12))?.route, Routes.members);
      expect(AdminNav.entryFor(Routes.memberships)?.route, Routes.memberships);
      expect(AdminNav.entryFor('/membersx'), isNull);
      expect(AdminNav.entryFor(Routes.login), isNull);
    });
  });

  group('sectionGuard', () {
    late AuthBloc auth;
    setUp(() => auth = AuthBloc(FakeAuthRepository(), SessionEvents()));
    tearDown(() => auth.close());

    test('sends a receptionist away from owner sections, lets the owner in', () async {
      final payroll = AdminNav.entryFor(Routes.payroll)!;
      auth.add(const AuthLoggedIn(receptionist));
      await auth.stream.first;
      expect(sectionGuard(auth, payroll), Routes.dashboard);
      expect(sectionGuard(auth, AdminNav.entryFor(Routes.members)!), isNull);
      auth.add(const AuthLoggedIn(owner));
      await auth.stream.first;
      expect(sectionGuard(auth, payroll), isNull);
    });
  });

  group('AppShell', () {
    final h = ShellHarness();
    setUp(h.setUp);
    tearDown(h.tearDown);

    Future<void> pump(WidgetTester tester, double width, {Session session = owner}) =>
        h.pump(tester, width, session: session);
    String topTitle(WidgetTester tester) => h.topTitle(tester);

    testWidgets('desktop: open sidebar with groups, navigation updates the title, fold hides labels', (tester) async {
      await pump(tester, 1280);
      expect(find.text('التشغيل'), findsOneWidget);
      expect(find.text('الإدارة'), findsOneWidget);
      expect(find.text('سامر الحلبي'), findsOneWidget);
      expect(find.text('مالك النادي'), findsOneWidget);
      expect(topTitle(tester), 'الأعضاء');

      await tester.tap(find.text('الحضور'));
      await tester.pumpAndSettle();
      expect(topTitle(tester), 'الحضور');

      await tester.tap(find.byTooltip('طيّ القائمة'));
      await tester.pumpAndSettle();
      expect(find.text('التشغيل'), findsNothing);
      expect(find.byTooltip('الاشتراكات والديون'), findsOneWidget);
      expect(find.byTooltip('فتح القائمة'), findsOneWidget);
    });

    testWidgets('top bar: branch picker and cash status follow the chosen branch', (tester) async {
      // قسم بلا محتوى: صفوف الأعضاء فيها أسماء الفروع أيضاً
      await h.pump(tester, 1280, at: pendingRoute);
      expect(find.text('كل الفروع'), findsOneWidget);
      expect(find.text('الصندوق: 1 من 2 مفتوح'), findsOneWidget);

      await tester.tap(find.text('كل الفروع'));
      await tester.pumpAndSettle();
      expect(find.text('الرئيسي · دمشق · الصندوق مفتوح'), findsOneWidget);
      await tester.tap(find.text('فرع المالكي').last);
      await tester.pumpAndSettle();
      expect(find.text('فرع المالكي'), findsOneWidget);
      expect(find.text('الصندوق مغلق'), findsOneWidget);
    });

    testWidgets('theme toggle switches and remembers the mode', (tester) async {
      await pump(tester, 1280);
      await tester.tap(find.byTooltip('الوضع الداكن'));
      await tester.pumpAndSettle();
      expect(h.theme.state, ThemeMode.dark);
    });

    testWidgets('tablet: sidebar is folded to icons with tooltips', (tester) async {
      await pump(tester, 800);
      expect(find.text('التشغيل'), findsNothing);
      expect(find.byTooltip('الصندوق والحركات'), findsOneWidget);
      expect(find.byTooltip('طيّ القائمة'), findsNothing);
    });

    testWidgets('mobile 360: drawer opens from the menu button and closes after choosing', (tester) async {
      await pump(tester, 360, session: receptionist);
      expect(find.text('التشغيل'), findsNothing);
      await tester.tap(find.byTooltip('القائمة'));
      await tester.pumpAndSettle();
      expect(find.text('التشغيل'), findsOneWidget);
      expect(find.text('الإدارة'), findsNothing);
      expect(find.text('الخطط'), findsOneWidget);
      await tester.tap(find.text('التقارير'));
      await tester.pumpAndSettle();
      expect(find.text('التشغيل'), findsNothing);
      expect(topTitle(tester), 'التقارير');
    });

    testWidgets('support session shows the fixed banner', (tester) async {
      await pump(
        tester,
        1280,
        session: const Session(
          user: AuthUser(id: 1, name: 'سامر الحلبي'),
          roles: ['club_owner'],
          isImpersonated: true,
        ),
      );
      expect(find.text('جلسة دعم من فريق UltraGym'), findsOneWidget);
      expect(find.text('إنهاء الجلسة'), findsOneWidget);
    });
  });
}
