import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../domain/models/workout_draft.dart';
import '../bloc/workout_editor_cubit.dart';

/// يوم بالمحرر (`.day`): شارة "اليوم N"، العنوان، "حذف اليوم"، والتمارين؛ صفوف بأعمدة من `AppSize.exerciseRowMin`،
/// وأضيق بطاقة لكل تمرين. `index` ترتيب اليوم (مفاتيح الأخطاء `days.{index}...`).
class WorkoutDayCard extends StatelessWidget {
  const WorkoutDayCard({super.key, required this.day, required this.index, required this.editable});

  final DayDraft day;
  final int index;
  final bool editable;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final cubit = context.read<WorkoutEditorCubit>();
    final state = context.watch<WorkoutEditorCubit>().state;
    final canRemoveDay = editable && state.draft.days.length > 1;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: c.line),
        borderRadius: AppRadius.fieldAll,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.s3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpace.s3,
          children: [
            Wrap(
              spacing: AppSpace.s3,
              runSpacing: AppSpace.s2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                StatusBadge('اليوم ${index + 1}', tone: UTone.primary),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: AppSize.staffListWidth),
                  child: DraftField(
                    key: ValueKey('day-${day.uid}-title'),
                    value: day.title,
                    semanticsLabel: 'عنوان اليوم ${index + 1}',
                    hint: 'عنوان اليوم (صدر وترايسبس)',
                    error: state.error('days.$index.title'),
                    enabled: editable,
                    onChanged: (v) => cubit.setDayTitle(day.uid, v),
                  ),
                ),
                if (canRemoveDay)
                  TextButton.icon(
                    onPressed: () => cubit.removeDay(day.uid),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('حذف اليوم'),
                    style: TextButton.styleFrom(foregroundColor: c.inkMuted),
                  ),
              ],
            ),
            if (state.error('days.$index.exercises') case final e?) Text(e, style: UType.caption(color: c.dangerInk)),
            LayoutBuilder(
              builder: (context, box) {
                final wide = box.maxWidth >= AppSize.exerciseRowMin;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppSpace.s2,
                  children: [
                    if (wide) const _Header(),
                    for (final (j, e) in day.exercises.indexed)
                      _ExerciseRow(
                        key: ValueKey('ex-${e.uid}'),
                        day: day,
                        exercise: e,
                        path: 'days.$index.exercises.$j',
                        wide: wide,
                        editable: editable,
                        canRemove: editable && day.exercises.length > 1,
                      ),
                  ],
                );
              },
            ),
            if (editable && day.exercises.length < WorkoutDraft.maxExercises)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: () => cubit.addExercise(day.uid),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('تمرين'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// أعمدة التمرين: الاسم والمجموعات والتكرار والراحة والملاحظة (بالنسب نفسها بالرأس والصفوف).
/// بلا تلميح بالحقول الرقمية: الفارغ من الخادم كان يبدو قيمة.
const _flex = (name: 3, sets: 1, reps: 1, rest: 1, notes: 3);

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final s = UType.label(color: context.colors.inkMuted);
    return ExcludeSemantics(
      child: Row(
        spacing: AppSpace.s2,
        children: [
          Expanded(
            flex: _flex.name,
            child: Text('التمرين', style: s),
          ),
          Expanded(
            flex: _flex.sets,
            child: Text('المجموعات', style: s),
          ),
          Expanded(
            flex: _flex.reps,
            child: Text('التكرار', style: s),
          ),
          Expanded(
            flex: _flex.rest,
            child: Text('راحة (ث)', style: s),
          ),
          Expanded(
            flex: _flex.notes,
            child: Text('ملاحظة', style: s),
          ),
          const SizedBox(width: AppSize.exerciseDeleteCol),
        ],
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({
    super.key,
    required this.day,
    required this.exercise,
    required this.path,
    required this.wide,
    required this.editable,
    required this.canRemove,
  });

  final DayDraft day;
  final ExerciseDraft exercise;
  final String path;
  final bool wide, editable, canRemove;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<WorkoutEditorCubit>();
    final state = context.watch<WorkoutEditorCubit>().state;
    final e = exercise;
    Widget field(String key, String value, String label, {bool numeric = false, String? hint}) => DraftField(
      key: ValueKey('ex-${e.uid}-$key'),
      value: value,
      label: wide ? null : label,
      semanticsLabel: label,
      hint: hint,
      ltr: numeric,
      digits: numeric,
      error: state.error('$path.$key'),
      enabled: editable,
      onChanged: (v) => cubit.setExercise(day.uid, e.uid, key, v),
    );
    final name = field('name', e.name, 'التمرين', hint: 'بنش برس');
    final sets = field('sets', e.sets, 'المجموعات', numeric: true);
    final reps = field('reps', e.reps, 'التكرار', numeric: true);
    final rest = field('rest_seconds', e.rest, 'راحة (ث)', numeric: true);
    final notes = field('notes', e.notes, 'ملاحظة');
    final remove = SizedBox(
      width: AppSize.exerciseDeleteCol,
      child: canRemove
          ? IconButton(
              tooltip: 'حذف التمرين',
              onPressed: () => cubit.removeExercise(day.uid, e.uid),
              icon: const Icon(Icons.close_rounded),
            )
          : null,
    );
    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpace.s2,
        children: [
          Expanded(flex: _flex.name, child: name),
          Expanded(flex: _flex.sets, child: sets),
          Expanded(flex: _flex.reps, child: reps),
          Expanded(flex: _flex.rest, child: rest),
          Expanded(flex: _flex.notes, child: notes),
          remove,
        ],
      );
    }
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(color: c.surfaceAlt, borderRadius: AppRadius.smAll),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.s2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpace.s2,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: name),
                remove,
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpace.s2,
              children: [
                Expanded(child: sets),
                Expanded(child: reps),
                Expanded(child: rest),
              ],
            ),
            notes,
          ],
        ),
      ),
    );
  }
}
