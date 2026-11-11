import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ultragym_design/ultragym_design.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import '../theme/theme_cubit.dart';

/// الشريط العلوي (`Dashboard.html`): زر القائمة أو الطي، عنوان القسم، ثم أدوات الشريط.
/// `actions` مكان محدد الفرع وحالة الصندوق والبحث والجرس حين تُبنى ميزاتها.
class AppTopBar extends StatelessWidget {
  const AppTopBar({super.key, required this.title, this.leading, this.actions = const []});

  final String title;
  final Widget? leading;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: AppSize.topBar,
      padding: const EdgeInsetsDirectional.only(start: AppSpace.s4, end: AppSpace.s6),
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Row(
        children: [
          if (leading != null) ...[leading!, AppSpace.gap2],
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: UType.h2(color: c.ink),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          for (final a in actions) ...[a, AppSpace.gap2],
          const ThemeToggle(),
        ],
      ),
    );
  }
}

/// زر دائري بحد خفيف (`.iconbtn` بالنموذج) مع تلميح إلزامي.
class TopBarIconButton extends StatelessWidget {
  const TopBarIconButton({super.key, required this.icon, required this.tooltip, required this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        fixedSize: const Size.square(AppSize.controlSm + AppSpace.s1),
        backgroundColor: c.surface,
        side: BorderSide(color: c.line),
        foregroundColor: c.ink,
      ),
      icon: Icon(icon, size: AppSize.iconSm),
    );
  }
}

/// حبة الشريط (`.pill` بالنموذج): أيقونة + نص + سهم اختياري. `compact` = أيقونة فقط (الموبايل).
/// بلا `onTap` تُرسم فقط (للعرض، أو داخل `PopupMenuButton` الذي يتولى الضغط).
/// `muted` = نص تلميح باهت يملأ الحبة (حبة البحث)، و `trailing` بنهايتها (اختصار لوحة المفاتيح).
class TopBarPill extends StatelessWidget {
  const TopBarPill({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.dropdown = false,
    this.compact = false,
    this.muted = false,
    this.maxWidth = AppSize.sidebar,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool dropdown, compact, muted;
  final double maxWidth;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Text(
      label,
      style: UType.label(color: muted ? c.inkMuted : c.ink),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    final body = Container(
      height: AppSize.controlSm + AppSpace.s1,
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: EdgeInsets.symmetric(horizontal: compact ? AppSpace.s2 + AppSpace.s1 : AppSpace.s4),
      decoration: ShapeDecoration(
        color: c.surface,
        shape: StadiumBorder(side: BorderSide(color: c.line)),
      ),
      child: Row(
        mainAxisSize: muted ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Icon(icon, size: AppSize.iconSm, color: c.inkMuted),
          if (!compact) ...[AppSpace.gap2, muted ? Expanded(child: text) : Flexible(child: text)],
          if (trailing != null) ...[AppSpace.gap2, trailing!],
          if (dropdown) ...[AppSpace.gap1, Icon(Icons.expand_more_rounded, size: AppSize.iconSm, color: c.inkMuted)],
        ],
      ),
    );
    if (onTap == null) return body;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(onTap: onTap, customBorder: const StadiumBorder(), child: body),
    );
  }
}

/// تبديل الفاتح والداكن (يُحفظ الاختيار بـ `ThemeCubit`).
class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    return TopBarIconButton(
      icon: dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
      tooltip: dark ? 'الوضع الفاتح' : 'الوضع الداكن',
      onPressed: () => context.read<ThemeCubit>().select(dark ? ThemeMode.light : ThemeMode.dark),
    );
  }
}
