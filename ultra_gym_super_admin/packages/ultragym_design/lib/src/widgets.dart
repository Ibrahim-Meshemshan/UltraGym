import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'motion.dart';
import 'ornaments.dart';
import 'theme.dart';
import 'tokens.dart';

// ============================================================ الشعار

enum ULogo { mark, horizontal, vertical, seal, outline }

/// الشعار بكل نسخه. `onDark` للأرضيات الداكنة (القائمة، البانر، الدخول: داكنة بالثيمين)
class UltraGymLogo extends StatelessWidget {
  const UltraGymLogo({super.key, this.variant = ULogo.horizontal, this.onDark, this.height = 32});
  final ULogo variant;
  final bool? onDark;
  final double height;

  @override
  Widget build(BuildContext context) {
    final dark = onDark ?? UGColors.isDark(context);
    return SvgPicture.asset(
      'packages/ultragym_design/assets/logo/ultragym-${variant.name}-${dark ? 'dark' : 'light'}.svg',
      height: height,
      semanticsLabel: 'UltraGym',
    );
  }
}

// ============================================================ الأزرار

enum UButtonKind { primary, secondary, ghost, danger, onDark }

/// الزر. زر أساسي واحد بكل شاشة، والنص فعل مباشر: "تسجيل عضو"
class UGButton extends StatefulWidget {
  const UGButton({super.key, required this.label, this.icon, this.onPressed, this.kind = UButtonKind.primary, this.expand = false, this.large = false});
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final UButtonKind kind;
  final bool expand, large;

  @override
  State<UGButton> createState() => _UGButtonState();
}

class _UGButtonState extends State<UGButton> {
  bool _hover = false;
  bool _focus = false;

  @override
  Widget build(BuildContext context) {
    final c = UGColors.of(context);
    final enabled = widget.onPressed != null;
    final (Color bg, Color fg, Color? border) = switch (widget.kind) {
      UButtonKind.primary => (_hover ? c.primaryHover : c.primary, c.onPrimary, null),
      UButtonKind.secondary => (_hover ? c.surfaceAlt : c.surface, c.ink, c.line),
      UButtonKind.ghost => (_hover ? c.surfaceAlt : Colors.transparent, c.primaryInk, null),
      UButtonKind.danger => (_hover ? c.dangerInk : c.danger, Colors.white, null),
      UButtonKind.onDark => (_hover ? Colors.white.withValues(alpha: .16) : Colors.white.withValues(alpha: .1), Colors.white, Colors.white.withValues(alpha: .18)),
    };
    final h = widget.large ? USize.controlLg : USize.control;
    Widget body = AnimatedContainer(
      duration: UMotionValues.fast,
      height: h,
      padding: EdgeInsets.symmetric(horizontal: widget.large ? USpace.s6 : USpace.s5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(URadius.sm),
        border: border == null ? null : Border.all(color: border),
        boxShadow: _focus ? [BoxShadow(color: c.focus, spreadRadius: 2)] : null,
      ),
      child: Row(
        mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.icon != null) ...[Icon(widget.icon, size: 18, color: fg), const SizedBox(width: USpace.s2)],
          Text(widget.label, style: (widget.large ? UType.bodyLg() : UType.label()).weight(600).copyWith(color: fg)),
        ],
      ),
    );
    if (widget.kind == UButtonKind.primary) body = Shine(active: _hover, child: body);
    return Opacity(
      opacity: enabled ? 1 : .45,
      child: FocusableActionDetector(
        enabled: enabled,
        onShowFocusHighlight: (v) => setState(() => _focus = v),
        onShowHoverHighlight: (v) => setState(() => _hover = v),
        mouseCursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onPressed?.call())},
        child: Semantics(button: true, label: widget.label, child: PressScale(onTap: widget.onPressed, child: body)),
      ),
    );
  }
}

// ============================================================ الشارات

/// شارة الحالة: خلفية هادئة + نص (+ نقطة اختيارية). اللون وحده لا يكفي
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.text, {super.key, this.tone = UTone.neutral, this.dot = true});
  final String text;
  final UTone tone;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = tone.colors(UGColors.of(context));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(URadius.full)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (dot) ...[Container(width: 6, height: 6, decoration: BoxDecoration(color: fg, shape: BoxShape.circle)), const SizedBox(width: 6)],
        Text(text, style: UType.caption(color: fg).weight(600)),
      ]),
    );
  }
}

/// شارة مائلة 10°: توقيع الهوية (عناوين الأقسام بالبانر، "جديد"، "مباشر")
class SlantTag extends StatelessWidget {
  const SlantTag(this.text, {super.key, this.background, this.foreground});
  final String text;
  final Color? background, foreground;

