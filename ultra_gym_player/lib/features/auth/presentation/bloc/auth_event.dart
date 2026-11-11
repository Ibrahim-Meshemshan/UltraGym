part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// فتح التطبيق (أو "إعادة المحاولة"): فحص النسخة ثم استعادة الجلسة.
final class AuthStarted extends AuthEvent {
  const AuthStarted();
}

/// نجح الدخول (من شاشة الدخول).
final class AuthLoggedIn extends AuthEvent {
  const AuthLoggedIn(this.session);

  final Session session;

  @override
  List<Object?> get props => [session];
}

/// غُيّرت كلمة السر المؤقتة.
final class AuthPasswordChanged extends AuthEvent {
  const AuthPasswordChanged();
}

/// تحديث بيانات الجلسة بصمت (بعد تعديل الملف مثلاً).
final class AuthRefreshed extends AuthEvent {
  const AuthRefreshed();
}

final class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

/// حدث جلسة من الشبكة (401، حساب موقوف، تغيير كلمة سر إجباري، نادٍ محجوب).
final class AuthSessionEventReceived extends AuthEvent {
  const AuthSessionEventReceived(this.event);

  final SessionEvent event;

  @override
  List<Object?> get props => [event];
}
