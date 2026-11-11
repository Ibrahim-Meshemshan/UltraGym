import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../domain/models/training_models.dart';
import '../bloc/training_cubits.dart';

/// قائمة البرامج (`Training.html` ← "الخطط"): "لأعضاء" / "قوالب عامة"، البحث بالعنوان، و "عرض المزيد".
class WorkoutListCard extends StatelessWidget {
  const WorkoutListCard({
    super.key,
    required this.templates,
    required this.onTemplates,
    required this.selectedId,
    required this.onSelect,
    this.onNew,
  });

  final bool templates;
  final ValueChanged<bool> onTemplates;
  final int? selectedId;
  final ValueChanged<int> onSelect;

  /// "+ خطة" (للمالك فقط).
  final VoidCallback? onNew;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final cubit = context.watch<WorkoutPlansCubit>();
    final state = cubit.state;
    return CutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.s3,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text('الخطط', style: UType.h3(color: c.ink)),
                ),
              ),
              if (onNew != null)
                TextButton.icon(onPressed: onNew, icon: const Icon(Icons.add_rounded), label: const Text('خطة')),
            ],
          ),
          FilterChoiceChips<bool>(
            semanticsLabel: 'نوع الخطط',
            showAll: false,
            options: const [(value: false, label: 'لأعضاء'), (value: true, label: 'قوالب عامة')],
            value: templates,
            onChanged: (v) => onTemplates(v ?? false),
          ),
          SearchField(value: state.query.search, onChanged: cubit.search, hint: 'ابحث بعنوان الخطة'),
          SliceView<Paged<WorkoutPlan>>(
            slice: state.slice,
            onRetry: cubit.load,
            loading: const ListShimmer(count: 4),
            isEmpty: (p) => p.items.isEmpty,
            empty: state.query.search.isNotEmpty
                ? Text('لا خطط بهذا العنوان.', style: UType.label(color: c.inkMuted))
                : EmptyState(
                    icon: Icons.fitness_center_rounded,
                    title: templates ? 'لا قوالب بعد' : 'لا خطط لأعضاء بعد',
                    message: templates
                        ? 'القالب خطة جاهزة بلا عضو، تُسند لأي عضو بنسخة منها.'
                        : 'أنشئ خطة لعضو أو أسند له قالباً جاهزاً، فتظهر بتطبيقه.',
                  ),
            builder: (context, p) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpace.s1,
              children: [
                for (final w in p.items) _Tile(w, selected: w.id == selectedId, onTap: () => onSelect(w.id)),
                if (state.canLoadMore)
                  TextButton(
                    onPressed: state.loadingMore ? null : cubit.more,
                    child: Text(state.loadingMore ? 'جارٍ التحميل…' : 'عرض المزيد'),
                  ),
                if (state.moreFailure case final f?) Text(f.message, style: UType.caption(color: c.dangerInk)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile(this.plan, {required this.selected, required this.onTap});

  final WorkoutPlan plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? c.primarySoft : c.surface,
        borderRadius: AppRadius.fieldAll,
        child: InkWell(
          borderRadius: AppRadius.fieldAll,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSize.minTap),
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.s2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpace.s1,
                children: [
                  Text(
                    plan.title,
                    style: UType.body(color: c.ink).weight(600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(TrainingTexts.subtitle(plan), style: UType.caption(color: c.inkMuted)),
                  if (plan.isArchived || plan.byPlayer)
                    Wrap(
                      spacing: AppSpace.s2,
                      runSpacing: AppSpace.s1,
                      children: [
                        if (plan.isArchived) const StatusBadge('مؤرشفة', tone: UTone.neutral),
                        if (plan.byPlayer) const StatusBadge('أضافها العضو', tone: UTone.info),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
