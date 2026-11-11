import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_gym_admin/core/networking/api_result.dart';
import 'package:ultra_gym_admin/core/networking/list_query.dart';
import 'package:ultra_gym_admin/features/transactions/domain/models/transaction_models.dart';
import 'package:ultra_gym_admin/features/transactions/presentation/bloc/transactions_cubit.dart';
import 'package:ultragym_design/ultragym_design.dart';

import 'fake_transactions_repository.dart';

void main() {
  group('models', () {
    test('a payment: player, membership, amounts and session from the real payload', () {
      final e = LedgerEntry.fromJson(ledgerRows().first);
      expect((e.id, e.receiptNumber, e.type, e.typeLabel), (29, 'B1-2026-000029', 'membership_payment', 'دفعة اشتراك'));
      expect((e.isIn, e.currency, e.amount, e.amountUsd, e.exchangeRate), (true, 'USD', 30.0, 30.0, 13000.0));
      expect((e.playerId, e.playerName, e.membershipId, e.cashSessionId), (6, 'خالد يوسف', 17, 1));
      expect((e.branchId, e.branchName, e.categoryName), (1, 'الفرع الرئيسي - المزة', null));
      expect(
        (e.businessDate, e.occurredAt, e.createdBy),
        (DateTime(2026, 11, 9), DateTime.utc(2026, 11, 9, 16), 'سامر الحلبي'),
      );
      expect(e.canReverse, isTrue);
    });

    test('a reversal and a reversed entry cannot be reversed again', () {
      final rows = [for (final j in ledgerRows()) LedgerEntry.fromJson(j)];
      final reversal = rows.firstWhere((e) => e.isReversal);
      final reversed = rows.firstWhere((e) => e.isReversed);
      expect((reversal.canReverse, reversal.reversalOfId, reversal.isIn), (false, 24, false));
      expect((reversed.canReverse, reversed.reversedAt), (false, DateTime.utc(2026, 11, 9, 19, 34, 39)));
    });

    test('detail extras, totals, reversal result and categories', () {
      final d = LedgerEntry.fromJson({
        ...txJson(id: 24, reversed: true),
        'reversed_by_transaction': {'id': 25, 'receipt_number': 'B1-2026-000025'},
        'amount_syp_equivalent': 65000,
      });
      expect((d.reversedByReceipt, d.amountSypEquivalent), ('B1-2026-000025', 65000.0));
      expect(LedgerTotals.fromJson(const {'in_usd': 481, 'out_usd': 39.62, 'net_usd': 441.38}).netUsd, 441.38);
      final r = LedgerReversal.fromJson({
        'original': txJson(reversed: true),
        'reversal': txJson(id: 41, type: 'reversal'),
      });
      expect((r.original.isReversed, r.reversal.id, r.reversal.isReversal), (true, 41, true));
      final c = FinanceCategory.fromJson(categoriesJson.last);
      expect((c.id, c.kind, c.name, c.active), (4, 'income', 'بيع مكملات', true));
    });

    test('missing fields do not throw', () {
      final e = LedgerEntry.fromJson(const {'id': 1});
      expect((e.receiptNumber, e.typeLabel, e.direction, e.currency, e.amount), ('—', '—', 'in', 'USD', 0.0));
      expect((e.playerName, e.businessDate, e.canReverse), (null, null, true));
    });

    test('type tones follow the prototype; salaries are owner-only options', () {
      expect(TransactionLabels.tone('membership_payment'), UTone.success);
      expect(TransactionLabels.tone('income'), UTone.accent);
      expect(TransactionLabels.tone('expense'), UTone.danger);
      expect(TransactionLabels.tone('membership_refund'), UTone.warning);
      expect(TransactionLabels.tone('salary'), UTone.info);
      expect(TransactionLabels.tone('reversal'), UTone.neutral);
      expect(TransactionFilters.types(finance: true).map((o) => o.value), contains('salary'));
      expect(TransactionFilters.types(finance: false).map((o) => o.value), isNot(contains('advance')));
    });
  });

  test('link filters: known values only', () {
    final q = ledgerQueryFrom(const {
      'type': 'expense',
      'currency': 'SYP',
      'from': '2026-11-01',
      'to': '2026-11-09',
      'branch_id': '2',
      'include_reversed': '0',
      'search': ' B1-2026 ',
    });
    expect(q.filter('type'), 'expense');
    expect(q.filter('currency'), 'SYP');
    expect((q.filter('from'), q.filter('to')), (DateTime(2026, 11), DateTime(2026, 11, 9)));
    expect((q.filter('branch_id'), q.filter('include_reversed'), q.search), (2, false, 'B1-2026'));
    final bad = ledgerQueryFrom(const {'type': 'gift', 'currency': 'EUR', 'from': 'x', 'include_reversed': '1'});
    expect(bad.filters, isEmpty);
  });

  group('cubits', () {
    test('ledger: branch with every request, totals from meta, filters kept', () async {
      final repo = FakeTransactionsRepository();
      final cubit = LedgerCubit(repo, (branchId: 2, query: const ListQuery().withFilter('type', 'expense')));
      await cubit.load();
      expect((repo.queries.single.branchId, repo.queries.single.query.filter('type')), (2, 'expense'));
      final t = ledgerTotalsOf(cubit.state.slice.data);
      expect((t?.inUsd, t?.outUsd, t?.netUsd), (481.0, 39.62, 441.38));
      expect(cubit.state.slice.data?.items, hasLength(5));
      await cubit.goTo(2);
      expect((repo.queries.last.query.page, repo.queries.last.branchId), (2, 2));
      await cubit.close();
    });

    test('totals are null when the server sends none', () {
      expect(ledgerTotalsOf(null), isNull);
    });

    test('entry detail', () async {
      final repo = FakeTransactionsRepository();
      final cubit = LedgerEntryCubit(repo, 24);
      await cubit.load();
      expect(repo.details, [24]);
      expect(cubit.state.data?.reversedByReceipt, 'B1-2026-000025');
      expect(cubit.state.data, isA<LedgerEntry>());
      expect(repo.listResult, isA<ApiSuccess<Object?>>());
      await cubit.close();
    });
  });
}
