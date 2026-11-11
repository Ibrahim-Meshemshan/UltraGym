import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../bloc/auth_bloc.dart';
import 'auth_scaffold.dart';

/// محتوى شاشات البوابة (لا اتصال، حجب، تحديث مطلوب): أيقونة بنغمة + عنوان + رسالة + زر أساسي + خروج.
class GateMessage extends StatelessWidget {
  const GateMessage({
    super.key,
    required this.icon,
    required this.tone,
    required this.title,
    required this.message,
    required this.primary,
    this.showLogout = true,
  });

  final IconData icon;
  final UTone tone;
  final String title, message;
  final Widget primary;
  final bool showLogout;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (bg, fg) = tone.colors(c);
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Center(
        child: Container(
          width: AppSpace.s16,
          height: AppSpace.s16,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Icon(icon, color: fg, size: AppSpace.s8),
        ),
      ),
      AppSpace.gap4,
      AuthHeading(title),
      AppSpace.gap2,
      Text(message, style: UType.body(color: c.inkMuted), textAlign: TextAlign.center),
      AppSpace.gap6,
      primary,
      if (showLogout) ...[
        AppSpace.gap2,
        UGButton(
          label: 'تسجيل الخروج',
          kind: UButtonKind.ghost,
          onPressed: () => context.read<AuthBloc>().add(const AuthLogoutRequested()),
        ),
      ],
    ]);
  }
}
