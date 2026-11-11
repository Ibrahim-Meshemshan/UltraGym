import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../../core/layout/reception_shell.dart';
import '../../domain/models/station_models.dart';
import '../bloc/active_branch_cubit.dart';
import '../bloc/station_bloc.dart';
import '../widgets/outcome_panel.dart';
import '../widgets/station_input_bar.dart';
import '../widgets/today_card.dart';

/// محطة الدخول (`Reception.html`): الحقل الدائم التركيز وزر الكاميرا، بطاقة النتيجة، و "دخول اليوم".
/// تتبع فرع المحطة من `ActiveBranchCubit` (الشريط العلوي يغيّره).
class StationScreen extends StatelessWidget {
  const StationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final branches = sl<ActiveBranchCubit>();
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: branches),
        BlocProvider(create: (_) => sl<StationBloc>()),
      ],
      child: OnInit(
        // كل فتح بعد الدخول يعيد قائمة الفروع (قد يكون موظفاً آخر)، والمحطة تبدأ بعد وصولها فقط.
        onInit: (_) => branches.load(),
        child: BlocListener<ActiveBranchCubit, ActiveBranchState>(
          listenWhen: (a, b) =>
              b.branches.isSuccess && b.selectedId != null && (a.selectedId != b.selectedId || !a.branches.isSuccess),
          listener: (context, s) => context.read<StationBloc>().add(StationBranchChanged(s.selectedId!)),
          child: const ReceptionShell(child: _Body()),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final branches = context.select<ActiveBranchCubit, Slice<List<StationBranch>>>((c) => c.state.branches);
    return SliceView<List<StationBranch>>(
      slice: branches,
      loading: Padding(padding: context.pagePadding, child: const DetailsShimmer()),
      onRetry: () => context.read<ActiveBranchCubit>().load(),
      isEmpty: (l) => l.isEmpty,
      empty: const Center(
        child: AppEmptyState(
          icon: Icons.store_mall_directory_rounded,
          title: 'لا فرع لحسابك',
          message: 'اطلب من مالك النادي ربط حسابك بفرع من قسم الموظفين، ثم ادخل من جديد.',
        ),
      ),
      builder: (context, _) => LayoutBuilder(
        builder: (context, box) {
          final wide = box.maxWidth >= Breakpoints.tablet;
          const main = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpace.s4,
            children: [StationInputBar(), OutcomePanel()],
          );
          // SliceView يضع المحتوى بوسط مكانه: الصفحة تملأ المكان وتبدأ من الأعلى.
          return SizedBox.expand(
            child: SingleChildScrollView(
              padding: context.pagePadding,
              child: Align(
                alignment: AlignmentDirectional.topStart,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: AppSize.maxContent),
                  child: wide
                      ? const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: AppSpace.s4,
                          children: [
                            Expanded(child: main),
                            SizedBox(width: AppSize.sideColumn, child: TodayCard()),
                          ],
                        )
                      : const Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: AppSpace.s4,
                          children: [main, TodayCard()],
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
