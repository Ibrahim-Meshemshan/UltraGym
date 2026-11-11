import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import 'demo_shape.dart';

/// سطر صغير تحت الرقم كحبة ملونة ("+ جدد هذا الشهر: 3") أو نص باهت بلا نغمة.
typedef DemoNote = ({String text, UTone? tone});

/// بطاقة رقم (`kpi` بالتجربة): أيقونة بمربع هادئ واسم القسم، الرقم كبيراً يعدّ صعوداً، ثم الملاحظة.
/// المرور يرفع البطاقة ويفتح خلفيتها ويلوّن الأيقونة بالبرتقالي. الضغط يفتح القسم.
class DemoKpi extends StatelessWidget {
  const DemoKpi({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.prefix = '',
    this.decimals = 0,
    this.note,
    this.onTap,
  });

  final IconData icon;
  final String label, prefix;
  final double value;
  final int decimals;
  final DemoNote? note;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final d = AppPalette.of(context);
    return Semantics(
      button: onTap != null,
      label: label,
      child: HoverLift(
        builder: (context, hover) => AnimatedContainer(
          duration: AppMotion.of(context, AppMotion.normal),
          curve: DemoShape.ease,
          decoration: BoxDecoration(
            color: hover ? d.card2 : d.card,
            borderRadius: DemoShape.lgAll,
            border: Border.all(color: d.line),
            boxShadow: hover ? d.shadowLg : d.shadow,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              borderRadius: DemoShape.lgAll,
              hoverColor: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.s4),
                child: _KpiBody(
                  icon: icon,
                  label: label,
                  value: CountUp(
                    value,
                    prefix: prefix,
                    decimals: decimals,
                    style: UType.stat(color: d.ink),
                  ),
                  note: note,
                  iconBg: hover ? d.accentSoft : d.well,
                  iconFg: hover ? d.accentText : d.muted,
                  labelColor: d.muted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// البطاقة الرئيسية بالتدرج البرتقالي والتوهج: الرقم الأهم، حبة ملاحظة، وشريط مقسّم يبيّن أجزاءه
/// (كل جزء بنسبة قيمته من الخادم إلى مجموعها؛ رسم لا حساب حالة). يتوهج أكثر عند المرور.
class DemoHeroKpi extends StatelessWidget {
  const DemoHeroKpi({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.parts,
    this.note,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final double value;
  final List<({String label, int value})> parts;
  final DemoNote? note;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final d = AppPalette.of(context);
    const on = AppPalette.onGradient;
    return Semantics(
      button: onTap != null,
      label: label,
      child: HoverLift(
        builder: (context, hover) => AnimatedContainer(
          duration: AppMotion.of(context, AppMotion.normal),
          curve: DemoShape.ease,
          decoration: BoxDecoration(
            gradient: d.gradient,
            borderRadius: DemoShape.lgAll,
            boxShadow: [...d.glow, if (hover) ...d.glow],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              borderRadius: DemoShape.lgAll,
              hoverColor: on.withValues(alpha: .06),
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _KpiBody(
                      icon: icon,
                      label: label,
                      value: CountUp(value, style: UType.stat(color: on)),
                      note: note,
                      iconBg: on.withValues(alpha: .18),
                      iconFg: on,
                      labelColor: on.withValues(alpha: .9),
                      onGradient: true,
                    ),
                    AppSpace.gap3,
                    _Meter(parts: parts),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _KpiBody extends StatelessWidget {
  const _KpiBody({
    required this.icon,
    required this.label,
    required this.value,
    required this.note,
    required this.iconBg,
    required this.iconFg,
    required this.labelColor,
    this.onGradient = false,
  });

  final IconData icon;
  final String label;
  final Widget value;
  final DemoNote? note;
  final Color iconBg, iconFg, labelColor;
  final bool onGradient;

  @override
  Widget build(BuildContext context) {
    final d = AppPalette.of(context);
    final n = note;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          spacing: AppSpace.s2,
          children: [
            AnimatedContainer(
              duration: AppMotion.of(context, AppMotion.fast),
              width: AppSize.controlSm,
              height: AppSize.controlSm,
              decoration: BoxDecoration(color: iconBg, borderRadius: DemoShape.smAll),
              child: Icon(icon, size: AppSize.iconSm, color: iconFg),
            ),
            Expanded(
              child: Text(
                label,
                style: UType.label(color: labelColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        AppSpace.gap3,
        FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart, child: value),
        if (n != null) ...[AppSpace.gap2, _Pill(note: n, onGradient: onGradient, palette: d)],
      ],
    );
  }
}

/// الملاحظة: حبة بخلفية النغمة الهادئة، أو نص باهت. فوق التدرج: حبة داكنة شفافة بنص أبيض.
class _Pill extends StatelessWidget {
  const _Pill({required this.note, required this.onGradient, required this.palette});

  final DemoNote note;
  final bool onGradient;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final tone = note.tone;
    final text = Text(
      note.text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: UType.caption(
        color: onGradient ? AppPalette.onGradient : (tone == null ? palette.muted : tone.colors(context.colors).$2),
      ).weight(onGradient || tone != null ? 600 : 400),
    );
    if (tone == null && !onGradient) return text;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.s2, vertical: AppSpace.s1),
      decoration: BoxDecoration(
        color: onGradient ? palette.accentInk.withValues(alpha: .22) : tone!.colors(context.colors).$1,
        borderRadius: DemoShape.smAll,
      ),
      child: text,
    );
  }
}

/// شريط مقسّم بنسب الأجزاء يكبر من البداية عند الدخول، وتحته أسماء الأجزاء بقيمها.
class _Meter extends StatelessWidget {
  const _Meter({required this.parts});

  final List<({String label, int value})> parts;

  @override
  Widget build(BuildContext context) {
    final total = parts.fold<int>(0, (s, p) => s + p.value);
    if (total == 0) return const SizedBox.shrink();
    const on = AppPalette.onGradient;
    final shades = [on, on.withValues(alpha: .55), on.withValues(alpha: .3)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.s2,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: AppMotion.of(context, AppMotion.entrance),
          curve: DemoShape.ease,
          builder: (context, t, _) => ClipRRect(
            borderRadius: AppRadius.fullAll,
            child: SizedBox(
              height: DemoShape.meter,
              child: ColoredBox(
                color: on.withValues(alpha: .18),
                child: FractionallySizedBox(
                  alignment: AlignmentDirectional.centerStart,
                  widthFactor: t,
                  child: Row(
                    children: [
                      for (var i = 0; i < parts.length; i++)
                        if (parts[i].value > 0)
                          Expanded(
                            flex: parts[i].value,
                            child: ColoredBox(color: shades[i % shades.length]),
                          ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Wrap(
          spacing: AppSpace.s3,
          runSpacing: AppSpace.s1,
          children: [
            for (var i = 0; i < parts.length; i++)
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: AppSpace.s1,
                children: [
                  Container(
                    width: DemoShape.meter,
                    height: DemoShape.meter,
                    decoration: BoxDecoration(color: shades[i % shades.length], shape: BoxShape.circle),
                  ),
                  Text('${parts[i].label} ${parts[i].value}', style: UType.caption(color: on)),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
