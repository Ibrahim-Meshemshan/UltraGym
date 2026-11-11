import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../members/presentation/widgets/member_cells.dart';
import '../../domain/models/payroll_models.dart';

/// قائمة الموظفين الفعّالين لشهر: الحروف والاسم والدور وشارة "مصروف" / "مستحق" من رواتب الشهر المدفوعة.
class StaffListCard extends StatelessWidget {
  const StaffListCard({
    super.key,
    required this.header,
    required this.slice,
    required this.selectedId,
    required this.onSelect,
    required this.onRetry,
  });

  final Widget header;
  final Slice<PayrollRoster> slice;
  final int? selectedId;
  final ValueChanged<int> onSelect;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => CutCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.s3,
      children: [
        Align(alignment: AlignmentDirectional.centerStart, child: header),
        SliceView<PayrollRoster>(
          slice: slice,
          onRetry: onRetry,
          loading: const _Shimmer(),
          isEmpty: (r) => r.staff.isEmpty,
          empty: const EmptyState(
            icon: Icons.badge_rounded,
            title: 'لا موظفين فعّالين',
            message: 'أضف المدربين والموظفين برواتبهم من "الموظفون والحسابات" ثم اصرف رواتبهم من هنا.',
          ),
          builder: (context, r) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpace.s1,
            children: [
              for (final s in r.staff)
                _StaffTile(s, paid: r.paid.containsKey(s.id), selected: s.id == selectedId, onTap: () => onSelect(s.id)),
            ],
          ),
        ),
      ],
    ),
  );
}

class _StaffTile extends StatelessWidget {
  const _StaffTile(this.staff, {required this.paid, required this.selected, required this.onTap});

  final PayrollStaff staff;
  final bool paid, selected;
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
              child: Row(
                spacing: AppSpace.s3,
                children: [
                  MemberAvatar(staff.name),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          staff.name,
                          style: UType.body(color: c.ink).weight(600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          PayrollTexts.role(staff),
                          style: UType.caption(color: c.inkMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  paid
                      ? const StatusBadge('مصروف', tone: UTone.success)
                      : const StatusBadge('مستحق', tone: UTone.warning),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Shimmer extends StatelessWidget {
  const _Shimmer();

  @override
  Widget build(BuildContext context) => AppShimmer(
    child: Column(
      spacing: AppSpace.s3,
      children: [
        for (var i = 0; i < 3; i++)
          const Row(
            spacing: AppSpace.s3,
            children: [
              ShimmerBox.circle(size: AppSize.avatar),
              Expanded(child: ShimmerBox(height: AppSpace.s8)),
            ],
          ),
      ],
    ),
  );
}
