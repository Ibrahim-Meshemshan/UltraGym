import '../../../../core/core.dart';
import '../../domain/models/attendance_models.dart';
import '../repo/attendance_repository.dart';

class AttendanceRemoteDataSource implements AttendanceRepository {
  AttendanceRemoteDataSource(this._api);

  final ApiClient _api;

  static const _path = '/club-admin/attendance';

  @override
  Future<ApiResult<Paged<AttendanceRow>>> list(ListQuery query, {int? branchId}) => _api.getPaged(
    _path,
    fromJson: AttendanceRow.fromJson,
    query: query,
    extra: {AttendanceFilters.branchId: ?branchId},
  );

  @override
  Future<ApiResult<AttendanceToday>> today({int? branchId}) =>
      _api.getObject('$_path/today', fromJson: AttendanceToday.fromJson, query: {'branch_id': ?branchId});

  @override
  Future<ApiResult<CheckInResult>> checkIn(Json body, {required String idempotencyKey}) async {
    final r = await _api.post('$_path/check-in', body: body, idempotencyKey: idempotencyKey, parse: Parse.json);
    return checkInResultOf(r);
  }

  /// رد الخادم ← نتيجة: 201 مقبول، 200 مكرر، 409 بسجل محفوظ = مرفوض. غير ذلك فشل بالنموذج (404، 422، شبكة).
  static ApiResult<CheckInResult> checkInResultOf(ApiResult<Json> r) {
    return switch (r) {
      ApiSuccess(:final data, :final message) => ApiSuccess(
        CheckInResult.fromJson(data, message: message ?? 'تم تسجيل الدخول'),
        message: message,
      ),
      // الرفض محفوظ بالخادم ويرجع السجل والعضو: نتيجة تُعرض ببطاقة حمراء لا خطأ بالنموذج.
      ApiFailure(:final failure) when _isRejection(failure) => ApiSuccess(
        CheckInResult.fromJson(asJson(failure.data), message: failure.message, code: failure.code),
      ),
      ApiFailure(:final failure) => ApiFailure(failure),
    };
  }

  static bool _isRejection(Failure f) => f.statusCode == 409 && asJson(f.data)['record'] is Map;
}