  @override
  Widget build(BuildContext context) {
    final c = UGColors.of(context);
    const k = -0.1763; // tan(10°)
    return Transform(
      transform: Matrix4.skewX(k),
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: USpace.s3, vertical: 3),
        decoration: BoxDecoration(color: background ?? c.primary, borderRadius: BorderRadius.circular(4)),
        child: Transform(transform: Matrix4.skewX(-k), alignment: Alignment.center, child: Text(text, style: UType.caption(color: foreground ?? c.onPrimary).weight(600))),
      ),
    );
  }
}

/// أيقونة داخل مربع مائل. تنزلق للأمام عند المرور على البطاقة
class IconSlab extends StatelessWidget {
  const IconSlab(this.icon, {super.key, this.size = 40, this.tone = UTone.primary, this.active = false, this.solid = false});
  final IconData icon;
  final double size;
  final UTone tone;
  final bool active, solid;

  @override
  Widget build(BuildContext context) {
    final c = UGColors.of(context);
    final (bg, fg) = solid ? (c.primary, c.onPrimary) : tone.colors(c);
    final reduced = UMotion.reduced(context);
    return AnimatedSlide(
      offset: Offset(active && !reduced ? -.08 : 0, 0),
      duration: UMotionValues.slow,
      curve: UMotionValues.standard,
      child: Transform(
        transform: Matrix4.skewX(-0.1763),
        alignment: Alignment.center,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(size * .26)),
          child: Transform(transform: Matrix4.skewX(0.1763), alignment: Alignment.center, child: Icon(icon, color: fg, size: size * .5)),
        ),
      ),
    );
  }
}

// ============================================================ البطاقات

/// البطاقة المشطوفة: شكل كل البطاقات. بلا ظل وهي ساكنة، وتصعد بحد برتقالي عند المرور
class CutCard extends StatelessWidget {
  const CutCard({super.key, required this.child, this.onTap, this.padding = const EdgeInsets.all(USpace.s5), this.builder});
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Widget Function(BuildContext context, bool hover, Widget child)? builder;

  @override
  Widget build(BuildContext context) {
    final c = UGColors.of(context);
    final dark = UGColors.isDark(context);
    return HoverLift(
      builder: (context, hover) {
        final active = hover && onTap != null;
        final inner = builder?.call(context, active, child) ?? child;
        return PressScale(
          onTap: onTap,
          child: AnimatedContainer(
            duration: UMotionValues.base,
            curve: UMotionValues.standard,
            decoration: ShapeDecoration(
              color: c.surface,
              shape: CutCardBorder(side: BorderSide(color: active ? c.primary : c.line, width: active ? 1.4 : 1)),
              shadows: active ? [BoxShadow(color: Colors.black.withValues(alpha: dark ? .35 : .08), blurRadius: 24, offset: const Offset(0, 8))] : null,
            ),
            padding: padding,
            child: MouseRegion(cursor: onTap == null ? MouseCursor.defer : SystemMouseCursors.click, child: inner),
          ),
        );
      },
    );
  }
}

/// بطاقة الإحصاء: أيقونة مائلة، رقم يعدّ، وسطر التغيّر
class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.icon, required this.label, required this.value, this.prefix = '', this.suffix = '', this.delta, this.deltaTone = UTone.success, this.onTap});
  final IconData icon;
  final String label, prefix, suffix;
  final double value;
  final String? delta;
  final UTone deltaTone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = UGColors.of(context);
    return CutCard(
      onTap: onTap ?? () {},
      padding: const EdgeInsets.all(USpace.s4),
      child: const SizedBox(),
      builder: (context, hover, _) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(label, style: UType.label(color: c.inkMuted), maxLines: 1, overflow: TextOverflow.ellipsis)),
          IconSlab(icon, size: 34, active: hover),
        ]),
        const SizedBox(height: USpace.s2),
        Align(alignment: AlignmentDirectional.centerStart, child: CountUp(value, prefix: prefix, suffix: suffix, style: UType.stat(color: c.ink))),
        if (delta != null) ...[
          const SizedBox(height: 2),
          Text(delta!, style: UType.caption(color: deltaTone.colors(c).$2), textDirection: TextDirection.rtl),
        ],
      ]),
    );
  }
}

/// بطاقة قسم: عنوان + رابط + محتوى
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.title, required this.child, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = UGColors.of(context);
    return CutCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Text(title, style: UType.h3(color: c.ink))),
          if (action != null) TextButton(onPressed: onAction ?? () {}, child: Text(action!)),
        ]),
        const SizedBox(height: USpace.s3),
        child,
      ]),
    );
  }
}

