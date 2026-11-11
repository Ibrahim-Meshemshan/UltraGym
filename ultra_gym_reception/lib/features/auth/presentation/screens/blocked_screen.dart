import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/gate_message.dart';

/// حجب: النادي موقوف أو اشتراكه بالمنصة غير فعّال. رسالة الخادم كما هي.
class BlockedScreen extends StatelessWidget {
  const BlockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final message = context.select<AuthBloc, String?>((b) => b.state.message);
    return AuthScaffold(
      showLogo: false,
      child: GateMessage(
        icon: Icons.lock_outline_rounded,
        tone: UTone.danger,
        title: 'الوصول محجوب',
        message: message ?? ErrorHandler.defaultMessage(FailureType.tenantSuspended),
        primary: UGButton(
          label: 'إعادة المحاولة',
          icon: Icons.refresh_rounded,
          kind: UButtonKind.secondary,
          expand: true,
          large: true,
          onPressed: () => context.read<AuthBloc>().add(const AuthStarted()),
        ),
      ),
    );
  }
}
