import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../domain/models/training_models.dart';
import '../../domain/models/workout_draft.dart';
import '../bloc/training_cubits.dart';
import 'workout_editor.dart';
import 'workout_list_card.dart';

/// تبويب "خطط التمارين": القائمة (لأعضاء / قوالب عامة) والمحرر بجانبها من `AppSize.profileSplit`، وأضيق تحتها.
/// المختار بـ `ValueCubit<int?>`: معرّف خطة، أو `newPlan` لخطة جديدة، أو null = أول خطة بالقائمة.
class WorkoutPlansSection extends StatelessWidget {
  const WorkoutPlansSection({super.key, required this.editable});

  final bool editable;

  /// المعرّفات من 1، فالصفر = "خطة جديدة".
  static const newPlan = 0;

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(create: (_) => ValueCubit<bool>(false)),
      BlocProvider(create: (_) => ValueCubit<int?>(null)),
      BlocProvider(create: (_) => sl<TrainersCubit>()..load()),
    ],
    child: BlocBuilder<ValueCubit<bool>, bool>(
      builder: (context, templates) => BlocProvider(
        key: ValueKey(templates),
        create: (_) => sl<WorkoutPlansCubit>(param1: templates)..load(),
        child: _Body(templates: templates, editable: editable),
      ),
    ),
  );
}

class _Body extends StatelessWidget {
  const _Body({required this.templates, required this.editable});

  final bool templates, editable;

  @override
  Widget build(BuildContext context) {
    final list = context.watch<WorkoutPlansCubit>();
    final picked = context.watch<ValueCubit<int?>>().state;
    final items = list.state.slice.data?.items ?? const <WorkoutPlan>[];
    final selectedId = picked ?? items.firstOrNull?.id;
    final pick = context.read<ValueCubit<int?>>();

    void reload(int? select) {
      pick.set(select);
      list.refresh();
    }

    final card = WorkoutListCard(
      templates: templates,
      onTemplates: (v) {
        pick.set(null);
        context.read<ValueCubit<bool>>().set(v);
      },
      selectedId: selectedId,
      onSelect: pick.set,
      onNew: editable ? () => pick.set(WorkoutPlansSection.newPlan) : null,
    );

    Widget editor(WorkoutDraft draft, {bool byPlayer = false}) => WorkoutEditor(
      key: ValueKey('editor-${draft.id ?? 'new-$templates'}'),
      draft: draft,
      editable: editable,
      byPlayer: byPlayer,
      onSaved: (p) => reload(p.id),
      onDeleted: () => reload(null),
      onAssigned: (copy) {
        // النسخة خطة عضو: نعرضها بتبويب "لأعضاء".
        context.read<ValueCubit<bool>>().set(false);
        pick.set(copy.id);
      },
    );

    final Widget? panel = switch (selectedId) {
      WorkoutPlansSection.newPlan => editor(WorkoutDraft.blank(memberPlan: !templates)),
      final int id => BlocProvider(
        key: ValueKey('plan-$id'),
        create: (_) => sl<WorkoutPlanCubit>(param1: id)..load(),
        child: Builder(
          builder: (context) {
            final cubit = context.watch<WorkoutPlanCubit>();
            return SliceView<WorkoutPlan>(
              slice: cubit.state,
              onRetry: cubit.load,
              loading: const DetailsShimmer(),
              builder: (context, p) => editor(WorkoutDraft.of(p), byPlayer: p.byPlayer),
            );
          },
        ),
      ),
      null => null,
    };

    return LayoutBuilder(
      builder: (context, box) {
        if (box.maxWidth >= AppSize.profileSplit) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpace.s4,
            children: [
              SizedBox(width: AppSize.workoutListWidth, child: card),
              Expanded(child: panel ?? const SizedBox.shrink()),
            ],
          );
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: AppSpace.s4, children: [card, ?panel]);
      },
    );
  }
}
