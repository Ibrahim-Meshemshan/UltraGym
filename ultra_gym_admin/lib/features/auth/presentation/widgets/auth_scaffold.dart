import 'package:flutter/material.dart';

import '../../../../core/core.dart';

/// هيكل شاشات ما قبل الدخول: أرضية داكنة بالثيمين بنقش السرعة والأقراص والشريط (المكان المزخرف الوحيد)،
/// وبطاقة بإطار مائل وظل عائم. الزخارف تقف مع "تقليل الحركة" (من الحزمة).
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.child, this.showLogo = true});

  final Widget child;
  final bool showLogo;

  @override
  Widget build(BuildContext context) => Theme(
    data: AppTheme.dark,
    child: Builder(
      builder: (context) {
        final c = context.colors;
        final orn = AppPalette.dark.ornaments;
        final mobile = context.isMobile;
        return Scaffold(
          backgroundColor: c.bg,
          body: Stack(
            children: [
              Positioned.fill(
                child: OrnamentPattern(colors: orn, opacity: UOrnament.loginPattern),
              ),
              PositionedDirectional(
                end: -140,
                bottom: -160,
                child: Opacity(
                  opacity: UOrnament.loginPlate,
                  child: PlateRing(size: mobile ? 380 : 560, colors: orn),
                ),
              ),
              PositionedDirectional(
                start: 0,
                end: 0,
                bottom: 0,
                child: TrackBand(height: AppSpace.s10, colors: orn),
              ),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpace.s5),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: _Card(showLogo: showLogo, child: child),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.child, required this.showLogo});

  final Widget child;
  final bool showLogo;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final pad = context.isMobile ? AppSpace.s6 : AppSpace.s8;
    return Entrance(
      child: Container(
        padding: EdgeInsets.fromLTRB(pad, pad, pad, AppSpace.s6),
        decoration: ShapeDecoration(
          color: c.surface,
          shape: SlantFrameBorder(side: BorderSide(color: c.line)),
          shadows: [BoxShadow(color: c.sidebar.withValues(alpha: .6), blurRadius: 60, offset: const Offset(0, 24))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showLogo) ...[
              Center(
                child: UltraGymLogo(variant: ULogo.vertical, onDark: true, height: context.isMobile ? 96 : 112),
              ),
              AppSpace.gap3,
              Center(child: PulseDivider(width: 200, colors: AppPalette.dark.ornaments)),
              AppSpace.gap4,
            ],
            child,
          ],
        ),
      ),
    );
  }
}

/// عنوان الخطوة: Changa للترحيب + سطر شرح.
class AuthHeading extends StatelessWidget {
  const AuthHeading(this.title, {super.key, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        Text(
          title,
          style: UType.displayMd(color: c.ink),
          textAlign: TextAlign.center,
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: UType.body(color: c.inkMuted),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }
}

/// رسالة معلومة أعلى البطاقة (انتهاء الجلسة، إيقاف الحساب).
class AuthNotice extends StatelessWidget {
  const AuthNotice(this.message, {super.key, this.tone = UTone.warning});

  final String message;
  final UTone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = tone.colors(context.colors);
    return Container(
      padding: const EdgeInsets.all(AppSpace.s3),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.smAll),
      child: Text(message, style: UType.body(color: fg)),
    );
  }
}
