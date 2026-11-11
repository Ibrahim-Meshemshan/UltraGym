import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/core.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/login_cubit.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/login_form.dart';
import '../widgets/tenant_picker.dart';

/// الدخول: البيانات ثم اختيار النادي إن لزم. النجاح يبلّغ AuthBloc فيوجّه الراوتر.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(create: (_) => AppFormCubit()),
      BlocProvider(create: (_) => sl<LoginCubit>()),
    ],
    child: BlocListener<LoginCubit, LoginState>(
      listenWhen: (a, b) => b.session != null && a.session != b.session,
      listener: (context, s) {
        // الويب: حقل كلمة السر المخفي يبقى ممسكاً بتركيز المتصفح بعد الانتقال فيبتلع الكتابة
        // والاختصارات (Ctrl K). نحرّره ونغلق سياق الحفظ التلقائي قبل مغادرة الشاشة.
        FocusManager.instance.primaryFocus?.unfocus();
        TextInput.finishAutofillContext();
        context.read<AuthBloc>().add(AuthLoggedIn(s.session!));
      },
      child: AuthScaffold(
        child: BlocBuilder<LoginCubit, LoginState>(
          buildWhen: (a, b) => a.choosingTenant != b.choosingTenant,
          builder: (context, s) {
            final duration = AppMotion.of(context, AppMotion.normal);
            return AnimatedSwitcher(
              duration: duration,
              child: s.choosingTenant
                  ? const TenantPicker(key: ValueKey('tenants'))
                  : const LoginForm(key: ValueKey('credentials')),
            );
          },
        ),
      ),
    ),
  );
}
