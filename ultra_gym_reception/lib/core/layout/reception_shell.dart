import 'package:flutter/material.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../core.dart';
import 'reception_top_bar.dart';

/// هيكل الاستقبال: شريط أيقونات ضيق (يختفي على الموبايل) + الشريط العلوي + تنبيه الانقطاع + الشاشة.
/// الأقسام الأخرى (البيع، الصندوق، المزامنة) تُضاف للشريط حين تُبنى.
class ReceptionShell extends StatelessWidget {
  const ReceptionShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final impersonated = context.select<AuthBloc, bool>((b) => b.state.session?.isImpersonated ?? false);
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!context.isMobile) const _Rail(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const ReceptionTopBar(),
                  if (impersonated)
                    _Strip(text: 'جلسة دعم من فريق UltraGym', bg: c.warningSoft, fg: c.warningInk),
                  BlocBuilder<ConnectionCubit, ConnectionStatus>(
                    bloc: sl<ConnectionCubit>(),
                    builder: (context, status) => status == ConnectionStatus.offline
                        ? _Strip(
                            text: 'لا اتصال بالخادم. تسجيل الدخول والبحث يحتاجان اتصالاً حتى يُفعَّل العمل دون اتصال '
                                'على هذا الجهاز. قارئ الباركود والمسح يعودان للعمل مع عودة الإنترنت.',
                            bg: c.warningSoft,
                            fg: c.warningInk,
                          )
                        : const SizedBox.shrink(),
                  ),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Strip extends StatelessWidget {
  const _Strip({required this.text, required this.bg, required this.fg});

  final String text;
  final Color bg, fg;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.s6, vertical: AppSpace.s2),
      child: Text(text, style: UType.label(color: fg)),
    ),
  );
}

/// الشريط الجانبي الضيق بلون الهيكل: الشعار ثم الأقسام (الآن محطة الدخول فقط).
class _Rail extends StatelessWidget {
  const _Rail();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: AppSize.rail,
      color: c.sidebar,
      padding: const EdgeInsets.symmetric(vertical: AppSpace.s4),
      child: Column(
        spacing: AppSpace.s4,
        children: [
          UltraGymLogo(variant: ULogo.mark, onDark: context.isDark, height: AppSize.control),
          Tooltip(
            message: 'محطة الدخول',
            child: Semantics(
              selected: true,
              button: true,
              label: 'محطة الدخول',
              child: Container(
                width: AppSize.minTap,
                height: AppSize.minTap,
                decoration: BoxDecoration(color: c.accent, borderRadius: AppRadius.fieldAll),
                child: Icon(Icons.qr_code_scanner_rounded, color: c.onAccent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

