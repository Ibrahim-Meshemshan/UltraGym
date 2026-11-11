import 'package:flutter/material.dart';
import 'package:ultragym_design/ultragym_design.dart';

import '../../responsive/responsive.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../form/form_pickers.dart';

/// حبة فلتر بقائمة (`.pill` "الفرع: الكل ▾"). null = الكل (`showAll: false` لاختيار إلزامي بلا "الكل"). الحبة المفعّلة بلون أساسي خفيف.
class FilterMenu<T> extends StatelessWidget {
  const FilterMenu({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    this.allLabel = 'الكل',
    this.showAll = true,
  });

  final String label, allLabel;
  final List<FormOption<T>> options;
  final T? value;
  final ValueChanged<T?> onChanged;
  final bool showAll;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final current = options.where((o) => o.value == value).firstOrNull;
    return MenuAnchor(
      menuChildren: [
        for (final o in <({T? value, String label})>[if (showAll) (value: null, label: allLabel), ...options])
          MenuItemButton(
            onPressed: () => onChanged(o.value),
            leadingIcon: Icon(o.value == value ? Icons.check_rounded : null, size: AppSize.iconSm, color: c.primary),
            child: Text(o.label, style: UType.body(color: c.ink)),
          ),
      ],
      builder: (context, menu, _) => FilterPill(
        active: current != null,
        onTap: () => menu.isOpen ? menu.close() : menu.open(),
        semanticsLabel: '$label: ${current?.label ?? allLabel}',
        children: [
          Text('$label: ${current?.label ?? allLabel}'),
          Icon(Icons.keyboard_arrow_down_rounded, size: AppSize.iconSm, color: c.inkMuted),
        ],
      ),
    );
  }
}

/// حبة بمربع اختيار ("عليه دين").
class FilterToggle extends StatelessWidget {
  const FilterToggle({super.key, required this.label, required this.value, required this.onChanged});

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => FilterPill(
    active: value,
    onTap: () => onChanged(!value),
    checked: value,
    semanticsLabel: label,
    children: [
      IgnorePointer(
        child: SizedBox.square(
          dimension: AppSize.iconSm,
          child: Checkbox(value: value, onChanged: (_) {}, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
        ),
      ),
      Text(label),
    ],
  );
}

/// الإطار المشترك للحبوب: ارتفاع 38 (48 باللمس)، حد رفيع، ونص `body` صغير.
class FilterPill extends StatelessWidget {
  const FilterPill({
    super.key,
    required this.children,
    required this.onTap,
    required this.semanticsLabel,
    this.active = false,
    this.checked,
  });

  final List<Widget> children;
  final VoidCallback onTap;
  final String semanticsLabel;
  final bool active;
  final bool? checked;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = active ? c.primaryInk : c.ink;
    return Semantics(
      button: checked == null,
      checked: checked,
      label: semanticsLabel,
      excludeSemantics: true,
      child: Material(
        color: active ? c.primarySoft : c.surface,
        shape: StadiumBorder(side: BorderSide(color: active ? c.primary : c.line)),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: Container(
            height: context.isMobile ? AppSize.minTap : AppSize.filterPill,
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.s4),
            child: DefaultTextStyle(
              style: UType.label(color: fg),
              child: Row(mainAxisSize: MainAxisSize.min, spacing: AppSpace.s2, children: children),
            ),
          ),
        ),
      ),
    );
  }
}

/// رقائق اختيار واحد (`.chip`، حالة الاشتراك): "الكل" أولاً (null)، والمختارة معكوسة الألوان.
/// `showAll: false` = اختيار إلزامي بلا "الكل" (مبدّل بين قيمتين مثلاً).
class FilterChoiceChips<T> extends StatelessWidget {
  const FilterChoiceChips({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    required this.semanticsLabel,
    this.allLabel = 'الكل',
    this.showAll = true,
  });

  final List<FormOption<T>> options;
  final T? value;
  final ValueChanged<T?> onChanged;
  final String semanticsLabel, allLabel;
  final bool showAll;

  @override
  Widget build(BuildContext context) {
    final all = <({T? value, String label})>[if (showAll) (value: null, label: allLabel), ...options];
    return Semantics(
      container: true,
      label: semanticsLabel,
      child: Wrap(
        spacing: AppSpace.s2,
        runSpacing: AppSpace.s2,
        children: [
          for (final o in all) _Chip(label: o.label, selected: o.value == value, onTap: () => onChanged(o.value)),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? c.ink : c.surface,
        shape: StadiumBorder(side: BorderSide(color: selected ? c.ink : c.line)),
        child: InkWell(
          onTap: selected ? null : onTap,
          customBorder: const StadiumBorder(),
          child: Container(
            height: context.isMobile ? AppSize.minTap : AppSize.filterChip,
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.s4),
            child: Center(
              widthFactor: 1,
              child: Text(label, style: UType.label(color: selected ? c.surface : c.ink)),
            ),
          ),
        ),
      ),
    );
  }
}