/// صف عضو بالقوائم: الأحرف الأولى، الاسم، الاشتراك، والحالة
class MemberTile extends StatefulWidget {
  const MemberTile({super.key, required this.name, required this.plan, required this.status, this.tone = UTone.neutral, this.trailing});
  final String name, plan, status;
  final UTone tone;
  final String? trailing;

  @override
  State<MemberTile> createState() => _MemberTileState();
}

class _MemberTileState extends State<MemberTile> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    final c = UGColors.of(context);
    final initials = widget.name.split(' ').take(2).map((w) => w.characters.first).join(' ');
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: AnimatedContainer(
        duration: UMotionValues.fast,
        padding: const EdgeInsets.symmetric(horizontal: USpace.s2, vertical: USpace.s2),
        decoration: BoxDecoration(color: _h ? c.surfaceAlt : Colors.transparent, borderRadius: BorderRadius.circular(URadius.sm)),
        child: Row(children: [
          CircleAvatar(radius: 17, backgroundColor: c.primarySoft, child: Text(initials, style: UType.caption(color: c.primaryInk).weight(600))),
          const SizedBox(width: USpace.s3),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.name, style: UType.body(color: c.ink).weight(500)),
              Text(widget.plan, style: UType.caption(color: c.inkMuted)),
            ]),
          ),
          if (widget.trailing != null) ...[Text(widget.trailing!, style: UType.caption(color: c.inkMuted)), const SizedBox(width: USpace.s3)],
          StatusBadge(widget.status, tone: widget.tone),
        ]),
      ),
    );
  }
}

// ============================================================ الهيكل: القائمة والشريط العلوي

class UNavItem {
  const UNavItem(this.icon, this.label, {this.badge});
  final IconData icon;
  final String label;
  final int? badge;
}

class _NavTile extends StatefulWidget {
  const _NavTile({required this.item, required this.selected, required this.collapsed, required this.onTap});
  final UNavItem item;
  final bool selected, collapsed;
  final VoidCallback onTap;

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    final c = UGColors.of(context);
    final sel = widget.selected;
    final fg = sel ? Colors.white : c.sidebarInk;
    final tile = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: UMotionValues.fast,
          curve: UMotionValues.standard,
          height: 42,
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: EdgeInsetsDirectional.only(start: _h && !sel ? 15 : 12, end: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: sel ? .1 : (_h ? .05 : 0)),
            borderRadius: BorderRadius.circular(URadius.sm),
          ),
          child: Stack(children: [
            PositionedDirectional(
              start: -12,
              top: 9,
              bottom: 9,
              child: AnimatedContainer(
                duration: UMotionValues.base,
                curve: UMotionValues.standard,
                width: sel ? 4 : 0,
                decoration: BoxDecoration(color: c.primary, borderRadius: const BorderRadius.horizontal(left: Radius.circular(4), right: Radius.circular(4))),
              ),
            ),
            Row(children: [
              Icon(widget.item.icon, size: 20, color: sel ? c.primary : fg),
              if (!widget.collapsed) ...[
                const SizedBox(width: USpace.s3),
                Expanded(child: Text(widget.item.label, style: UType.label(color: fg).weight(sel ? 600 : 500), overflow: TextOverflow.ellipsis)),
                if (widget.item.badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                    decoration: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(99)),
                    child: Text('${widget.item.badge}', style: UType.caption(color: c.onAccent).weight(700)),
                  ),
              ],
            ]),
          ]),
        ),
      ),
    );
    return widget.collapsed ? Tooltip(message: widget.item.label, child: tile) : tile;
  }
}

/// القائمة الجانبية: داكنة بالثيمين وبلا زخرفة. مفتوحة 264 أو مطوية 76
class UGSidebar extends StatelessWidget {
  const UGSidebar({super.key, required this.items, required this.selected, required this.onSelect, this.collapsed = false, this.footer});
  final List<UNavItem> items;
  final int selected;
  final ValueChanged<int> onSelect;
  final bool collapsed;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final c = UGColors.of(context);
    return AnimatedContainer(
      duration: UMotionValues.long,
      curve: UMotionValues.emphasized,
      width: collapsed ? USize.sidebarCollapsed : USize.sidebar,
      color: c.sidebar,
      padding: const EdgeInsets.symmetric(horizontal: USpace.s3, vertical: USpace.s5),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: USpace.s2, vertical: USpace.s2),
          child: Align(
            alignment: collapsed ? Alignment.center : AlignmentDirectional.centerStart,
            child: UltraGymLogo(variant: collapsed ? ULogo.mark : ULogo.horizontal, onDark: true, height: collapsed ? 26 : 28),
          ),
        ),
        const SizedBox(height: USpace.s4),
        Divider(color: Colors.white.withValues(alpha: .08)),
        const SizedBox(height: USpace.s3),
        for (var i = 0; i < items.length; i++) _NavTile(item: items[i], selected: i == selected, collapsed: collapsed, onTap: () => onSelect(i)),
        const Spacer(),
        if (footer != null) footer!,
      ]),
    );
  }
}

