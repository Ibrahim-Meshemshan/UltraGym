import 'package:dio/dio.dart';

import '../../../../core/core.dart';
import '../../domain/models/member_models.dart';
import '../../domain/models/member_profile_models.dart';

/// ملف عضو واحد وعملياته وسجلاته. المالك والاستقبال (بفروعه) معاً؛ الأرشفة من قائمة الأعضاء.
abstract interface class MemberProfileRepository {
  /// `GET club-admin/players/{id}` (يشمل المؤرشف).
  Future<ApiResult<MemberProfile>> profile(int id);

  /// `PATCH club-admin/players/{id}`: الحساب (الاسم، الموبايل، البريد) والملف معاً.
  Future<ApiResult<void>> update(int id, Json body);

  /// `POST players/{id}/suspend` بسبب إلزامي، و `activate` للتفعيل.
  Future<ApiResult<void>> suspend(int id, String reason);
  Future<ApiResult<void>> activate(int id);

  /// `POST players/{id}/reset-password`: كلمة سر مؤقتة تظهر مرة واحدة.
  Future<ApiResult<NewMember>> resetPassword(int id);

  /// `POST players/{id}/photo` (حقل `photo`، 3MB).
  Future<ApiResult<void>> uploadPhoto(int id, FormData form);

  /// السجلات مقسّمة لصفحات (الأحدث أولاً).
  Future<ApiResult<Paged<MembershipItem>>> memberships(int id, ListQuery query);
  Future<ApiResult<Paged<AttendanceEntry>>> attendance(int id, ListQuery query);
  Future<ApiResult<Paged<PaymentEntry>>> payments(int id, ListQuery query);
}
