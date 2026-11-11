import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_gym_admin/core/error/failure.dart';
import 'package:ultra_gym_admin/core/networking/api_result.dart';
import 'package:ultra_gym_admin/core/utils/formatters.dart';
import 'package:ultra_gym_admin/core/utils/json_x.dart';
import 'package:ultra_gym_admin/features/dashboard/domain/models/dashboard_models.dart';
import 'package:ultra_gym_admin/features/dashboard/presentation/bloc/dashboard_cubit.dart';

import 'fake_dashboard_repository.dart';

const offline = Failure(type: FailureType.network, message: 'تعذّر الاتصال.');

void main() {
  group('DashboardData.fromJson', () {
    test('owner: numbers, cash balances and the 14-day revenue', () {
      final d = ownerData;
      expect(d.businessDate, DateTime(2026, 11, 8));
      expect(d.players.total, 12);
      expect(d.memberships.inGrace, 1);
      expect(d.attendance.rejectedToday, 1);
      expect(d.debts.totalDueUsd, 20);
      expect(d.cashBoxes, hasLength(2));
      expect(d.cashBoxes.first.sessionId, 1);
      expect(d.cashBoxes.first.expectedUsd, 314.5);
      expect(d.cashBoxes.first.openedAt, DateTime.utc(2026, 9, 27, 9));
      expect(d.cashBoxes.last.isOpen, isFalse);
      expect(d.cashBoxes.last.hasBalance, isFalse);
      expect(d.finance?.netMonthUsd, -1.62);
      expect(d.finance?.daily, hasLength(14));
      expect(d.finance?.daily.last.date, DateTime(2026, 11, 8));
      expect(d.alerts.map((a) => a.type), ['cash_session_closed', 'memberships_expiring']);
    });

    test('receptionist: no finance and no cash balance', () {
      expect(receptionData.finance, isNull);
      expect(receptionData.cashBoxes.single.isOpen, isTrue);
      expect(receptionData.cashBoxes.single.hasBalance, isFalse);
    });

    test('missing sections fall back to zeros instead of throwing', () {
      final d = DashboardData.fromJson(asJson({'business_date': '2026-11-08'}));
      expect(d.players.total, 0);
      expect(d.cashBoxes, isEmpty);
      expect(d.finance, isNull);
    });

    test('expiring membership reads the list item shape', () {
      final m = ExpiringMembership.fromJson(
        asJson({
          'id': 3,
          'player': {'id': 3, 'name': 'أحمد الخطيب'},
          'plan': {'id': 4, 'name': 'تدريب خاص شهري'},
          'branch': {'id': 1, 'name': 'الفرع الرئيسي - المزة'},
          'ends_on': '2026-11-23',
          'days_remaining': 16,
          'status': 'active',
          'status_label': 'فعّال',
        }),
      );
      expect(m.playerName, 'أحمد الخطيب');
      expect(m.planName, 'تدريب خاص شهري');
      expect(m.endsOn, DateTime(2026, 11, 23));
      expect(m.daysRemaining, 16);
    });
  });

  test('Formatters.dayTitle uses Levantine month names', () {
    expect(Formatters.dayTitle(DateTime(2026, 11, 8)), 'الأحد 8 تشرين الثاني');
    expect(Formatters.weekday(DateTime(2026, 11, 4)), 'الأربعاء');
  });

  test('Formatters.usd puts the minus sign before the dollar sign', () {
    expect(Formatters.usd(1240.5), r'$1,240.50');
    expect(Formatters.usd(-1.62), r'-$1.62');
    expect(Formatters.usd(null), '—');
  });

  test('Formatters.ltr isolates a value inside an Arabic sentence', () {
    expect(Formatters.ltr('2026-09-27 12:00'), '\u20662026-09-27 12:00\u2069');
  });

  group('DashboardCubit', () {
    test('loads both parts with the selected branch', () async {
      final repo = FakeDashboardRepository();
      final cubit = DashboardCubit(repo, branchId: 2);
      await cubit.load();
      expect(repo.summaryCalls, [2]);
      expect(repo.expiringCalls, [2]);
      expect(cubit.state.summary.data, ownerData);
      expect(cubit.state.expiring.data, expiringSoon);
      await cubit.close();
    });

    test('a failed expiring list does not take the page down, and retries alone', () async {
      final repo = FakeDashboardRepository(expiring: const ApiFailure(offline));
      final cubit = DashboardCubit(repo);
      await cubit.load();
      expect(cubit.state.summary.isSuccess, isTrue);
      expect(cubit.state.expiring.failure, offline);

      repo.expiringResult = const ApiSuccess(expiringSoon);
      await cubit.retryExpiring();
      expect(cubit.state.expiring.data, expiringSoon);
      expect(repo.summaryCalls, hasLength(1));
      await cubit.close();
    });

    test('silent refresh keeps the numbers when the server fails', () async {
      final repo = FakeDashboardRepository();
      final cubit = DashboardCubit(repo);
      await cubit.load();
      repo
        ..summaryResult = const ApiFailure(offline)
        ..expiringResult = const ApiFailure(offline);
      await cubit.refresh();
      expect(cubit.state.summary.data, ownerData);
      expect(cubit.state.expiring.data, expiringSoon);
      await cubit.close();
    });

    test('first load failure surfaces for the retry screen', () async {
      final cubit = DashboardCubit(FakeDashboardRepository(summary: const ApiFailure(offline)));
      await cubit.load();
      expect(cubit.state.summary.hasData, isFalse);
      expect(cubit.state.summary.failure, offline);
      await cubit.close();
    });
  });
}
