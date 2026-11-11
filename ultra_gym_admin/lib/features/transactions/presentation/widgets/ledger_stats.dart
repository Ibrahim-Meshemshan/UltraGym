import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../domain/models/transaction_models.dart';
import '../bloc/transactions_cubit.dart';

/// أرقام الدفتر للفلتر الحالي (`meta.totals`، بالدولار المكافئ بسعر يوم كل حركة): الداخل، الخارج، الصافي، العدد.
class LedgerStats extends StatelessWidget {
  const LedgerStats({super.key});

  @override
  Widget build(BuildContext context) {
    final slice = context.select<LedgerCubit, Slice<Paged<LedgerEntry>>>((l) => l.state.slice);
    if (slice.isFirstLoad) return const StatsShimmer();
    final page = slice.data;
    final t = ledgerTotalsOf(page);
    if (page == null || t == null) return const SizedBox.shrink();
    return ResponsiveGrid(
      children: [
        AppStatCard(
          icon: Icons.south_west_rounded,
          label: 'الداخل · بالدولار المكافئ',
          value: t.inUsd,
          prefix: r'$',
          decimals: 2,
        ),
        AppStatCard(
          icon: Icons.north_east_rounded,
          label: 'الخارج · بالدولار المكافئ',
          value: t.outUsd,
          prefix: r'$',
          decimals: 2,
        ),
        AppStatCard(
          icon: Icons.account_balance_wallet_outlined,
          label: 'الصافي',
          value: t.netUsd.abs(),
          prefix: t.netUsd < 0 ? r'-$' : r'$',
          decimals: 2,
        ),
        AppStatCard(
          icon: Icons.receipt_long_outlined,
          label: 'عدد الحركات',
          value: page.pagination.total.toDouble(),
          note: 'للفترة والفلاتر المعروضة',
        ),
      ],
    );
  }
}
