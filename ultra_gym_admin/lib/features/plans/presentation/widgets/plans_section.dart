import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../domain/models/plans_models.dart';
import '../bloc/plans_cubit.dart';
import 'plan_actions.dart';
import 'plan_card.dart';

/// بطاقات الخطط (`Plans.html`): الملاحظة و "خطة جديدة" (للمالك)، ثم شبكة البطاقات وصفحاتها.
/// `archived` = الأرشيف (استرجاع فقط).
class PlansSection extends StatelessWidget {
  const PlansSection({super.key, required this.owner, this.archived = false});

  final bool owner, archived;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => sl<PlansListCubit>(param1: archived)..load(),
    child: _Body(owner: owner, archived: archived),
  );
}

class _Body extends StatelessWidget {
  const _Body({required this.owner, required this.archived});

  final bool owner, archived;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final list = context.read<PlansListCubit>();
    final slice = context.select<PlansListCubit, Slice<Paged<Plan>>>((l) => l.state.slice);
    Future<void> after(Future<bool> action) async {
      if (await action) await list.refresh(keepPage: true);
    }

    final add = owner && !archived ? () => after(PlanActions.save(context)) : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.s4,
      children: [
        Row(
          spacing: AppSpace.s3,
          children: [
            Expanded(
              child: Text(
                archived
                    ? 'الخطط المؤرشفة لا تظهر بالبيع. استرجعها لتعود موقوفة ثم فعّلها من "تعديل".'
                    : 'تعديل خطة لا يغيّر الاشتراكات المباعة سابقاً؛ كل اشتراك يحفظ نسخة من خطته وقت البيع.',
                style: UType.label(color: c.inkMuted),
              ),
            ),
            if (add != null) UGButton(label: 'خطة جديدة', icon: Icons.add_rounded, onPressed: add),
          ],
        ),
        SliceView<Paged<Plan>>(
          slice: slice,
          onRetry: list.load,
          loading: const _Shimmer(),
          isEmpty: (p) => p.items.isEmpty,
          empty: EmptyState(
            icon: archived ? Icons.archive_outlined : Icons.sell_rounded,
            title: archived ? 'لا خطط بالأرشيف' : 'لا خطط اشتراك بعد',
            message: archived
                ? 'الخطط التي تؤرشفها تظهر هنا.'
                : owner
                ? 'أضف أول خطة (بالمدة أو بعدد الحصص) لتبدأ البيع.'
                : 'اطلب من مالك النادي إضافة خطط الاشتراك.',
            actionLabel: add == null ? null : 'خطة جديدة',
            onAction: add,
          ),
          builder: (context, page) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpace.s4,
            children: [
              ResponsiveGrid(
                minItemWidth: AppSize.planCardMin,
                maxColumns: 3,
                spacing: AppSpace.s4,
                children: [
                  for (final p in page.items)
                    PlanCard(
                      p,
                      archived: archived,
                      onEdit: owner && !archived ? () => after(PlanActions.save(context, plan: p)) : null,
                      onArchive: owner && !archived ? () => after(PlanActions.archive(context, p)) : null,
                      onRestore: owner && archived ? () => after(PlanActions.restore(context, p)) : null,
                    ),
                ],
              ),
              if (page.pagination.lastPage > 1)
                PaginationBar(pagination: page.pagination, onPage: list.goTo, noun: 'خطة'),
            ],
          ),
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
      minItemWidth: AppSize.planCardMin,
      maxColumns: 3,
      spacing: AppSpace.s4,
      children: [
        for (var i = 0; i < 6; i++)
          ShimmerCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpace.s3,
              children: [
                const ShimmerBox(width: 140, height: AppSpace.s5),
                const ShimmerBox(width: 90, height: AppSpace.s8),
                for (var j = 0; j < 3; j++) const ShimmerBox(),
              ],
            ),
          ),
      ],
    ),
  );
}
