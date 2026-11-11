import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import 'demo_shape.dart';

/// بطاقة التجربة: زوايا 20، حد رفيع، ظل ناعم طويل. عند المرور (إن كانت تُضغط) تفتح خلفيتها قليلاً
/// ويكبر ظلها وترتفع؛ والعنوان + سطر شرح + زر نصي بالأعلى كـ `SectionCard`.
class DemoCard extends StatelessWidget {
  const DemoCard({
    super.key,
    this.title,
    this.subtitle,
    this.action,
    this.onAction,
    this.onTap,
    this.trailing,
    this.padding = const EdgeInsets.all(AppSpace.s5),
    required this.child,
  });

  final String? title, subtitle, action;
  final VoidCallback? onAction, onTap;

  /// عنصر إضافي بالرأس قبل الزر النصي (مثلاً تبويبات الفترة).
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final d = AppPalette.of(context);
    final t = title;
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (t != null) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t, style: UType.h3(color: d.ink)),
                    if (subtitle case final s?) Text(s, style: UType.caption(color: d.muted)),
                  ],
                ),
              ),
              ?trailing,
              if (action case final a?) DemoLink(label: a, onTap: onAction),
            ],
          ),
          AppSpace.gap4,
        ],
        child,
      ],
    );
    return HoverLift(
      builder: (context, hover) {
        final lit = hover && onTap != null;
        return AnimatedContainer(
          duration: AppMotion.of(context, AppMotion.normal),
          curve: DemoShape.ease,
          decoration: BoxDecoration(
            color: lit ? d.card2 : d.card,
            borderRadius: DemoShape.lgAll,
            border: Border.all(color: d.line),
            boxShadow: lit ? d.shadowLg : d.shadow,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              borderRadius: DemoShape.lgAll,
              hoverColor: Colors.transparent,
              splashColor: d.well,
              highlightColor: d.well,
              child: Padding(padding: padding, child: body),
            ),
          ),
        );
      },
    );
  }
}

/// زر نصي صغير بأعلى البطاقة ("كل الورديات") بلون الحبر البرتقالي، يتحول لخلفية هادئة عند المرور.
class DemoLink extends StatelessWidget {
  const DemoLink({super.key, required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final d = AppPalette.of(context);
    return TextButton(
      onPressed: onTap ?? () {},
      style: TextButton.styleFrom(
        foregroundColor: d.accentText,
        overlayColor: d.accent,
        shape: const RoundedRectangleBorder(borderRadius: DemoShape.smAll),
        textStyle: UType.label(),
      ),
      child: Text(label),
    );
  }
}

enum DemoButtonKind { primary, ghost }

/// أزرار التجربة: الأساسي تدرج برتقالي بحافة ضوء علوية وتوهج تحته (يلمع قليلاً عند المرور)،
/// والثانوي "زجاجي" بخلفية البطاقة وحد رفيع (يغمق عند المرور). كلاهما يصغر 0.97 لحظة الضغط.
class DemoButton extends StatelessWidget {
  const DemoButton({super.key, required this.label, this.icon, this.kind = DemoButtonKind.primary, this.onPressed});

  final String label;
  final IconData? icon;
  final DemoButtonKind kind;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final d = AppPalette.of(context);
    final primary = kind == DemoButtonKind.primary;
    final fg = primary ? d.accentInk : d.ink;
    return Semantics(
      button: true,
      enabled: onPressed != null,
      child: PressScale(
        onTap: onPressed,
        child: HoverLift(
          builder: (context, hover) => AnimatedContainer(
            duration: AppMotion.of(context, AppMotion.fast),
            curve: DemoShape.ease,
            height: AppSize.control,
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.s5),
            decoration: BoxDecoration(
              gradient: primary ? d.gradient : null,
              color: primary ? null : (hover ? d.card3 : d.card),
              borderRadius: DemoShape.mdAll,
              border: Border.all(color: primary ? d.accentFrom : d.line2),
              boxShadow: primary ? [...d.glow, if (hover) ...d.glow] : null,
            ),
            foregroundDecoration: primary && hover
                ? BoxDecoration(color: d.card.withValues(alpha: .06), borderRadius: DemoShape.mdAll)
                : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: AppSpace.s2,
              children: [
                if (icon case final i?) Icon(i, size: AppSize.iconSm, color: fg),
                Text(label, style: UType.label(color: fg).weight(600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// تبويبات صغيرة داخل "بئر" (`seg` بالتجربة): المختار بخلفية البطاقة وظلها، والباقي باهت يقوى عند المرور.
class DemoSegmented<T> extends StatelessWidget {
  const DemoSegmented({super.key, required this.options, required this.value, required this.onChanged});

  final List<({T value, String label})> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final d = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpace.s1),
      decoration: BoxDecoration(
        color: d.well,
        borderRadius: DemoShape.mdAll,
        border: Border.all(color: d.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final o in options)
            Semantics(
              button: true,
              selected: o.value == value,
              child: PressScale(
                onTap: () => onChanged(o.value),
                child: HoverLift(
                  builder: (context, hover) {
                    final on = o.value == value;
                    return AnimatedContainer(
                      duration: AppMotion.of(context, AppMotion.fast),
                      curve: DemoShape.ease,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpace.s3, vertical: AppSpace.s1),
                      decoration: BoxDecoration(
                        color: on ? d.card3 : null,
                        borderRadius: DemoShape.smAll,
                        boxShadow: on ? d.shadow.take(1).toList() : null,
                      ),
                      child: Text(
                        o.label,
                        style: UType.caption(color: on || hover ? d.ink : d.muted).weight(on ? 600 : 500),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
