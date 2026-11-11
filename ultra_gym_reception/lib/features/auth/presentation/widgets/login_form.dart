import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../auth_copy.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/login_cubit.dart';
import 'auth_scaffold.dart';

/// خطوة البيانات: الموبايل أو المعرّف + كلمة السر. أخطاء الخادم (بيانات خاطئة، قفل 15 دقيقة) أعلى النموذج.
class LoginForm extends StatelessWidget {
  const LoginForm({super.key});

  void _submit(BuildContext context) => context.read<LoginCubit>().submit(context.read<AppFormCubit>());

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final notice = context.select<AuthBloc, String?>((b) => b.state.message);
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const AuthHeading(AuthCopy.title, subtitle: AuthCopy.subtitle),
      if (notice != null) ...[AppSpace.gap4, AuthNotice(notice)],
      const FormErrorBanner(),
      AppSpace.gap5,
      FormColumn(children: [
        FormText(
          'phone',
          label: AuthCopy.identityLabel,
          required: true,
          ltr: true,
          autofocus: true,
          validator: Validators.required('اكتب ${AuthCopy.identityLabel}.'),
          textInputAction: TextInputAction.next,
        ),
        FormPassword(
          'password',
          label: 'كلمة السر',
          validator: Validators.required('اكتب كلمة السر.'),
          onSubmitted: (_) => _submit(context),
        ),
      ]),
      AppSpace.gap6,
      BlocSelector<AppFormCubit, AppFormState, bool>(
        selector: (s) => s.submitting,
        builder: (context, busy) => UGButton(
          label: busy ? 'جارٍ الدخول…' : 'دخول',
          expand: true,
          large: true,
          onPressed: busy ? null : () => _submit(context),
        ),
      ),
      AppSpace.gap4,
      Text(AuthCopy.forgotPassword, style: UType.caption(color: c.inkMuted), textAlign: TextAlign.center),
    ]);
  }
}
