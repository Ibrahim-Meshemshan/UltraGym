import 'dart:async';

import '../../../../core/core.dart';
import '../../data/repo/auth_repository.dart';
import '../../domain/models/auth_models.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// حالة الجلسة للتطبيق كله (lazySingleton). الراوتر يعيد التوجيه حسب `AuthStatus`،
/// وأحداث الجلسة من الشبكة (`SessionEvents`) تصل هنا مباشرة.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repo, SessionEvents events) : super(const AuthState()) {
    on<AuthStarted>(_onStarted);
    on<AuthLoggedIn>(_onLoggedIn);
    on<AuthPasswordChanged>(_onPasswordChanged);
    on<AuthRefreshed>(_onRefreshed);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthSessionEventReceived>(_onSessionEvent);
    _events = events.stream.listen((e) => add(AuthSessionEventReceived(e)));
  }

  final AuthRepository _repo;
  late final StreamSubscription<SessionEvent> _events;

  static const _expired = 'انتهت الجلسة. سجّل الدخول من جديد.';

  Future<void> _onStarted(AuthStarted e, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.unknown, message: () => null));
    final version = await _repo.checkVersion();
    if (version != null && version.forceUpdate) {
      return emit(state.copyWith(status: AuthStatus.updateRequired, version: version));
    }
    if (!_repo.hasToken) return emit(state.copyWith(status: AuthStatus.unauthenticated, session: () => null));
    final r = await _repo.me();
    switch (r) {
      case ApiSuccess<Session>(:final data):
        _enter(data, emit);
      case ApiFailure<Session>(:final failure):
        await _fail(failure, emit);
    }
    if (version != null && version.updateAvailable && state.isAuthenticated) {
      AppSnackbar.show('يتوفر تحديث جديد للتطبيق.');
    }
  }

  void _onLoggedIn(AuthLoggedIn e, Emitter<AuthState> emit) => _enter(e.session, emit);

  void _onPasswordChanged(AuthPasswordChanged e, Emitter<AuthState> emit) {
    final s = state.session;
    if (s != null) _enter(s.copyWith(mustChangePassword: false), emit);
  }

  Future<void> _onRefreshed(AuthRefreshed e, Emitter<AuthState> emit) async {
    final r = await _repo.me();
    if (r case ApiSuccess<Session>(:final data)) emit(state.copyWith(session: () => data));
  }

  Future<void> _onLogout(AuthLogoutRequested e, Emitter<AuthState> emit) async {
    await _repo.logout();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  Future<void> _onSessionEvent(AuthSessionEventReceived e, Emitter<AuthState> emit) async {
    if (state.status == AuthStatus.unauthenticated) return;
    switch (e.event) {
      case SessionEvent.expired:
        await _repo.clearLocal();
        emit(const AuthState(status: AuthStatus.unauthenticated, message: _expired));
      case SessionEvent.accountSuspended:
        await _repo.clearLocal();
        emit(AuthState(
          status: AuthStatus.unauthenticated,
          message: ErrorHandler.defaultMessage(FailureType.accountSuspended),
        ));
      case SessionEvent.passwordChangeRequired:
        emit(state.copyWith(status: AuthStatus.passwordChangeRequired));
      case SessionEvent.tenantBlocked:
        emit(state.copyWith(
          status: AuthStatus.blocked,
          message: () => ErrorHandler.defaultMessage(FailureType.tenantSuspended),
        ));
    }
  }

  void _enter(Session s, Emitter<AuthState> emit) {
    emit(AuthState(
      status: s.mustChangePassword ? AuthStatus.passwordChangeRequired : AuthStatus.authenticated,
      session: s,
      version: state.version,
    ));
    if (!s.mustChangePassword) unawaited(_repo.registerDevice());
  }

  Future<void> _fail(Failure f, Emitter<AuthState> emit) async {
    switch (f.type) {
      case FailureType.passwordChangeRequired:
        emit(state.copyWith(status: AuthStatus.passwordChangeRequired));
      case FailureType.tenantSuspended || FailureType.subscriptionInactive:
        emit(state.copyWith(status: AuthStatus.blocked, message: () => f.message));
      case _ when f.isNetwork || f.type == FailureType.server || f.type == FailureType.maintenance:
        emit(state.copyWith(status: AuthStatus.offline, message: () => f.message));
      default:
        await _repo.clearLocal();
        emit(AuthState(status: AuthStatus.unauthenticated, message: f.type == FailureType.unauthenticated ? _expired : f.message));
    }
  }

  @override
  Future<void> close() async {
    await _events.cancel();
    return super.close();
  }
}
