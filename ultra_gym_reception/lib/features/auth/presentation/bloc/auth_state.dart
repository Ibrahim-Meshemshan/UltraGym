part of 'auth_bloc.dart';

/// حالة الجلسة التي يوجّه بها الراوتر.
enum AuthStatus {
  /// استعادة الجلسة جارية (شاشة البدء).
  unknown,

  /// نسخة التطبيق لم تعد مدعومة (تطبيق العضو).
  updateRequired,
  unauthenticated,

  /// كلمة سر مؤقتة: تغييرها قبل أي شيء.
  passwordChangeRequired,

  /// تعذّر الوصول للخادم أثناء استعادة الجلسة.
  offline,

  /// النادي أو اشتراكه موقوف: شاشة حجب بالرسالة.
  blocked,
  authenticated,
}

class AuthState extends Equatable {
  const AuthState({this.status = AuthStatus.unknown, this.session, this.message, this.version});

  final AuthStatus status;
  final Session? session;

  /// سبب الحالة للعرض (انتهاء الجلسة، الحجب، تعذّر الاتصال).
  final String? message;
  final AppVersionInfo? version;

  bool get isAuthenticated => status == AuthStatus.authenticated && session != null;

  AuthState copyWith({AuthStatus? status, Session? Function()? session, String? Function()? message, AppVersionInfo? version}) =>
      AuthState(
        status: status ?? this.status,
        session: session == null ? this.session : session(),
        message: message == null ? this.message : message(),
        version: version ?? this.version,
      );

  @override
  List<Object?> get props => [status, session, message, version];
}
