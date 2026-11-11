import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/screens/blocked_screen.dart';
import '../../features/auth/presentation/screens/change_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/offline_screen.dart';
import '../../features/auth/presentation/screens/update_required_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../theme/app_tokens.dart';
import 'routes.dart';

/// الراوتر الوحيد: يتبع `AuthBloc` ويعيد التوجيه حسب `AuthStatus`، والصفحة المطلوبة تُحفظ بـ `?from=`.
GoRouter buildRouter(AuthBloc auth) => GoRouter(
      initialLocation: Routes.splash,
      refreshListenable: StreamListenable(auth.stream),
      redirect: (context, state) => authRedirect(auth.state.status, state.uri),
      routes: [
        GoRoute(path: Routes.splash, pageBuilder: (c, s) => fadePage(s, const SplashScreen())),
        GoRoute(path: Routes.login, pageBuilder: (c, s) => fadePage(s, const LoginScreen())),
        GoRoute(path: Routes.changePassword, pageBuilder: (c, s) => fadePage(s, const ChangePasswordScreen())),
        GoRoute(path: Routes.offline, pageBuilder: (c, s) => fadePage(s, const OfflineScreen())),
        GoRoute(path: Routes.blocked, pageBuilder: (c, s) => fadePage(s, const BlockedScreen())),
        GoRoute(path: Routes.updateRequired, pageBuilder: (c, s) => fadePage(s, const UpdateRequiredScreen())),
        GoRoute(path: Routes.home, pageBuilder: (c, s) => fadePage(s, const HomeScreen())),
      ],
    );

/// مسارات ما قبل الدخول: لا تُحفظ كـ `from`.
const _gates = {Routes.splash, Routes.login, Routes.changePassword, Routes.offline, Routes.blocked, Routes.updateRequired};

/// قرار التوجيه (منفصل للاختبار): null = ابقَ حيث أنت.
String? authRedirect(AuthStatus status, Uri uri) {
  final here = uri.path;
  final requested = uri.queryParameters['from'];
  final from = _gates.contains(here) ? _safe(requested) : _safe(uri.toString());

  String? go(String target) {
    if (here == target) return null;
    return Uri(path: target, queryParameters: from == null ? null : {'from': from}).toString();
  }

  return switch (status) {
    AuthStatus.unknown => go(Routes.splash),
    AuthStatus.updateRequired => go(Routes.updateRequired),
    AuthStatus.unauthenticated => go(Routes.login),
    AuthStatus.passwordChangeRequired => go(Routes.changePassword),
    AuthStatus.offline => go(Routes.offline),
    AuthStatus.blocked => go(Routes.blocked),
    AuthStatus.authenticated => _gates.contains(here) ? (from ?? Routes.home) : null,
  };
}

/// يقبل مساراً داخلياً فقط (لا رابط خارجي عبر `from`).
String? _safe(String? path) =>
    path != null && path.startsWith('/') && !path.startsWith('//') && !_gates.contains(Uri.parse(path).path) ? path : null;

/// يحوّل stream حالة الـ Bloc لـ Listenable يحدّث الراوتر.
class StreamListenable extends ChangeNotifier {
  StreamListenable(Stream<Object?> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<Object?> _sub;

  @override
  void dispose() {
    unawaited(_sub.cancel());
    super.dispose();
  }
}

/// انتقال الشاشات العامة: تلاشٍ بمدة `AppMotion.slow`، ويُلغى مع "تقليل الحركة".
CustomTransitionPage<void> fadePage(GoRouterState state, Widget child) => CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: AppMotion.slow,
      reverseTransitionDuration: AppMotion.slow,
      transitionsBuilder: (context, animation, _, child) => AppMotion.reduced(context)
          ? child
          : FadeTransition(opacity: CurvedAnimation(parent: animation, curve: AppMotion.curve), child: child),
    );
