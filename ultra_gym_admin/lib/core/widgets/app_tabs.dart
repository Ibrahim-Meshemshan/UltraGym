import 'package:flutter/material.dart';
import 'package:ultragym_design/ultragym_design.dart';

import '../responsive/responsive.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import '../utils/formatters.dart';

/// تبويب: عنوان + عدد اختياري بجانبه ("الأعضاء 1,284").
typedef AppTab = ({String label, int? count});

/// تبويبات بخط سفلي (`.tab` بالنموذج): المختار بخط أساسي 2px ونص أغمق.
class AppTabs extends StatelessWidget {
  const AppTabs({super.key, required this.tabs, required this.selected, required this.onSelect});

  final List<AppTab> tabs;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpace.s6,
        children: [
          for (var i = 0; i < tabs.length; i++) _Tab(tab: tabs[i], selected: i == selected, onTap: () => onSelect(i)),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.tab, required this.selected, required this.onTap});

  final AppTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final count = tab.count;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: selected ? null : onTap,
        child: AnimatedContainer(
          duration: AppMotion.of(context, AppMotion.fast),
          height: context.isMobile ? AppSize.minTap : AppSize.control,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.s1),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: selected ? c.primary : Colors.transparent, width: 2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpace.s2,
            children: [
              Text(tab.label, style: UType.body(color: selected ? c.ink : c.inkMuted).weight(selected ? 600 : 400)),
              if (count != null)
                Text(
                  Formatters.number(count),
                  textDirection: TextDirection.ltr,
                  style: UType.body(color: c.inkMuted),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
