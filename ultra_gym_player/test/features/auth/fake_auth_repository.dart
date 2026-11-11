import 'package:ultra_gym_player/core/error/failure.dart';
import 'package:ultra_gym_player/core/networking/api_result.dart';
import 'package:ultra_gym_player/core/utils/json_x.dart';
import 'package:ultra_gym_player/features/auth/data/repo/auth_repository.dart';
import 'package:ultra_gym_player/features/auth/domain/models/auth_models.dart';

const testSession = Session(
  user: AuthUser(id: 41, name: 'سامر الحلبي'),
  tenant: TenantRef(id: 12, name: 'نادي القمة الرياضي', slug: 'qimma'),
  roles: ['club_owner'],
  permissions: {'can_view_finance': true},
);

Failure failureOf(FailureType type) => Failure(type: type, message: 'رسالة ${type.name}');

/// مستودع وهمي: كل نتيجة يحددها الاختبار، ويسجّل ما استُدعي.
class FakeAuthRepository implements AuthRepository {
  bool token = false;
  ApiResult<Session> meResult = const ApiSuccess(testSession);
  final List<ApiResult<LoginOutcome>> loginResults = [];
  AppVersionInfo? version;
  final calls = <String>[];
  final loginTenants = <int?>[];

  @override
  bool get hasToken => token;

  @override
  Future<ApiResult<LoginOutcome>> login({required String phone, required String password, int? tenantId}) async {
    calls.add('login');
    loginTenants.add(tenantId);
    final r = loginResults.removeAt(0);
    if (r case ApiSuccess<LoginOutcome>(data: LoginSucceeded())) token = true;
    return r;
  }

  @override
  Future<ApiResult<Session>> me() async {
    calls.add('me');
    return meResult;
  }

  @override
  Future<ApiResult<void>> changePassword(Json body) async {
    calls.add('changePassword');
    return const ApiSuccess(null);
  }

  @override
  Future<void> logout() async {
    calls.add('logout');
    token = false;
  }

  @override
  Future<void> clearLocal() async {
    calls.add('clearLocal');
    token = false;
  }

  @override
  Future<void> registerDevice() async => calls.add('registerDevice');

  @override
  Future<AppVersionInfo?> checkVersion() async => version;
}
