import '../../../../core/core.dart';
import '../../domain/models/check_in_models.dart';
import '../../domain/models/station_models.dart';

/// محطة الدخول: فروع الموظف، حضور اليوم، البحث السريع، وتسجيل الدخول (QR أو المعرّف أو الاختيار).
abstract interface class StationRepository {
  /// `GET club-admin/branches` (الخادم يحصرها بفروع الموظف).
  Future<ApiResult<List<StationBranch>>> branches();

  /// `GET club-admin/attendance/today?branch_id=`: الأرقام وآخر الدخول.
  Future<ApiResult<TodaySummary>> today(int branchId);

  /// `GET club-admin/players/lookup?q=&branch_id=`: الاسم أو الموبايل أو المعرّف، مع حكم الدخول.
  Future<ApiResult<List<LookupPlayer>>> lookup(String q, int branchId);

  /// `POST club-admin/attendance/check-in` بـ `qr_token` أو `member_code` أو `player_id`. الرفض (409) نتيجة.
  Future<ApiResult<CheckInResult>> checkIn(Json body, {required String idempotencyKey});
}
