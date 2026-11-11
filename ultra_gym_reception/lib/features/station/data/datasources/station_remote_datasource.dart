import '../../../../core/core.dart';
import '../../domain/models/check_in_models.dart';
import '../../domain/models/station_models.dart';
import '../repo/station_repository.dart';

class StationRemoteDataSource implements StationRepository {
  StationRemoteDataSource(this._api);

  final ApiClient _api;

  static const _base = '/club-admin';

  @override
  Future<ApiResult<List<StationBranch>>> branches() =>
      _api.getList('$_base/branches', fromJson: StationBranch.fromJson, query: {'per_page': 100});

  @override
  Future<ApiResult<TodaySummary>> today(int branchId) =>
      _api.getObject('$_base/attendance/today', fromJson: TodaySummary.fromJson, query: {'branch_id': branchId});

  @override
  Future<ApiResult<List<LookupPlayer>>> lookup(String q, int branchId) =>
      _api.getList('$_base/players/lookup', fromJson: LookupPlayer.fromJson, query: {'q': q, 'branch_id': branchId});

  @override
  Future<ApiResult<CheckInResult>> checkIn(Json body, {required String idempotencyKey}) async => checkInResultOf(
    await _api.post('$_base/attendance/check-in', body: body, idempotencyKey: idempotencyKey, parse: Parse.json),
  );

  /// 201 مقبول، 200 مكرر، 409 بسجل محفوظ = مرفوض (نتيجة). غير ذلك فشل: 422 `QR_*`، 404، شبكة.
  static ApiResult<CheckInResult> checkInResultOf(ApiResult<Json> r) => switch (r) {
    ApiSuccess(:final data, :final message) => ApiSuccess(
      CheckInResult.fromJson(data, message: message ?? 'تم تسجيل الدخول'),
      message: message,
    ),
    ApiFailure(:final failure) when failure.statusCode == 409 && asJson(failure.data)['record'] is Map => ApiSuccess(
      CheckInResult.fromJson(asJson(failure.data), message: failure.message, code: failure.code),
    ),
    ApiFailure(:final failure) => ApiFailure(failure),
  };
}
