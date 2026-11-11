import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../domain/models/training_models.dart';
import '../../domain/models/workout_draft.dart';
import '../bloc/workout_editor_cubit.dart';
import 'workout_actions.dart';
import 'workout_day_card.dart';
import 'workout_editor_fields.dart';

/// محرر الخطة (`Training.html`): الرأس والأفعال، الحقول، الأيام بتمارينها، ثم "+ يوم" و "حفظ الخطة".
/// الاستقبال يرى الخطة نفسها للقراءة فقط (بلا أزرار).
class WorkoutEditor extends StatelessWidget {
  const WorkoutEditor({
    super.key,
    required this.draft,
    required this.editable,
    required this.onSaved,
    required this.onDeleted,
    required this.onAssigned,
    this.byPlayer = false,
  });

  final WorkoutDraft draft;
  final bool editable, byPlayer;
  final ValueChanged<WorkoutPlan> onSaved, onAssigned;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) =>
      BlocProvider(create: (_) => WorkoutEditorCubit(sl(), draft), child: _Body(this));
}

class _Body extends StatelessWidget {
  const _Body(this.w);

  final WorkoutEditor w;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final cubit = context.read<WorkoutEditorCubit>();
    final state = context.watch<WorkoutEditorCubit>().state;
    final d = state.draft;
    final editable = w.editable && !state.saving;
    return CutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.s4,
        children: [
          _Header(w: w),
          if (w.byPlayer) const _Note('أضافها العضو من تطبيقه؛ تعديلها من هنا يظهر له.', tone: UTone.info),
          WorkoutEditorFields(editable: editable),
          for (final (i, day) in d.days.indexed)
            WorkoutDayCard(key: ValueKey('day-${day.uid}'), day: day, index: i, editable: editable),
          if (state.error('days') case final e?) Text(e, style: UType.caption(color: c.dangerInk)),
          if (state.failure case final f?) _Note(f.message, tone: UTone.danger),
          if (w.editable)
            Wrap(
              spacing: AppSpace.s3,
              runSpacing: AppSpace.s2,
              alignment: WrapAlignment.spaceBetween,
              children: [
                UGButton(
                  label: 'يوم',
                  icon: Icons.add_rounded,
                  kind: UButtonKind.secondary,
                  onPressed: editable && d.days.length < WorkoutDraft.maxDays ? cubit.addDay : null,
                ),
                UGButton(
                  label: state.saving ? 'جارٍ الحفظ…' : 'حفظ الخطة',
                  icon: Icons.check_rounded,
                  onPressed: editable
                      ? () async {
                          final saved = await cubit.save();
                          if (saved == null || !context.mounted) return;
                          AppSnackbar.show('تم حفظ الخطة.');
                          w.onSaved(saved);
                        }
                      : null,
                ),
              ],
            ),
          Text(
            'القالب العام خطة بلا عضو محدد؛ الخطة المرتبطة بعضو تخصه وحده وتظهر بتطبيقه.',
            style: UType.caption(color: c.inkMuted),
          ),
        ],
      ),
    );
  }
}

/// العنوان والشارات، وللخطة المحفوظة (للمالك): "إسناد لعضو" وحذف.
class _Header extends StatelessWidget {
  const _Header({required this.w});

  final WorkoutEditor w;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final d = w.draft;
    final title = d.isNew ? (d.memberPlan ? 'خطة جديدة لعضو' : 'قالب جديد') : d.title;
    return Wrap(
      spacing: AppSpace.s3,
      runSpacing: AppSpace.s2,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: [
        Wrap(
          spacing: AppSpace.s2,
          runSpacing: AppSpace.s1,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Semantics(
              header: true,
              child: Text(title, style: UType.h2(color: c.ink)),
            ),
            if (!d.isNew && d.isTemplate) const StatusBadge('قالب عام', tone: UTone.accent),
            if (d.status == 'archived') const StatusBadge('مؤرشفة', tone: UTone.neutral),
          ],
        ),
        if (w.editable && !d.isNew)
          Wrap(
            spacing: AppSpace.s2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              UGButton(
                label: 'إسناد لعضو',
                icon: Icons.person_add_alt_1_rounded,
                kind: UButtonKind.secondary,
                onPressed: () async {
                  final copy = await WorkoutActions.assign(context, d);
                  if (copy != null) w.onAssigned(copy);
                },
              ),
              IconButton(
                tooltip: 'حذف الخطة',
                color: c.dangerInk,
                onPressed: () async {
                  if (await WorkoutActions.delete(context, d)) w.onDeleted();
                },
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text, {required this.tone});

  final String text;
  final UTone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = tone.colors(context.colors);
    return Semantics(
      liveRegion: tone == UTone.danger,
      child: DecoratedBox(
        decoration: BoxDecoration(color: bg, borderRadius: AppRadius.smAll),
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.s3),
          child: Text(text, style: UType.body(color: fg)),
        ),
      ),
    );
  }
}
