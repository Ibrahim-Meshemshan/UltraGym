import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_gym_admin/features/day_passes/domain/models/day_pass_models.dart';
import 'package:ultra_gym_admin/features/day_passes/presentation/bloc/day_passes_cubit.dart';

import '../quick_search/fake_quick_search_repository.dart';
import 'fake_day_passes_repository.dart';

void main() {
  group('models', () {
    test('day pass from the contract: visitor, price, payment with receipt', () {
      final p = DayPass.fromJson(dayPassJson());
      expect((p.isVisitor, p.name, p.phone, p.priceUsd, p.isFree), (true, 'خالد الأحمد', '+963933556677', 5.0, false));
      expect(p.transactions.single.receiptNumber, 'B1-2026-000007');
      expect(p.businessDate, DateTime(2026, 11, 9));
      final member = DayPass.fromJson(dayPassJson(kind: 'player', name: 'رامي العمر'));
      expect((member.isVisitor, member.playerId), (false, 7));
      final cancelled = DayPass.fromJson(dayPassJson(status: 'cancelled'));
      expect((cancelled.isCancelled, cancelled.cancellationReason), (true, 'سُجّل بالخطأ'));
    });

    test('price as the server sends it: no price yet means only the owner can sell', () {
      final none = DayPassPrice.fromJson(priceJson(price: null, gender: true, branch: 2));
      expect((none.hasPrice, none.canSell, none.genderRequired, none.branchName), (false, true, true, 'فرع المالكي'));
      expect(DayPassPrice.fromJson(priceJson(price: null, canChange: false)).canSell, isFalse);
      expect(DayPassPrice.fromJson(priceJson(enabled: false)).canSell, isFalse);
      expect(DayPassPrice.fromJson(priceJson()).priceSyp, 65000);
    });

    test('summary from meta', () {
      final s = DayPassSummary.fromJson(const {'count': 3, 'visitors': 2, 'players': 1, 'revenue_usd': 10});
      expect((s.count, s.visitors, s.players, s.revenueUsd), (3, 2, 1, 10.0));
    });
  });

  test('query from the link: known values only', () {
    final q = dayPassesQueryFrom({
      'kind': 'visitor',
      'status': 'gone',
      'from': '2026-11-01',
      'branch_id': '2',
      'search': ' خالد ',
    });
    expect(q.filters, {'kind': 'visitor', 'from': DateTime(2026, 11), 'branch_id': 2});
    expect(q.search, 'خالد');
  });

  group('DayPassSaleCubit', () {
    test('a stale price (branch changed meanwhile) is ignored', () async {
      final repo = FakeDayPassesRepository();
      final cubit = DayPassSaleCubit(repo);
      addTearDown(cubit.close);
      final gate = Completer<void>();
      repo.holdPrice = gate;
      final first = cubit.loadPrice(1);
      repo.holdPrice = null;
      await cubit.loadPrice(2);
      gate.complete();
      await first;
      expect(cubit.state.price.data?.branchId, 2);
    });

    test('picking a member switches the buyer; another sale keeps the price with a new key', () async {
      final cubit = DayPassSaleCubit(FakeDayPassesRepository());
      addTearDown(cubit.close);
      await cubit.loadPrice(1);
      cubit.pick(ahmad);
      expect((cubit.state.buyer, cubit.state.player), (DayPassBuyer.member, ahmad));
      final key = cubit.keyFor({'player_id': 3});
      cubit.done(DayPass.fromJson(dayPassJson()));
      expect(cubit.state.sold, isTrue);
      cubit.again();
      expect((cubit.state.result, cubit.state.player, cubit.state.sold), (null, null, true));
      expect(cubit.state.price.data?.priceUsd, 5);
      expect(cubit.keyFor({'player_id': 3}), isNot(key));
    });
  });

  test('list cubit asks with the branch', () async {
    final repo = FakeDayPassesRepository();
    final list = DayPassesListCubit(repo, (branchId: 2, query: dayPassesQueryFrom({'kind': 'player'})));
    addTearDown(list.close);
    await list.load();
    expect(repo.queries.single.branchId, 2);
    expect(repo.queries.single.query.filter('kind'), 'player');
    expect(list.state.slice.data?.items, hasLength(3));
  });
}
