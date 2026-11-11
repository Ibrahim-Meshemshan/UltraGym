import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_gym_admin/core/error/failure.dart';
import 'package:ultra_gym_admin/core/networking/api_result.dart';
import 'package:ultra_gym_admin/features/cash_sessions/domain/models/cash_session_models.dart';
import 'package:ultra_gym_admin/features/cash_sessions/presentation/bloc/cash_sessions_cubit.dart';

import 'fake_cash_sessions_repository.dart';

void main() {
  group('models', () {
    test('open session: live totals, expected now, breakdown and its count', () {
      final s = CashSession.fromJson(sessionJson(withBreakdown: true));
      expect((s.isOpen, s.id, s.branchId, s.branchName), (true, 1, 1, 'الفرع الرئيسي - المزة'));
      expect((s.openingUsd, s.openingSyp, s.expectedUsd), (50.0, 500000.0, null));
      expect((s.expectedUsdNow, s.expectedSypNow), (436.5, 286000.0));
      expect((s.totals!.inUsd, s.totals!.outSyp), (391.5, 450000.0));
      expect(s.breakdown.map((l) => (l.label, l.currency, l.isIn, l.count)), [
        ('دفعة اشتراك', 'USD', true, 14),
        ('مصروف', 'SYP', false, 1),
      ]);
      expect(s.transactionsCount, 15);
      expect(s.businessDate, DateTime(2026, 11, 10));
    });

    test('closed session from the list: fixed expected, count, difference, no totals', () {
      final s = CashSession.fromJson(sessionJson(status: 'closed', differenceUsd: -5));
      expect((s.isOpen, s.totals, s.closedBy), (false, null, 'ريم العلي'));
      expect((s.expectedUsdNow, s.closingUsd, s.differenceUsd, s.differenceSyp), (436.5, 431.5, -5.0, 0.0));
    });

    test('current: open box or closed with the suggested opening', () {
      final open = CashBox.fromJson(boxJson(1));
      expect((open.isOpen, open.branchId, open.session?.id), (true, 1, 1));
      final closed = CashBox.fromJson(boxJson(2, open: false));
      expect((closed.isOpen, closed.branchName, closed.suggestedUsd, closed.suggestedSyp), (
        false,
        'فرع المالكي',
        75.0,
        325000.0,
      ));
    });

    test('labels: feminine status and difference words', () {
      expect(CashSessionLabels.status('open').text, 'مفتوحة');
      expect(CashSessionLabels.status('closed').text, 'مغلقة');
      expect([-3, 0, null, 5].map(CashSessionLabels.difference), ['عجز', 'مطابق', 'مطابق', 'زيادة']);
    });
  });

  test('query from the link: dates, branch, with difference only', () {
    final q = cashHistoryQueryFrom({'from': '2026-11-01', 'branch_id': '2', 'with_difference': '1', 'x': 'y'});
    expect(q.filters, {'from': DateTime(2026, 11), 'branch_id': 2, 'with_difference': true});
    expect(cashHistoryQueryFrom({'with_difference': '0'}).filters, isEmpty);
  });

  group('CashBoxCubit', () {
    test('an open box brings its detail for the breakdown', () async {
      final repo = FakeCashSessionsRepository();
      final cubit = CashBoxCubit(repo, 1);
      addTearDown(cubit.close);
      await cubit.load();
      expect(repo.currentCalls, [1]);
      expect(repo.details, [1]);
      expect(cubit.state.data?.session?.breakdown, hasLength(2));
    });

    test('a closed box asks nothing more; a failed detail keeps the live totals', () async {
      final repo = FakeCashSessionsRepository();
      final closed = CashBoxCubit(repo, 2);
      addTearDown(closed.close);
      await closed.load();
      expect(closed.state.data?.isOpen, isFalse);
      expect(repo.details, isEmpty);

      repo.detailFor = (_) => const ApiFailure(Failure(type: FailureType.network, message: 'لا اتصال'));
      final open = CashBoxCubit(repo, 1);
      addTearDown(open.close);
      await open.load();
      expect(open.state.data?.session?.totals?.expectedUsd, 436.5);
      expect(open.state.data?.session?.breakdown, isEmpty);
    });
  });

  test('history asks for closed sessions with the top-bar branch', () async {
    final repo = FakeCashSessionsRepository();
    final list = CashHistoryCubit(repo, (branchId: 2, query: cashHistoryQueryFrom({'with_difference': '1'})));
    addTearDown(list.close);
    await list.load();
    final q = repo.queries.single;
    expect((q.branchId, q.status, q.query.filter('with_difference')), (2, 'closed', true));
    await list.clearFilters();
    expect(repo.queries.last.status, 'closed', reason: 'clearing filters keeps the status');
  });
}
