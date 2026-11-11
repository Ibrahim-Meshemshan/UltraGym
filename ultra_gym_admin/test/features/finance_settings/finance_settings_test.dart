import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_gym_admin/core/networking/api_result.dart';
import 'package:ultra_gym_admin/features/finance_settings/domain/models/finance_settings_models.dart';
import 'package:ultra_gym_admin/features/finance_settings/presentation/bloc/finance_settings_cubit.dart';
import 'package:ultra_gym_admin/features/transactions/domain/models/transaction_models.dart';

import 'fake_finance_settings_repository.dart';

void main() {
  group('models', () {
    test('a history row reads the server shape', () {
      final r = ExchangeRateEntry.fromJson(rateJson(3, 13000, note: 'سعر السوق'));
      expect(r.id, 3);
      expect(r.sypPerUsd, 13000);
      expect(r.note, 'سعر السوق');
      expect(r.createdBy, 'سامر الحلبي');
      expect(r.createdAt, DateTime.utc(2026, 9, 27, 9));
    });

    test('the current rate comes from meta.current, and a null rate is "not set"', () {
      final set = currentRateOf(ratesPage());
      expect(set.isSet, isTrue);
      expect(set.sypPerUsd, 13000);
      expect(set.updatedAt, DateTime.utc(2026, 9, 27, 9));

      final unset = currentRateOf(
        ratesPage(
          rows: const [],
          meta: const {
            'current': {'syp_per_usd': null, 'updated_at': null},
          },
        ),
      );
      expect(unset.isSet, isFalse);
      expect(currentRateOf(null).isSet, isFalse);
    });

    test('rateChange compares with the next older row, and the last row has none', () {
      final rows = [for (final j in rateRows()) ExchangeRateEntry.fromJson(j)];
      expect(rateChange(rows, 0), 500);
      expect(rateChange(rows, 1), -300);
      expect(rateChange(rows, 2), isNull);
    });

    test('a category carries its usage count and status', () {
      final c = FinanceCategory.fromJson(settingsCategoriesJson[2]);
      expect(c.name, 'ضيافة');
      expect(c.active, isFalse);
      expect(c.transactionsCount, 0);
      expect(c.isIncome, isFalse);
      expect(FinanceCategory.fromJson(settingsCategoriesJson[3]).isIncome, isTrue);
    });
  });

  group('cubits', () {
    test('rates load 10 per page', () async {
      final repo = FakeFinanceSettingsRepository();
      final cubit = ExchangeRatesCubit(repo);
      addTearDown(cubit.close);
      await cubit.load();
      expect(repo.rateQueries.single.perPage, 10);
      expect(cubit.state.slice.data!.items, hasLength(3));
    });

    test('categories load once and refresh silently', () async {
      final repo = FakeFinanceSettingsRepository();
      final cubit = FinanceCategoriesCubit(repo);
      addTearDown(cubit.close);
      await cubit.load();
      expect(cubit.state.data, hasLength(4));
      repo.categoriesResult = const ApiSuccess([]);
      await cubit.refresh();
      expect(cubit.state.data, isEmpty);
      expect(repo.categoryCalls, 2);
    });
  });
}