/// جرس الإشعارات مع نقطة نابضة
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key, this.count = 0});
  final int count;

  @override
  Widget build(BuildContext context) {
    final c = UGColors.of(context);
    return Tooltip(
      message: 'الإشعارات',
      child: Stack(clipBehavior: Clip.none, children: [
        IconButton(onPressed: () {}, icon: Icon(Icons.notifications_none_rounded, color: c.inkMuted)),
        if (count > 0) PositionedDirectional(top: 4, end: 4, child: PingDot(color: c.primary)),
      ]),
    );
  }
}

/// البحث الشامل
class SearchPill extends StatelessWidget {
  const SearchPill({super.key, this.hint = 'ابحث عن عضو، اشتراك، أو حصة…', this.width = 320});
  final String hint;
  final double width;

  @override
  Widget build(BuildContext context) {
    final c = UGColors.of(context);
    return Container(
      width: width,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: USpace.s4),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(URadius.full), border: Border.all(color: c.line)),
      child: Row(children: [
        Icon(Icons.search_rounded, size: 18, color: c.inkFaint),
        const SizedBox(width: USpace.s2),
        Expanded(child: Text(hint, style: UType.label(color: c.inkFaint), overflow: TextOverflow.ellipsis)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(border: Border.all(color: c.line), borderRadius: BorderRadius.circular(5)),
          child: Text('Ctrl K', style: UType.caption(color: c.inkFaint), textDirection: TextDirection.ltr),
        ),
      ]),
    );
  }
}

/// الشريط العلوي: عنوان، بحث، إشعارات، حساب
class UGTopBar extends StatelessWidget implements PreferredSizeWidget {
  const UGTopBar({super.key, required this.title, this.onMenu, this.showSearch = true, this.trailing = const []});
  final String title;
  final VoidCallback? onMenu;
  final bool showSearch;
  final List<Widget> trailing;

  @override
  Size get preferredSize => const Size.fromHeight(USize.topBar);

  @override
  Widget build(BuildContext context) {
    final c = UGColors.of(context);
    return Container(
      height: USize.topBar,
      padding: const EdgeInsets.symmetric(horizontal: USpace.s6),
      decoration: BoxDecoration(color: c.bg, border: Border(bottom: BorderSide(color: c.line))),
      child: Row(children: [
        if (onMenu != null) IconButton(onPressed: onMenu, tooltip: 'القائمة', icon: Icon(Icons.menu_rounded, color: c.ink)),
        Text(title, style: UType.h2(color: c.ink)),
        const Spacer(),
        if (showSearch) const SearchPill(),
        const SizedBox(width: USpace.s3),
        ...trailing,
        const NotificationBell(count: 3),
        const SizedBox(width: USpace.s2),
        CircleAvatar(radius: 17, backgroundColor: c.primary, child: Text('ر', style: UType.label(color: c.onPrimary).weight(700))),
      ]),
    );
  }
}

// ============================================================ البانر والرسوم والحالات

