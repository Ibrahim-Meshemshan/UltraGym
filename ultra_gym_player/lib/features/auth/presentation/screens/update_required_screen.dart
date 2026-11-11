import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../domain/models/auth_models.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/gate_message.dart';

/// التحديث الإجباري (`force_update`): يمنع الاستعمال حتى التحديث من المتجر.
class UpdateRequiredScreen extends StatelessWidget {
  const UpdateRequiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final v = context.select<AuthBloc, AppVersionInfo?>((b) => b.state.version);
    final store = v?.storeUrl;
    return AuthScaffold(
      showLogo: false,
      child: GateMessage(
        icon: Icons.system_update_rounded,
        tone: UTone.primary,
        title: 'تحديث مطلوب',
        showLogout: false,
        message: 'نسختك ${v?.current ?? AppConfig.appVersion} لم تعد مدعومة. حدّث التطبيق للنسخة ${v?.latest ?? 'الأحدث'} لتكمل.',
        primary: UGButton(
          label: 'فتح المتجر',
          icon: Icons.open_in_new_rounded,
          expand: true,
          large: true,
          onPressed: store == null ? null : () => Launcher.url(store),
        ),
      ),
    );
  }
}
