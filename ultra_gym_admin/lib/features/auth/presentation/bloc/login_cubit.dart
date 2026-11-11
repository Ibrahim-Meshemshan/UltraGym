import '../../../../core/core.dart';
import '../../data/repo/auth_repository.dart';
import '../../domain/models/auth_models.dart';

/// خطوات شاشة الدخول: البيانات، ثم اختيار النادي إن ارتبط الحساب بأكثر من نادٍ.
class LoginState extends Equatable {
  const LoginState({this.tenants, this.session, this.pickingTenantId});

  /// غير فارغ = خطوة اختيار النادي.
  final List<TenantChoice>? tenants;

  /// الجلسة عند النجاح: الشاشة تمررها لـ AuthBloc.
  final Session? session;

  /// النادي الذي يُرسل طلبه الآن.
  final int? pickingTenantId;

  bool get choosingTenant => tenants != null;

  @override
  List<Object?> get props => [tenants, session, pickingTenantId];
}

/// منطق الدخول بالشاشة (factory). لا يعتمد على AuthBloc: الشاشة تبلّغه بالنجاح.
class LoginCubit extends Cubit<LoginState> {
  LoginCubit(this._repo) : super(const LoginState());

  final AuthRepository _repo;

  Future<void> submit(AppFormCubit form, {int? tenantId}) async {
    if (tenantId != null) emit(LoginState(tenants: state.tenants, pickingTenantId: tenantId));
    final r = await form.submit(
      (f) =>
          _repo.login(phone: '${f.value('phone') ?? ''}', password: '${f.value('password') ?? ''}', tenantId: tenantId),
    );
    if (isClosed) return;
    switch (r) {
      case ApiSuccess<LoginOutcome>(data: LoginNeedsTenant(:final tenants)):
        emit(LoginState(tenants: tenants));
      case ApiSuccess<LoginOutcome>(data: LoginSucceeded(:final session)):
        emit(LoginState(tenants: state.tenants, session: session));
      case _:
        emit(LoginState(tenants: state.tenants));
    }
  }

  void backToCredentials() => emit(const LoginState());
}
