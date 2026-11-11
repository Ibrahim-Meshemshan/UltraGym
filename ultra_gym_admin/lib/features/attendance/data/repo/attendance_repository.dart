import '../../../../core/core.dart';
import '../../domain/models/attendance_models.dart';

/// سجل الحضور وأرقام اليوم وتسجيل الدخول اليدوي.
abstract interface class AttendanceRepository {
  /// `GET club-admin/attendance` (الأحدث أولاً). بلا فترة ← آخر 31 يوماً (`meta.period`).
  Future<ApiResult<Paged<AttendanceRow>>> list(ListQuery query, {int? branchId});

  /// `GET club-admin/attendance/today?branch_id=`.
  Future<ApiResult<AttendanceToday>> today({int? branchId});

  /// `POST club-admin/attendance/check-in` بـ `player_id` أو `member_code`. الرفض (409) يرجع نتيجةً بالسجل المحفوظ.
  Future<ApiResult<CheckInResult>> checkIn(Json body, {required String idempotencyKey});
}
