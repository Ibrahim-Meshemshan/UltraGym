import 'package:flutter/material.dart';

import '../../../../core/core.dart';

/// شاشة البدء: الشعار على لون الهيكل أثناء استعادة الجلسة (`GET /auth/me`).
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.sidebar,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Entrance(child: UltraGymLogo(variant: ULogo.vertical, onDark: true, height: 120)),
            AppSpace.gap6,
            Entrance(
              index: 1,
              child: Text(AppConfig.appTitle, style: UType.h3(color: c.sidebarInk)),
            ),
          ],
        ),
      ),
    );
  }
}
