import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/gate_message.dart';

/// تعذّر الوصول للخادم أثناء استعادة الجلسة: إعادة المحاولة (والجلسة المحفوظة تبقى).
class OfflineScreen extends StatelessWidget {
  const OfflineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final message = context.select<AuthBloc, String?>((b) => b.state.message);
    return AuthScaffold(
      showLogo: false,
      child: GateMessage(
        icon: Icons.wifi_off_rounded,
        tone: UTone.info,
        title: 'لا يوجد اتصال',
        message: message ?? ErrorHandler.defaultMessage(FailureType.network),
        primary: UGButton(
          label: 'إعادة المحاولة',
          icon: Icons.refresh_rounded,
          expand: true,
          large: true,
          onPressed: () => context.read<AuthBloc>().add(const AuthStarted()),
        ),
      ),
    );
  }
}
