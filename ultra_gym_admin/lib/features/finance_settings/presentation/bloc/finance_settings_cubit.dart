import '../../../../core/core.dart';
import '../../../transactions/domain/models/transaction_models.dart';
import '../../data/repo/finance_settings_repository.dart';
import '../../domain/models/finance_settings_models.dart';

/// سجل سعر الصرف (10 بالصفحة) والسعر الحالي بـ `meta.current`.
class ExchangeRatesCubit extends ListCubit<ExchangeRateEntry> {
  ExchangeRatesCubit(FinanceSettingsRepository repo)
    : super((q) => repo.rates(q), query: const ListQuery(perPage: 10));
}

/// كل التصنيفات بنوعيها (صفحة التصنيفات).
class FinanceCategoriesCubit extends LoadCubit<List<FinanceCategory>> {
  FinanceCategoriesCubit(FinanceSettingsRepository repo) : super(repo.categories);
}
