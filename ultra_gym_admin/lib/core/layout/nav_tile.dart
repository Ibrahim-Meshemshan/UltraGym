import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ultragym_design/ultragym_design.dart';

import '../bloc/value_cubit.dart';
import '../theme/app_colors.dart';
import '../theme/app_palette.dart';
import '../theme/app_tokens.dart';

/// ألوان القائمة الجانبية من أدوار الثيم: فاتحة بالوضع الفاتح وداكنة بالداكن (كلوحة الديمو).
class SidebarInk {
  SidebarInk._(UGPalette c)
    : selectedText = c.ink,
      groupLabel = c.inkMuted,
      divider = c.line,
      hoverFill = c.inkFaint.withValues(alpha: .14);

  factory SidebarInk.of(BuildContext context) => SidebarInk._(context.colors);

  final Color selectedText, groupLabel, divider, hoverFill;
}

typedef _Ui = ({bool hover, bool focus});

/// عنصر القائمة كـ `.snav__item` بالديمو: ارتفاع 44 وزوايا 14 والمحتوى بمنتصفه عمودياً.
/// المحدد بالتدرج البرتقالي وتوهجه ونصه وأيقونته داكنان، والمرور خلفية رمادية خفيفة ونص أغمق،
/// وتركيز لوحة المفاتيح حلقة بلون الحبر بسمك 2 على بعد 2 (لا تظهر بالضغط بالفأرة، كـ `:focus-visible`).
/// المرور والتركيز بـ `ValueCubit` (لا `setState`). مطوية = أيقونة فقط مع تلميح.
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
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => ValueCubit<_Ui>((hover: false, focus: false)),
    child: BlocBuilder<ValueCubit<_Ui>, _Ui>(builder: _tile),
  );

  Widget _tile(BuildContext context, _Ui ui) {
    final c = context.colors;
    final p = AppPalette.of(context);
    final ink = SidebarInk.of(context);
    final state = context.read<ValueCubit<_Ui>>();
    final fg = selected ? p.accentInk : (ui.hover ? c.ink : c.sidebarInk);
    final iconFg = selected ? p.accentInk : (ui.hover ? c.ink : c.inkMuted);
    final body = AnimatedContainer(
      duration: AppMotion.of(context, AppMotion.normal),
      curve: AppMotion.curve,
      height: AppSize.navItem,
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.s3),
      alignment: collapsed ? Alignment.center : AlignmentDirectional.centerStart,
      decoration: BoxDecoration(
        gradient: selected ? p.gradient : null,
        color: selected || !ui.hover ? null : ink.hoverFill,
        borderRadius: AppRadius.navAll,
        boxShadow: selected ? p.glow : const [],
      ),
      child: Row(
        mainAxisAlignment: collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          Icon(icon, size: AppSize.icon, color: iconFg),
          if (!collapsed) ...[
            AppSpace.gap3,
            Expanded(
              child: Text(
                label,
                style: UType.body(color: fg).weight(600),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ],
      ),
    );
    const ring = AppSize.focusGap + AppSize.focusRing;
    final tile = Semantics(
      selected: selected,
      button: true,
      label: collapsed ? label : null,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              onHover: (h) => state.update((u) => (hover: h, focus: u.focus)),
              onFocusChange: (f) => state.update(
                (u) =>
                    (hover: u.hover, focus: f && FocusManager.instance.highlightMode == FocusHighlightMode.traditional),
              ),
              borderRadius: AppRadius.navAll,
              hoverColor: Colors.transparent,
              focusColor: Colors.transparent,
              highlightColor: ink.hoverFill,
              splashFactory: NoSplash.splashFactory,
              child: body,
            ),
          ),
          if (ui.focus)
            Positioned.fill(
              left: -ring,
              right: -ring,
              top: -ring,
              bottom: -ring,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.navFocusAll,
                    border: Border.all(color: c.focus, width: AppSize.focusRing),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s1),
      child: collapsed ? Tooltip(message: label, child: tile) : tile,
    );
  }
}
