import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_gym_admin/core/error/failure.dart';
import 'package:ultra_gym_admin/core/layout/nav_config.dart';
import 'package:ultra_gym_admin/core/networking/api_result.dart';
import 'package:ultra_gym_admin/core/networking/auth_interceptor.dart';
import 'package:ultra_gym_admin/core/router/routes.dart';
import 'package:ultra_gym_admin/features/club_plan/domain/models/club_plan_models.dart';
import 'package:ultra_gym_admin/features/club_plan/presentation/bloc/club_plan_cubit.dart';

import '../../core/layout/shell_harness.dart';
import 'fake_club_plan_repository.dart';

void main() {
  group('models', () {
    test('entitlements from the real response: limits (null = unlimited) and features', () {
      final e = Entitlements.fromJson(entitlementsJson);
      expect(e.limits.players, isNull);
      expect(e.limits.branches, 10);
      expect(e.has(PlanFeature.advancedFinance), isTrue);
      expect(e.has(PlanFeature.customBranding), isFalse);
      expect(e.has('something_new'), isTrue, reason: 'unknown features are not hidden; the server decides');
    });

    test('subscription: grace and read-only from status, days kept as club days', () {
      final g = ClubSubscription.fromJson(subscriptionJson('grace'));
      expect((g.inGrace, g.isReadOnly, g.planName), (true, false, 'Pro'));
      expect(g.graceEndsOn, DateTime(2026, 11, 11));
      expect(ClubSubscription.fromJson(subscriptionJson('expired')).isReadOnly, isTrue);
    });
  });

  group('ClubPlanCubit', () {
    late FakeClubPlanRepository repo;
    late SessionEvents events;
    setUp(() {
      repo = FakeClubPlanRepository();
      events = SessionEvents();
    });

    test('owner loads features and the club subscription; receptionist features only', () async {
      repo.subscriptionResult = ApiSuccess(ClubSubscription.fromJson(subscriptionJson('grace')));
      final owner = ClubPlanCubit(repo, events, owner: true);
      addTearDown(owner.close);
      await owner.load();
      expect(owner.state.inGrace, isTrue);
      expect(owner.state.has(PlanFeature.customBranding), isFalse);

      final reception = ClubPlanCubit(repo, events, owner: false);
      addTearDown(reception.close);
      await reception.load();
      expect(repo.subscriptionCalls, 1);
      expect(reception.state.inGrace, isFalse);
    });

    test('failure hides nothing; a SUBSCRIPTION_EXPIRED rejection turns read-only on', () async {
      repo.entitlementsResult = const ApiFailure(Failure(type: FailureType.network, message: 'x'));
      final cubit = ClubPlanCubit(repo, events, owner: false);
      addTearDown(cubit.close);
      await cubit.load();
      expect(cubit.state.has(PlanFeature.advancedFinance), isTrue);
      events.add(SessionEvent.readOnly);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.readOnly, isTrue);
    });
  });

  test('nav hides sections whose feature is off', () {
    final off = entitlementsWithout({PlanFeature.advancedFinance, PlanFeature.offlineReception});
    final routes = [
      for (final g in AdminNav.visibleFor(owner, has: (f) => f == null || off.has(f)))
        for (final e in g.entries) e.route,
    ];
    expect(routes, isNot(contains(Routes.payroll)));
    expect(routes, isNot(contains(Routes.receptionDevices)));
    expect(routes, contains(Routes.staff));
  });

  group('shell', () {
    final h = ShellHarness();
    setUp(h.setUp);
    tearDown(h.tearDown);

    testWidgets('a feature outside the plan leaves the menu, and its link says so', (tester) async {
      h.plan.entitlementsResult = ApiSuccess(entitlementsWithout({PlanFeature.advancedFinance}));
      await h.pump(tester, 1280, at: Routes.payroll);
      expect(find.text('الرواتب والسلف'), findsOneWidget, reason: 'only the top-bar title');
      expect(find.text('هذه الميزة ليست ضمن باقتك'), findsOneWidget);
      await tester.tap(find.text('عرض الباقة الحالية'));
      await tester.pumpAndSettle();
      expect(h.location, Routes.billing);
      expect(find.text('الرواتب والسلف'), findsNothing);
    });

    testWidgets('grace banner for the owner, with the date and the billing link', (tester) async {
      h.plan.subscriptionResult = ApiSuccess(ClubSubscription.fromJson(subscriptionJson('grace')));
      await h.pump(tester, 1280, at: pendingRoute);
      expect(find.text('انتهى اشتراك النادي بالمنصة، وأنت بفترة السماح حتى 11 تشرين الثاني.'), findsOneWidget);
      await tester.tap(find.text('عرض الفاتورة'));
      await tester.pumpAndSettle();
      expect(h.location, Routes.billing);
    });

    testWidgets('no subscription problem: no banner', (tester) async {
      await h.pump(tester, 1280, at: pendingRoute);
      expect(find.textContaining('اشتراك النادي بالمنصة'), findsNothing);
      expect(h.plan.subscriptionCalls, 1);
    });

    testWidgets('receptionist: read-only banner after a rejected operation, without the owner link', (tester) async {
      await h.pump(tester, 1280, session: receptionist, at: Routes.dashboard);
      expect(h.plan.subscriptionCalls, 0);
      h.events.add(SessionEvent.readOnly);
      await tester.pumpAndSettle();
      expect(find.text('اللوحة للقراءة فقط: انتهى اشتراك النادي بالمنصة.'), findsOneWidget);
      expect(find.text('تواصل مع UltraGym'), findsNothing);
      expect(h.auth.state.session, isNotNull, reason: 'read-only does not end the session');
    });

    for (final w in [360.0, 800.0]) {
      testWidgets('banner and locked page fit at ${w.toInt()}px', (tester) async {
        h.plan.subscriptionResult = ApiSuccess(ClubSubscription.fromJson(subscriptionJson('expired')));
        h.plan.entitlementsResult = ApiSuccess(entitlementsWithout({PlanFeature.offlineReception}));
        await h.pump(tester, w, at: Routes.receptionDevices);
        expect(find.text('هذه الميزة ليست ضمن باقتك'), findsOneWidget);
        expect(find.byType(TextButton), findsWidgets);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
