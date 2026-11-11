import 'package:dio/dio.dart';

import '../../../../core/core.dart';
import '../../../branches/domain/models/branch_models.dart';
import '../../domain/models/settings_models.dart';

/// الإعدادات والفروع (للمالك فقط): ملف النادي وإعداداته (`/club-admin/club`) وإدارة الفروع (`/club-admin/branches`).
abstract interface class SettingsRepository {
  Future<ApiResult<ClubProfile>> club();

  /// التواصل فقط (`contact_phone`، `contact_email`، `city`، `address`)؛ الاسم والبادئة من المنصة.
  Future<ApiResult<ClubProfile>> updateClub(Json body);

  /// إعدادات التشغيل والإشعارات (`PATCH club/settings`، الحقول المرسلة فقط).
  Future<ApiResult<ClubSettings>> updateSettings(Json body);

  Future<ApiResult<NotificationCatalog>> notificationTypes();

  /// `logo` png/jpg/webp حتى 2MB.
  Future<ApiResult<void>> uploadLogo(FormData form);
  Future<ApiResult<void>> deleteLogo();

  /// كل الفروع غير المؤرشفة (الفعّالة والموقوفة)، الرئيسي أولاً.
  Future<ApiResult<List<Branch>>> branches();

  /// إضافة (`POST`، تخضع لحد الباقة `PLAN_LIMIT_REACHED`) أو تعديل (`PATCH`).
  Future<ApiResult<Branch>> saveBranch(Json body, {int? id, String? idempotencyKey});

  /// `active` / `inactive` (الرئيسي لا يُوقف، ومع وردية مفتوحة يُرفض بـ 409).
  Future<ApiResult<Branch>> setBranchStatus(int id, String status);

  /// أرشفة الموقوف غير الرئيسي (حذف ناعم يبقي سجله المالي).
  Future<ApiResult<void>> archiveBranch(int id);
}
