import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../../quick_search/presentation/widgets/quick_search_button.dart';
import '../../domain/models/training_models.dart';
import '../bloc/training_cubits.dart';
import '../bloc/workout_editor_cubit.dart';

/// رأس المحرر (`Training.html`): العنوان، العضو، المدرب، من، إلى، الحالة، والوصف.
class WorkoutEditorFields extends StatelessWidget {
  const WorkoutEditorFields({super.key, required this.editable});

  final bool editable;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<WorkoutEditorCubit>();
    final state = context.watch<WorkoutEditorCubit>().state;
    final d = state.draft;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.s3,
      children: [
        ResponsiveGrid(
          minItemWidth: AppSize.workoutFieldMin,
          maxColumns: 3,
          children: [
            DraftField(
              key: const ValueKey('workout-title'),
              label: 'عنوان الخطة',
              value: d.title,
              hint: 'تضخيم · 4 أيام',
              error: state.error('title'),
              enabled: editable,
              onChanged: cubit.setTitle,
            ),
            if (!d.isNew || d.memberPlan) _MemberField(editable: editable && d.isNew),
            _TrainerField(editable: editable),
            _DateField(editable: editable, end: false),
            _DateField(editable: editable, end: true),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const FieldLabel('الحالة'),
                FilterChoiceChips<String>(
                  semanticsLabel: 'حالة الخطة',
                  showAll: false,
                  options: const [(value: 'active', label: 'فعّالة'), (value: 'archived', label: 'مؤرشفة')],
                  value: d.status,
                  onChanged: editable ? (v) => cubit.setStatus(v ?? 'active') : (_) {},
                ),
              ],
            ),
          ],
        ),
        DraftField(
          key: const ValueKey('workout-description'),
          label: 'الوصف',
          value: d.description,
          hint: 'اختياري: الهدف وتعليمات عامة للعضو',
          maxLines: 2,
          error: state.error('description'),
          enabled: editable,
          onChanged: cubit.setDescription,
        ),
      ],
    );
  }
}

/// العضو: يُختار بالبحث عند إنشاء خطة لعضو؛ بخطة محفوظة يظهر للقراءة مع رابط ملفه (أو "قالب عام").
class _MemberField extends StatelessWidget {
  const _MemberField({required this.editable});

  final bool editable;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final state = context.watch<WorkoutEditorCubit>().state;
    final player = state.draft.player;
    final error = state.error('player_id');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FieldLabel('العضو'),
        if (editable)
          OutlinedButton.icon(
            onPressed: () async {
              final picked = await QuickSearch.pick(context);
              if (picked == null || !context.mounted) return;
              context.read<WorkoutEditorCubit>().setPlayer((id: picked.id, name: picked.name));
            },
            icon: const Icon(Icons.person_search_rounded),
            label: Text(player?.name ?? 'اختر العضو', maxLines: 1, overflow: TextOverflow.ellipsis),
          )
        else if (player == null)
          Text('قالب عام', style: UType.body(color: c.inkMuted))
        else
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: () => context.go(Routes.child(Routes.members, player.id)),
              child: Text(player.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
        if (error != null) Text(error, style: UType.caption(color: c.dangerInk)),
      ],
    );
  }
}

/// المدرب من المدربين الفعّالين؛ مدرب الخطة إن لم يعد فعّالاً يبقى خياراً باسمه.
class _TrainerField extends StatelessWidget {
  const _TrainerField({required this.editable});

  final bool editable;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<WorkoutEditorCubit>().state;
    final trainers = context.watch<TrainersCubit>().state.data ?? const <TrainingRef>[];
    final current = state.draft.trainer;
    final options = [if (current != null && !trainers.any((t) => t.id == current.id)) current, ...trainers];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FieldLabel('المدرب'),
        DropdownButtonFormField<int?>(
          key: ValueKey('trainer-${current?.id}-${options.length}'),
          value: current?.id,
          isExpanded: true,
          decoration: InputDecoration(errorText: state.error('trainer_id')),
          items: [
            const DropdownMenuItem<int?>(child: Text('بلا مدرب')),
            for (final t in options)
              DropdownMenuItem<int?>(
                value: t.id,
                child: Text(t.name, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: editable
              ? (id) => context.read<WorkoutEditorCubit>().setTrainer(options.where((t) => t.id == id).firstOrNull)
              : null,
        ),
      ],
    );
  }
}

/// طرف من المدة (اختياري، كالنموذج: "من" و "إلى" حقلان): منتقي تاريخ، و × لمسحه.
class _DateField extends StatelessWidget {
  const _DateField({required this.editable, required this.end});

  final bool editable;

  /// `ends_on` أو `starts_on`.
  final bool end;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final state = context.watch<WorkoutEditorCubit>().state;
    final d = state.draft;
    final value = end ? d.endsOn : d.startsOn;
    final error = state.error(end ? 'ends_on' : 'starts_on');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FieldLabel(end ? 'إلى' : 'من'),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: editable ? () => _pick(context, value) : null,
                icon: const Icon(Icons.calendar_today_rounded),
                label: Text(
                  value == null ? 'بلا تاريخ' : Formatters.date(value),
                  textDirection: value == null ? null : TextDirection.ltr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (editable && value != null)
              IconButton(
                tooltip: end ? 'مسح تاريخ النهاية' : 'مسح تاريخ البداية',
                onPressed: () => _set(context, null),
                icon: const Icon(Icons.close_rounded),
              ),
          ],
        ),
        if (error != null) Text(error, style: UType.caption(color: c.dangerInk)),
      ],
    );
  }

  void _set(BuildContext context, DateTime? v) {
    final cubit = context.read<WorkoutEditorCubit>();
    final d = cubit.state.draft;
    end ? cubit.setPeriod(d.startsOn, v) : cubit.setPeriod(v, d.endsOn);
  }

  Future<void> _pick(BuildContext context, DateTime? value) async {
    final now = Formatters.clubTime(sl<ServerClock>().now());
    final first = DateTime(now.year - 2), last = DateTime(now.year + 2, 12, 31);
    final initial = value ?? DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      firstDate: first,
      lastDate: last,
      initialDate: initial.isBefore(first) || initial.isAfter(last) ? DateTime(now.year, now.month, now.day) : initial,
      helpText: end ? 'نهاية الخطة' : 'بداية الخطة',
    );
    if (picked == null || !context.mounted) return;
    _set(context, picked);
  }
}
