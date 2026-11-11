import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../domain/models/branch_draft.dart';
import '../../domain/models/settings_models.dart';
import '../bloc/settings_cubits.dart';
import 'club_settings_cards.dart';

/// أقسام الذكور والإناث (`BranchSettings.html`): مختلط / أوقات منفصلة، ثم فترة لكل مجموعة أيام بوقتيها وقسمها.
class BranchScheduleCard extends StatelessWidget {
  const BranchScheduleCard({super.key});

  static const _policies = <FormOption<String>>[
    (value: 'mixed', label: 'مختلط'),
    (value: 'time_split', label: 'أوقات منفصلة'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final cubit = context.read<BranchEditorCubit>();
    final s = context.watch<BranchEditorCubit>().state;
    final d = s.draft;
    return SettingsCard(
      title: 'أقسام الذكور والإناث',
      subtitle: 'بتوقيت النادي. الاستقبال يرفض الدخول خارج وقت قسم العضو.',
      children: [
        FilterChoiceChips<String>(
          options: _policies,
          value: d.policy,
          showAll: false,
          semanticsLabel: 'نظام الدخول',
          onChanged: (v) => cubit.setPolicy(v ?? 'mixed'),
        ),
        if (!d.timeSplit)
          Text('الدخول للجميع بكل الأوقات. هذا هو الافتراضي.', style: UType.body(color: c.inkMuted))
        else ...[
          for (final (i, slot) in d.slots.indexed)
            _SlotCard(key: ValueKey(slot.uid), index: i, slot: slot, errors: s.errors),
          if (s.error('gender_schedule') case final e?) Text(e, style: UType.label(color: c.dangerInk)),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: d.slots.length >= BranchDraft.maxSlots ? null : cubit.addSlot,
              icon: const Icon(Icons.add_rounded),
              label: const Text('إضافة فترة'),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppSpace.s3),
            decoration: BoxDecoration(color: c.warningSoft, borderRadius: AppRadius.fieldAll),
            child: Text(
              'خارج كل الفترات الفرع مغلق. الأعضاء بلا جنس محدد سيُرفض دخولهم حتى يُكمَل ملفهم.',
              style: UType.label(color: c.warningInk),
            ),
          ),
        ],
      ],
    );
  }
}

class _SlotCard extends StatelessWidget {
  const _SlotCard({super.key, required this.index, required this.slot, required this.errors});

  final int index;
  final SlotDraft slot;
  final Map<String, String> errors;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final cubit = context.read<BranchEditorCubit>();
    String? err(String f) =>
        errors['gender_schedule.$index.$f'] ?? (f == 'days' ? errors['gender_schedule.$index'] : null);
    final to = BranchDraft.time(slot.to);
    return Container(
      padding: const EdgeInsets.all(AppSpace.s3),
      decoration: BoxDecoration(
        border: Border.all(color: c.line),
        borderRadius: AppRadius.fieldAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.s3,
        children: [
          Wrap(
            spacing: AppSpace.s2,
            runSpacing: AppSpace.s2,
            children: [
              for (final day in SettingsTexts.days)
                FilterChip(
                  label: Text(day.label),
                  selected: slot.days.contains(day.value),
                  onSelected: (_) => cubit.toggleDay(slot.uid, day.value),
                ),
            ],
          ),
          if (err('days') case final e?) Text(e, style: UType.label(color: c.dangerInk)),
          Wrap(
            spacing: AppSpace.s3,
            runSpacing: AppSpace.s3,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              SizedBox(
                width: AppSize.slotTimeField,
                child: DraftField(
                  label: 'من',
                  value: slot.from,
                  ltr: true,
                  hint: '08:00',
                  error: err('from'),
                  onChanged: (v) => cubit.setFrom(slot.uid, v),
                ),
              ),
              SizedBox(
                width: AppSize.slotTimeField,
                child: DraftField(
                  label: 'إلى',
                  value: slot.to,
                  ltr: true,
                  hint: '14:00',
                  error: err('to'),
                  onChanged: (v) => cubit.setTo(slot.uid, v),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const FieldLabel('القسم'),
                  FilterChoiceChips<String>(
                    options: SettingsTexts.genders,
                    value: slot.gender,
                    showAll: false,
                    semanticsLabel: 'القسم',
                    onChanged: (v) => cubit.setGender(slot.uid, v ?? 'mixed'),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () => cubit.removeSlot(slot.uid),
                style: TextButton.styleFrom(foregroundColor: c.dangerInk),
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('حذف الفترة'),
              ),
            ],
          ),
          if (slot.overnight && to != null)
            Text(
              '(حتى اليوم التالي) تنتهي ${Formatters.ltr(to)} صباح اليوم التالي.',
              style: UType.caption(color: c.inkMuted),
            ),
        ],
      ),
    );
  }
}
