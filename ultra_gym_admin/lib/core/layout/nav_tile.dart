import 'package:flutter/material.dart';
import 'package:ultragym_design/ultragym_design.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// ألوان القائمة الجانبية من أدوار الثيم: فاتحة بالوضع الفاتح وداكنة بالداكن (كلوحة الديمو)،
/// فالتحديد والمرور شفافية من لون النص نفسه.
class SidebarInk {
  SidebarInk._(UGPalette c)
    : selectedText = c.ink,
      groupLabel = c.inkFaint,
      divider = c.line,
      selectedFill = c.ink.withValues(alpha: .07),
      hoverFill = c.ink.withValues(alpha: .04);

  factory SidebarInk.of(BuildContext context) => SidebarInk._(context.colors);

  final Color selectedText, groupLabel, divider, selectedFill, hoverFill;

  static Color focusFill(Color focus) => focus.withValues(alpha: .22);
}

/// عنصر القائمة: مرور، ضغط، تركيز لوحة مفاتيح، ومحدد (شريط برتقالي بطرف البداية وأيقونة برتقالية).
/// مطوية = أيقونة فقط مع تلميح.
class NavTile extends StatelessWidget {
  const NavTile({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.collapsed,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected, collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ink = SidebarInk.of(context);
    final fg = selected ? ink.selectedText : c.sidebarInk;
    final tile = Semantics(
      selected: selected,
      button: true,
      label: collapsed ? label : null,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.smAll,
          hoverColor: ink.hoverFill,
          focusColor: SidebarInk.focusFill(c.focus),
          splashFactory: NoSplash.splashFactory,
          highlightColor: ink.hoverFill,
          child: AnimatedContainer(
            duration: AppMotion.of(context, AppMotion.fast),
            curve: AppMotion.curve,
            height: AppSize.control,
            decoration: BoxDecoration(color: selected ? ink.selectedFill : null, borderRadius: AppRadius.smAll),
            child: Stack(
              children: [
                PositionedDirectional(
                  start: 0,
                  top: AppSpace.s2,
                  bottom: AppSpace.s2,
                  child: AnimatedContainer(
                    duration: AppMotion.of(context, AppMotion.normal),
                    curve: AppMotion.curve,
                    width: selected ? AppSpace.s1 : 0,
                    decoration: BoxDecoration(color: c.primary, borderRadius: AppRadius.fullAll),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.s3),
                  child: Row(
                    mainAxisAlignment: collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                    children: [
                      Icon(icon, size: AppSize.icon, color: selected ? c.primary : fg),
                      if (!collapsed) ...[
                        AppSpace.gap3,
                        Expanded(
                          child: Text(
                            label,
                            style: UType.label(color: fg).weight(selected ? 600 : 500),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s1),
      child: collapsed ? Tooltip(message: label, child: tile) : tile,
    );
  }
}
