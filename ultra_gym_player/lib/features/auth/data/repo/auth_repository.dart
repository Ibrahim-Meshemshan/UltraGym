import '../../../../core/core.dart';
import '../../domain/models/auth_models.dart';

/// عقد الدخول والجلسة. المسارات حسب الواجهة (`AppConfig.authBase`).
abstract interface class AuthRepository {
  /// يحفظ التوكن عند النجاح. حساب بأكثر من نادٍ دون `tenantId` يرجع `LoginNeedsTenant`.
  Future<ApiResult<LoginOutcome>> login({required String phone, required String password, int? tenantId});

  /// استعادة الجلسة عند فتح التطبيق.
  Future<ApiResult<Session>> me();

  /// `{ current_password, new_password, new_password_confirmation }`. نفس التوكن يبقى صالحاً.
  Future<ApiResult<void>> changePassword(Json body);

  /// خروج هذا الجهاز من الخادم ثم مسح التوكن والكاش محلياً (حتى لو فشل الطلب).
  Future<void> logout();

  /// مسح الجلسة محلياً فقط (انتهاء الجلسة، حساب موقوف).
  Future<void> clearLocal();

  bool get hasToken;

  /// `POST /devices` بعد الدخول وعند كل فتح (للتطبيقات التي لها `AppConfig.platformApp`).
  Future<void> registerDevice();

  /// `GET /app-version` (بلا توكن). null إن لم يكن للتطبيق نسخة متجر أو فشل الطلب.
  Future<AppVersionInfo?> checkVersion();
}
