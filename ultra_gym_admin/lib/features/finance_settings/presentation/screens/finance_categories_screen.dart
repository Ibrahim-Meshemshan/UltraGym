import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../transactions/domain/models/transaction_models.dart';
import '../../../transactions/presentation/widgets/finance_tabs.dart';
import '../bloc/finance_settings_cubit.dart';
import '../widgets/category_group_card.dart';

/// التصنيفات (`FinanceSettings.html`، تبويب "التصنيفات"): المصاريف والإيرادات الأخرى بمجموعتين. المالك يضيف
/// ويعدّل ويوقف ويحذف غير المستعمل، والاستقبال يقرأ فقط.
class FinanceCategoriesScreen extends StatelessWidget {
  const FinanceCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => sl<FinanceCategoriesCubit>()..load(),
    child: const _Body(),
  );
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final owner = context.select<AuthBloc, bool>((b) => b.state.session?.isClubOwner ?? false);
    final cubit = context.read<FinanceCategoriesCubit>();
    final slice = context.select<FinanceCategoriesCubit, Slice<List<FinanceCategory>>>((l) => l.state);
    return AppPage(
      children: [
        const FinanceTabs(selected: 3),
        SliceView<List<FinanceCategory>>(
          slice: slice,
          onRetry: cubit.load,
          loading: const _Shimmer(),
          builder: (context, all) => ResponsiveGrid(
            minItemWidth: AppSize.categoryGroupMin,
            maxColumns: 2,
            spacing: AppSpace.s5,
            children: [
              for (final kind in const ['expense', 'income'])
                CategoryGroupCard(kind: kind, owner: owner, items: [...all.where((x) => x.kind == kind)]),
            ],
          ),
        ),
        Text(
          'أوقف التصنيف ليختفي من نموذج تسجيل الحركة ويبقى ظاهراً بالتقارير السابقة.',
          style: UType.caption(color: context.colors.inkMuted),
        ),
      ],
    );
  }
}

class _Shimmer extends StatelessWidget {
  const _Shimmer();

  @override
  Widget build(BuildContext context) => AppShimmer(
    child: ResponsiveGrid(
      minItemWidth: AppSize.categoryGroupMin,
      maxColumns: 2,
      spacing: AppSpace.s5,
      children: [
        for (var g = 0; g < 2; g++)
          ShimmerCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpace.s4,
              children: [
                const ShimmerBox(width: 160, height: AppSpace.s6),
                for (var i = 0; i < 3; i++) const ShimmerBox(height: AppSpace.s8),
              ],
            ),
          ),
      ],
    ),
  );
}
