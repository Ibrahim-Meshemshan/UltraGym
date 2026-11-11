import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../data/repo/auth_repository.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_scaffold.dart';

/// تغيير كلمة السر المؤقتة إجبارياً: لا يُسمح بغيرها حتى تُغيَّر (الخادم يرجع 403 لأي طلب آخر).
class ChangePasswordScreen extends StatelessWidget {
  const ChangePasswordScreen({super.key});

  Future<void> _submit(BuildContext context) async {
    final form = context.read<AppFormCubit>();
    final auth = context.read<AuthBloc>();
    final r = await form.submit((f) => sl<AuthRepository>().changePassword(f.apiBody()));
    if (r case ApiSuccess<void>(:final message)) {
      AppSnackbar.show(message ?? 'تم تغيير كلمة السر.');
      auth.add(const AuthPasswordChanged());
    }
  }

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => AppFormCubit(),
    child: AuthScaffold(
      showLogo: false,
      child: Builder(
        builder: (context) {
          final form = context.read<AppFormCubit>();
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AuthHeading('اختر كلمة سر جديدة', subtitle: 'دخلت بكلمة سر مؤقتة من النادي. غيّرها لتكمل.'),
              const FormErrorBanner(),
              AppSpace.gap5,
              FormColumn(
                children: [
                  FormPassword(
                    'current_password',
                    label: 'كلمة السر المؤقتة',
                    validator: Validators.required('اكتب كلمة السر المؤقتة.'),
                  ),
                  FormPassword(
                    'new_password',
                    label: 'كلمة السر الجديدة (8 أحرف، فيها حرف ورقم)',
                    validator: Validators.newPassword(),
                  ),
                  FormPassword(
                    'new_password_confirmation',
                    label: 'تأكيد كلمة السر',
                    validator: Validators.matches(() => form.text('new_password').text),
                    onSubmitted: (_) => _submit(context),
                  ),
                ],
              ),
              AppSpace.gap6,
              BlocSelector<AppFormCubit, AppFormState, bool>(
                selector: (s) => s.submitting,
                builder: (context, busy) => UGButton(
                  label: busy ? 'جارٍ الحفظ…' : 'حفظ والمتابعة',
                  expand: true,
                  large: true,
                  onPressed: busy ? null : () => _submit(context),
                ),
              ),
              AppSpace.gap2,
              UGButton(
                label: 'تسجيل الخروج',
                kind: UButtonKind.ghost,
                onPressed: () => context.read<AuthBloc>().add(const AuthLogoutRequested()),
              ),
            ],
          );
        },
      ),
    ),
  );
}
