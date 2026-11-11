import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../../core/layout/app_top_bar.dart';
import '../../domain/models/branch_models.dart';
import '../bloc/branch_scope_cubit.dart';

/// محدد الفرع بالشريط العلوي (`Dashboard.html`: "كل الفروع ▾").
/// فرع واحد ← اسمه فقط بلا قائمة. الموبايل ← أيقونة فقط والاسم بالقائمة.
class BranchPicker extends StatelessWidget {
  const BranchPicker({super.key, this.compact = false});

  final bool compact;

  /// قيمة "كل الفروع" بالقائمة (المعرّفات الحقيقية موجبة).
  static const _all = 0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BranchScopeCubit, BranchScope>(
      builder: (context, s) {
        if (s.branches.isFirstLoad) {
          return AppShimmer(
            child: ShimmerBox(
              width: compact ? AppSize.controlSm : AppSize.gridItem / 2,
              height: AppSize.controlSm,
              radius: AppRadius.full,
            ),
          );
        }
        if (s.branches.isFailure && !s.branches.hasData) {
          return TopBarIconButton(
            icon: Icons.refresh_rounded,
            tooltip: 'تعذّر جلب الفروع. إعادة المحاولة',
            onPressed: context.read<BranchScopeCubit>().load,
          );
        }
        if (s.active.isEmpty) return const SizedBox.shrink();

        final label = s.selected?.name ?? 'كل الفروع';
        if (!s.canChoose) {
          return Tooltip(
            message: label,
            child: TopBarPill(icon: Icons.place_outlined, label: label, compact: compact),
          );
        }
        return PopupMenuButton<int>(
          tooltip: 'اختيار الفرع: $label',
          position: PopupMenuPosition.under,
          onSelected: (id) => context.read<BranchScopeCubit>().select(id == _all ? null : id),
          itemBuilder: (_) => [
            _item(context, _all, 'كل الفروع', null, s.selectedId == null),
            const PopupMenuDivider(),
            for (final b in s.active) _item(context, b.id, b.name, _subtitle(b), b.id == s.selectedId),
          ],
          child: TopBarPill(icon: Icons.place_outlined, label: label, dropdown: true, compact: compact),
        );
      },
    );
  }

  static String _subtitle(Branch b) => [
    if (b.isMain) 'الرئيسي',
    if (b.city != null) b.city!,
    b.cashSessionOpen ? 'الصندوق مفتوح' : 'الصندوق مغلق',
  ].join(' · ');

  PopupMenuItem<int> _item(BuildContext context, int value, String title, String? subtitle, bool selected) {
    final c = context.colors;
    return PopupMenuItem<int>(
      value: value,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: UType.label(color: c.ink).weight(selected ? 600 : 500)),
                if (subtitle != null) Text(subtitle, style: UType.caption(color: c.inkMuted)),
              ],
            ),
          ),
          AppSpace.gap3,
          Icon(Icons.check_rounded, size: AppSize.iconSm, color: selected ? c.primary : Colors.transparent),
        ],
      ),
    );
  }
}
