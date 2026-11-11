import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_gym_super_admin/core/bloc/app_form_cubit.dart';
import 'package:ultra_gym_super_admin/core/error/failure.dart';
import 'package:ultra_gym_super_admin/core/networking/api_result.dart';
import 'package:ultra_gym_super_admin/core/networking/auth_interceptor.dart';
import 'package:ultra_gym_super_admin/core/router/app_router.dart';
import 'package:ultra_gym_super_admin/core/router/routes.dart';
import 'package:ultra_gym_super_admin/features/auth/domain/models/auth_models.dart';
import 'package:ultra_gym_super_admin/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ultra_gym_super_admin/features/auth/presentation/bloc/login_cubit.dart';

import 'fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repo;
  late SessionEvents events;
  late AuthBloc bloc;

  setUp(() {
    repo = FakeAuthRepository();
    events = SessionEvents();
    bloc = AuthBloc(repo, events);
  });

  tearDown(() => bloc.close());

  Future<AuthState> settle() => bloc.stream.firstWhere((s) => s.status != AuthStatus.unknown);

  group('AuthBloc restore', () {
    test('no token goes to login without calling the server', () async {
      bloc.add(const AuthStarted());
      expect((await settle()).status, AuthStatus.unauthenticated);
      expect(repo.calls, isNot(contains('me')));
    });

    test('valid token restores the session and registers the device', () async {
      repo.token = true;
      bloc.add(const AuthStarted());
      final s = await settle();
      expect(s.status, AuthStatus.authenticated);
      expect(s.session!.isClubOwner, isTrue);
      expect(repo.calls, contains('registerDevice'));
    });

    test('temporary password forces the change screen', () async {
      repo
        ..token = true
        ..meResult = ApiSuccess(Session.fromJson({
          'user': {'id': 1, 'name': 'x'},
          'must_change_password': true,
        }));
      bloc.add(const AuthStarted());
      expect((await settle()).status, AuthStatus.passwordChangeRequired);
    });

    test('network failure keeps the token and shows offline', () async {
      repo
        ..token = true
        ..meResult = ApiFailure(failureOf(FailureType.network));
      bloc.add(const AuthStarted());
      expect((await settle()).status, AuthStatus.offline);
      expect(repo.token, isTrue);
    });

    test('401 clears the token and returns to login with a message', () async {
      repo
        ..token = true
        ..meResult = ApiFailure(failureOf(FailureType.unauthenticated));
      bloc.add(const AuthStarted());
      final s = await settle();
      expect(s.status, AuthStatus.unauthenticated);
      expect(s.message, isNotNull);
      expect(repo.token, isFalse);
    });

    test('suspended club shows the blocking screen', () async {
      repo
        ..token = true
        ..meResult = ApiFailure(failureOf(FailureType.tenantSuspended));
      bloc.add(const AuthStarted());
      expect((await settle()).status, AuthStatus.blocked);
    });

    test('forced app update stops before the session', () async {
      repo
        ..token = true
        ..version = const AppVersionInfo(current: '1.0.0', latest: '2.0.0', forceUpdate: true);
      bloc.add(const AuthStarted());
      expect((await settle()).status, AuthStatus.updateRequired);
      expect(repo.calls, isNot(contains('me')));
    });
  });

  group('AuthBloc session events', () {
    test('401 from any request logs out locally', () async {
      repo.token = true;
      bloc.add(const AuthStarted());
      await settle();
      events.add(SessionEvent.expired);
      final s = await bloc.stream.firstWhere((s) => s.status == AuthStatus.unauthenticated);
      expect(s.session, isNull);
      expect(repo.calls, contains('clearLocal'));
    });

    test('password change event then AuthPasswordChanged returns to authenticated', () async {
      repo.token = true;
      bloc.add(const AuthStarted());
      await settle();
      events.add(SessionEvent.passwordChangeRequired);
      await bloc.stream.firstWhere((s) => s.status == AuthStatus.passwordChangeRequired);
      bloc.add(const AuthPasswordChanged());
      expect((await bloc.stream.first).status, AuthStatus.authenticated);
    });

    test('logout calls the server and clears the session', () async {
      repo.token = true;
      bloc.add(const AuthStarted());
      await settle();
      bloc.add(const AuthLogoutRequested());
      final s = await bloc.stream.first;
      expect(s.status, AuthStatus.unauthenticated);
      expect(repo.calls, contains('logout'));
    });
  });

  group('LoginCubit', () {
    test('multi-club account picks a tenant, then logs in with tenant_id', () async {
      const choices = [TenantChoice(tenant: TenantRef(id: 12, name: 'نادي القمة')), TenantChoice(tenant: TenantRef(id: 15, name: 'نادي الأبطال'))];
      repo.loginResults.addAll(const [ApiSuccess(LoginNeedsTenant(choices)), ApiSuccess(LoginSucceeded(testSession))]);
      final login = LoginCubit(repo);
      final form = AppFormCubit();
      form.text('phone').text = '0933100001';
      form.text('password').text = 'Demo@2026';

      await login.submit(form);
      expect(login.state.choosingTenant, isTrue);
      expect(login.state.tenants, hasLength(2));

      await login.submit(form, tenantId: 15);
      expect(repo.loginTenants, [null, 15]);
      expect(login.state.session, testSession);
      await login.close();
      await form.close();
    });

    test('wrong credentials stay on the form with the server message', () async {
      repo.loginResults.add(ApiFailure(failureOf(FailureType.invalidCredentials)));
      final login = LoginCubit(repo);
      final form = AppFormCubit();
      await login.submit(form);
      expect(login.state.session, isNull);
      expect(form.state.failure!.type, FailureType.invalidCredentials);
      await login.close();
      await form.close();
    });
  });

  group('authRedirect', () {
    Uri u(String s) => Uri.parse(s);

    test('unknown always shows splash, keeping the requested page', () {
      expect(authRedirect(AuthStatus.unknown, u('/home')), '/?from=%2Fhome');
      expect(authRedirect(AuthStatus.unknown, u('/')), isNull);
    });

    test('logged out goes to login, and back to the requested page after login', () {
      expect(authRedirect(AuthStatus.unauthenticated, u('/?from=%2Fmembers%2F3')), '/login?from=%2Fmembers%2F3');
      expect(authRedirect(AuthStatus.authenticated, u('/login?from=%2Fmembers%2F3')), '/members/3');
      expect(authRedirect(AuthStatus.authenticated, u('/login')), Routes.home);
      expect(authRedirect(AuthStatus.authenticated, u('/home')), isNull);
    });

    test('gates: password change, offline, blocked, update', () {
      expect(authRedirect(AuthStatus.passwordChangeRequired, u('/home')), startsWith(Routes.changePassword));
      expect(authRedirect(AuthStatus.offline, u('/')), Routes.offline);
      expect(authRedirect(AuthStatus.blocked, u('/home')), startsWith(Routes.blocked));
      expect(authRedirect(AuthStatus.updateRequired, u('/')), Routes.updateRequired);
    });

    test('from never redirects outside the app', () {
      expect(authRedirect(AuthStatus.authenticated, u('/login?from=%2F%2Fevil.com')), Routes.home);
      expect(authRedirect(AuthStatus.authenticated, u('/login?from=https%3A%2F%2Fevil.com')), Routes.home);
    });
  });
}