/// بانر الترحيب: المكان المزخرف الوحيد بالرئيسية (نقش + قرص + ميلان)
class HeroBanner extends StatelessWidget {
  const HeroBanner({super.key, required this.greeting, required this.subtitle, this.action, this.tag});
  final String greeting, subtitle;
  final String? tag;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = UGColors.of(context);
    return ClipPath(
      clipper: ShapeBorderClipper(shape: const CutCardBorder(radius: URadius.hero, cut: 26), textDirection: Directionality.of(context)),
      child: Container(
        height: 156,
        color: c.hero,
        child: Stack(children: [
          const Positioned.fill(child: OrnamentPattern(colors: UOrnColors.dark, opacity: UOrnament.heroPattern)),
          PositionedDirectional(
            end: 160,
            top: 0,
            bottom: 0,
            child: Transform(transform: Matrix4.skewX(-.25), child: Container(width: 26, color: c.primary.withValues(alpha: .9))),
          ),
          PositionedDirectional(end: 196, top: 0, bottom: 0, child: Transform(transform: Matrix4.skewX(-.25), child: Container(width: 5, color: c.accent))),
          PositionedDirectional(end: -70, top: -60, child: Opacity(opacity: UOrnament.heroPlate + .1, child: const PlateRing(size: 270, colors: UOrnColors.dark))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: USpace.s8),
            child: Row(children: [
              Expanded(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (tag != null) ...[SlantTag(tag!), const SizedBox(height: USpace.s3)],
                  Text(greeting, style: UType.displayMd(color: Colors.white)),
                  const SizedBox(height: USpace.s1),
                  Text(subtitle, style: UType.body(color: const Color(0xFFC9C9C0))),
                ]),
              ),
              if (action != null) Padding(padding: const EdgeInsetsDirectional.only(end: 230), child: action!),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// أعمدة التكرار: رؤوس مائلة، تطلع بالتتابع، وآخر عمود برتقالي
class RepBarChart extends StatefulWidget {
  const RepBarChart({super.key, required this.values, required this.labels, this.height = 190, this.format});
  final List<double> values;
  final List<String> labels;
  final double height;
  final String Function(double)? format;

  @override
  State<RepBarChart> createState() => _RepBarChartState();
}

class _RepBarChartState extends State<RepBarChart> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: UMotionValues.bars + UMotionValues.barStep * widget.values.length);
  int? _hover;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (UMotion.reduced(context)) {
      _c.value = 1;
    } else if (_c.value == 0) {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = UGColors.of(context);
    final mx = widget.values.reduce(math.max);
    final n = widget.values.length;
    final total = _c.duration!.inMilliseconds;
    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < n; i++)
              Expanded(
                child: MouseRegion(
                  onEnter: (_) => setState(() => _hover = i),
                  onExit: (_) => setState(() => _hover = null),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                      AnimatedOpacity(
                        opacity: _hover == i ? 1 : 0,
                        duration: UMotionValues.fast,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(color: c.ink, borderRadius: BorderRadius.circular(5)),
                          child: Text(widget.format?.call(widget.values[i]) ?? CountUp.format(widget.values[i], 0), style: UType.caption(color: c.bg), textDirection: TextDirection.ltr),
                        ),
                      ),
                      Builder(builder: (context) {
                        final start = (UMotionValues.barStep.inMilliseconds * i) / total;
                        final t = UMotionValues.standard.transform(((_c.value - start) / (1 - start)).clamp(0.0, 1.0));
                        final h = (widget.height - 44) * widget.values[i] / mx * t;
                        final last = i == n - 1;
                        return ClipPath(
                          clipper: _SlantTopClipper(),
                          child: AnimatedContainer(
                            duration: UMotionValues.fast,
                            height: math.max(h, 0),
                            color: last ? c.primary : (_hover == i ? c.lineStrong : c.line),
                          ),
                        );
                      }),
                      const SizedBox(height: 6),
                      Text(widget.labels[i], style: UType.caption(color: i == n - 1 ? c.ink : c.inkMuted)),
                    ]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SlantTopClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size s) {
    final d = math.min(10.0, s.height);
    return Path()
      ..moveTo(0, d)
      ..lineTo(s.width, 0)
      ..lineTo(s.width, s.height)
      ..lineTo(0, s.height)
      ..close();
  }

  @override
  bool shouldReclip(_SlantTopClipper o) => false;
}

/// الحالة الفارغة: مؤقت + فاصل نبض + عنوان Changa + زر. دعوة وليست اعتذاراً
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.title, required this.message, this.actionLabel, this.onAction, this.icon = Icons.add_rounded});
  final String title, message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = UGColors.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const TimerDial(size: 150),
          const SizedBox(height: USpace.s5),
          Text(title, style: UType.displayMd(color: c.ink), textAlign: TextAlign.center),
          const SizedBox(height: USpace.s2),
          const PulseDivider(width: 200),
          const SizedBox(height: USpace.s2),
          Text(message, style: UType.body(color: c.inkMuted), textAlign: TextAlign.center),
          if (actionLabel != null) ...[const SizedBox(height: USpace.s5), UGButton(label: actionLabel!, icon: icon, onPressed: onAction ?? () {})],
        ]),
      ),
    );
  }
}

/// عنوان الصفحة مع شرح وأزرار
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.subtitle, this.actions = const []});
  final String title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final c = UGColors.of(context);
    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: UType.h1(color: c.ink)),
          if (subtitle != null) Text(subtitle!, style: UType.body(color: c.inkMuted)),
        ]),
      ),
      for (final a in actions) Padding(padding: const EdgeInsetsDirectional.only(start: USpace.s2), child: a),
    ]);
  }
}
