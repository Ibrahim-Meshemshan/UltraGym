import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../transactions/presentation/widgets/finance_tabs.dart';
import '../../domain/models/finance_settings_models.dart';
import '../bloc/finance_settings_cubit.dart';
import '../widgets/current_rate_card.dart';
import '../widgets/rate_history_table.dart';

/// سعر الصرف (`FinanceSettings.html`، تبويب "سعر الصرف"): السعر المعتمد الآن ونموذج سعر جديد (للمالك)، ثم السجل.
/// الاستقبال يقرأ فقط.
class ExchangeRateScreen extends StatelessWidget {
  const ExchangeRateScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => sl<ExchangeRatesCubit>()..load(),
    child: const _Body(),
  );
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final owner = context.select<AuthBloc, bool>((b) => b.state.session?.isClubOwner ?? false);
    final list = context.read<ExchangeRatesCubit>();
    final slice = context.select<ExchangeRatesCubit, Slice<Paged<ExchangeRateEntry>>>((l) => l.state.slice);
    final page = slice.data;
    final Widget current = slice.isFirstLoad
        ? const AppShimmer(
            child: ShimmerCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpace.s4,
                children: [
                  ShimmerBox(width: 120),
                  ShimmerBox(width: 220, height: AppSpace.s10),
                  ShimmerBox(width: 160, height: AppSpace.s3),
                  ShimmerBox(height: AppSize.control),
                ],
              ),
            ),
          )
        : page == null
        ? const SizedBox.shrink()
        : CurrentRateCard(
            rate: currentRateOf(page),
            // آخر من سجّل: أول سطر بالسجل حين نكون على الصفحة الأولى.
            updatedBy: page.pagination.currentPage == 1 ? page.items.firstOrNull?.createdBy : null,
            owner: owner,
            onSaved: () => list.refresh(),
          );
    return AppPage(
      children: [
        const FinanceTabs(selected: 2),
        LayoutBuilder(
          builder: (context, box) => box.maxWidth >= AppSize.profileSplit
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpace.s5,
                  children: [
                    Expanded(flex: 2, child: current),
                    const Expanded(flex: 3, child: RateHistoryTable()),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppSpace.s5,
                  children: [current, const RateHistoryTable()],
                ),
        ),
      ],
    );
  }
}
