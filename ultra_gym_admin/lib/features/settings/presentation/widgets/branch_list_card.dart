import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../branches/domain/models/branch_models.dart';
import '../../domain/models/settings_models.dart';

/// قائمة الفروع (`BranchSettings.html`): "N من L" و "+ فرع" (معطّل بحد الباقة)، ثم سطر لكل فرع بشاراته.
/// `selected` = معرّف الفرع المفتوح بالمحرر، و 0 = فرع جديد.
class BranchListCard extends StatelessWidget {
  const BranchListCard({super.key, required this.branches, required this.selected, required this.onSelect, this.club});

  final List<Branch> branches;
  final int selected;
  final ValueChanged<int> onSelect;

  /// حد الفروع من ملف النادي؛ null (لم يُحمَّل أو فشل) = بلا عدّاد والزر متاح، والخادم يرفض بـ `PLAN_LIMIT_REACHED`.
  final ClubProfile? club;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final limitReached = club?.branchLimitReached ?? false;
    return CutCard(
      padding: const EdgeInsets.all(AppSpace.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.s3,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: AppSpace.s2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('الفروع', style: UType.h3(color: c.ink)),
                    if (club?.branchesLimit case final limit?)
                      Text('${club!.branchesUsed} من $limit', style: UType.label(color: c.inkMuted)),
                  ],
                ),
              ),
              Tooltip(
                message: limitReached ? 'وصلت لحد الفروع بباقتك.' : 'إضافة فرع',
                child: TextButton.icon(
                  onPressed: limitReached || selected == 0 ? null : () => onSelect(0),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('فرع'),
                ),
              ),
            ],
          ),
          for (final b in branches) _BranchTile(b, selected: b.id == selected, onTap: () => onSelect(b.id)),
          if (selected == 0) _NewTile(),
        ],
      ),
    );
  }
}

class _BranchTile extends StatelessWidget {
  const _BranchTile(this.b, {required this.selected, required this.onTap});

  final Branch b;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final sub = [if (b.isMain) 'رئيسي', SettingsTexts.policy(b.genderPolicy), ?b.city].join(' · ');
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? c.primarySoft : Colors.transparent,
        borderRadius: AppRadius.fieldAll,
        child: InkWell(
          borderRadius: AppRadius.fieldAll,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSize.minTap),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.s3, vertical: AppSpace.s2),
              child: Row(
                spacing: AppSpace.s2,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b.name, style: UType.body(color: c.ink).weight(selected ? 600 : 500)),
                        Text(sub, style: UType.caption(color: c.inkMuted)),
                      ],
                    ),
                  ),
                  StatusBadge(b.isActive ? 'فعّال' : 'موقوف', tone: b.isActive ? UTone.success : UTone.neutral),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NewTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      constraints: const BoxConstraints(minHeight: AppSize.minTap),
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.s3, vertical: AppSpace.s2),
      decoration: BoxDecoration(color: c.primarySoft, borderRadius: AppRadius.fieldAll),
      alignment: AlignmentDirectional.centerStart,
      child: Text('فرع جديد', style: UType.body(color: c.ink).weight(600)),
    );
  }
}
