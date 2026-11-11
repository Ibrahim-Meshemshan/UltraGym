import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../domain/models/memberships_models.dart';
import '../bloc/memberships_cubit.dart';

/// أرقام الرأس (`.stat` بالنموذج). القريبة والديون تفتح تبويبيهما. الفشل يخفيها ولا يوقف الجدول.
class MembershipStatsRow extends StatelessWidget {
  const MembershipStatsRow({super.key});

  @override
  Widget build(BuildContext context) {
    final slice = context.watch<MembershipStatsCubit>().state;
    final tab = context.read<ValueCubit<MembershipsTab>>();
    if (slice.isFirstLoad) return const StatsShimmer();
    final s = slice.data;
    if (s == null) return const SizedBox.shrink();
    return Semantics(
      container: true,
      label: 'أرقام الاشتراكات',
      child: ResponsiveGrid(
        children: [
          AppStatCard(icon: Icons.card_membership_rounded, label: 'اشتراكات فعّالة', value: s.active.toDouble()),
          AppStatCard(icon: Icons.ac_unit_rounded, label: 'مجمّدة', value: s.frozen.toDouble()),
          AppStatCard(
            icon: Icons.hourglass_bottom_rounded,
            label: 'تنتهي خلال ${MembershipFilters.expiringDays} أيام',
            value: s.expiring.toDouble(),
            noteTone: s.expiring > 0 ? UTone.warning : null,
            note: s.expiring > 0 ? 'ذكّرهم بالتجديد' : 'لا شيء قريب',
            onTap: () => tab.set(MembershipsTab.expiring),
          ),
          AppStatCard(
            icon: Icons.account_balance_wallet_outlined,
            label: 'مجموع الديون',
            value: s.debtUsd,
            prefix: r'$',
            decimals: 2,
            note: s.debtCount == 0
                ? 'كل الاشتراكات مدفوعة'
                : 'على ${Formatters.count(s.debtCount, 'اشتراك واحد', 'اشتراكين', 'اشتراكات', many: 'اشتراكاً')}',
            noteTone: s.debtCount > 0 ? UTone.danger : UTone.success,
            onTap: () => tab.set(MembershipsTab.debts),
          ),
        ],
      ),
    );
  }
}
