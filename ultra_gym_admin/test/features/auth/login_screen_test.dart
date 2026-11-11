import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:ultra_gym_admin/core/error/failure.dart';
import 'package:ultra_gym_admin/core/networking/api_result.dart';
import 'package:ultra_gym_admin/core/networking/auth_interceptor.dart';
import 'package:ultra_gym_admin/core/theme/app_theme.dart';
import 'package:ultra_gym_admin/features/auth/domain/models/auth_models.dart';
import 'package:ultra_gym_admin/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ultra_gym_admin/features/auth/presentation/bloc/login_cubit.dart';
import 'package:ultra_gym_admin/features/auth/presentation/screens/login_screen.dart';

import 'fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repo;
  late AuthBloc auth;

  setUp(() {
    repo = FakeAuthRepository();
    auth = AuthBloc(repo, SessionEvents());
    GetIt.instance.registerFactory<LoginCubit>(() => LoginCubit(repo));
  });

  tearDown(() async {
    await GetIt.instance.reset();
    await auth.close();
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      BlocProvider.value(
        value: auth,
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          // "تقليل الحركة": الزخارف الدائمة تقف فيستقر الاختبار.
          builder: (context, child) =>
              MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: true), child: child!),
          home: const LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('validates locally, shows server errors, then picks a club and logs in', (tester) async {
    await pump(tester);
    await tester.tap(find.text('دخول'));
    await tester.pumpAndSettle();
    expect(find.text('اكتب كلمة السر.'), findsOneWidget);
    expect(repo.calls, isEmpty);

    repo.loginResults.addAll([
      const ApiFailure(Failure(type: FailureType.invalidCredentials, message: 'الموبايل أو كلمة السر غير صحيحة.')),
      const ApiSuccess(
        LoginNeedsTenant([
          TenantChoice(
            tenant: TenantRef(id: 12, name: 'نادي القمة الرياضي'),
            roles: ['club_owner'],
          ),
          TenantChoice(
            tenant: TenantRef(id: 15, name: 'نادي الأبطال'),
            roles: ['receptionist'],
          ),
        ]),
      ),
      const ApiSuccess(LoginSucceeded(testSession)),
    ]);
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '0933100001');
    await tester.enterText(fields.at(1), 'wrong');
    await tester.tap(find.text('دخول'));
    await tester.pumpAndSettle();
    expect(find.text('الموبايل أو كلمة السر غير صحيحة.'), findsOneWidget);

    await tester.tap(find.text('دخول'));
    await tester.pumpAndSettle();
    expect(find.text('اختر النادي'), findsOneWidget);
    expect(find.text('موظف استقبال'), findsNothing);
    expect(find.text('استقبال'), findsOneWidget);

    await tester.tap(find.text('نادي الأبطال'));
    await tester.pumpAndSettle();
    expect(repo.loginTenants.last, 15);
    expect(auth.state.status, AuthStatus.authenticated);
    expect(auth.state.session, testSession);
  });
}
