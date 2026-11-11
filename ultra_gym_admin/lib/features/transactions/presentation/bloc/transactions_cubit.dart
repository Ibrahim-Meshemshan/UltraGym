import '../../../../core/core.dart';
import '../../data/repo/transactions_repository.dart';
import '../../domain/models/transaction_models.dart';

/// معاملات الدفتر: فرع الشريط العلوي + فلتر أولي من الرابط.
typedef LedgerArgs = ({int? branchId, ListQuery query});

/// الدفتر بفرع الشريط العلوي (المجاميع بـ `meta.totals`). تغيير الفرع ينشئ واحداً جديداً.
class LedgerCubit extends ListCubit<LedgerEntry> {
  LedgerCubit(TransactionsRepository repo, LedgerArgs args)
    : super((q) => repo.list(q, branchId: args.branchId), query: args.query);
}

/// تفاصيل حركة (نافذة التفاصيل).
class LedgerEntryCubit extends LoadCubit<LedgerEntry> {
  LedgerEntryCubit(TransactionsRepository repo, int id) : super(() => repo.detail(id));
}

/// مجاميع الصفحة الحالية من `meta.totals` (تتبع الفلتر، لا الصفحة).
LedgerTotals? ledgerTotalsOf(Paged<LedgerEntry>? page) => switch (page?.meta['totals']) {
  final Map<dynamic, dynamic> t => LedgerTotals.fromJson(asJson(t)),
  _ => null,
};

/// الفلتر الأولي من الرابط: `/cash-sessions/transactions?type=expense&currency=SYP&from=…&to=…&branch_id=2&search=…`.
ListQuery ledgerQueryFrom(Map<String, String> params) {
  var q = const ListQuery();
  if (params[TransactionFilters.type] case final t? when TransactionFilters.allTypes.contains(t)) {
    q = q.withFilter(TransactionFilters.type, t);
  }
  if (params[TransactionFilters.currency] case final c? when c == 'USD' || c == 'SYP') {
    q = q.withFilter(TransactionFilters.currency, c);
  }
  for (final key in const [TransactionFilters.from, TransactionFilters.to]) {
    if (DateTime.tryParse(params[key] ?? '') case final d?) q = q.withFilter(key, DateTime(d.year, d.month, d.day));
  }
  if (int.tryParse(params[TransactionFilters.branchId] ?? '') case final id?) {
    q = q.withFilter(TransactionFilters.branchId, id);
  }
  if (params[TransactionFilters.includeReversed] == '0') q = q.withFilter(TransactionFilters.includeReversed, false);
  if (params['search'] case final s? when s.trim().isNotEmpty) q = q.withSearch(s.trim());
  return q;
}
