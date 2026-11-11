import '../../../../core/core.dart';
import '../../domain/models/membership_detail_models.dart';
import '../repo/membership_detail_repository.dart';

class MembershipDetailRemoteDataSource implements MembershipDetailRepository {
  MembershipDetailRemoteDataSource(this._api);

  final ApiClient _api;

  static const _path = '/club-admin/memberships';

  @override
  Future<ApiResult<MembershipDetail>> detail(int id) =>
      _api.getObject('$_path/$id', fromJson: MembershipDetail.fromJson);

  @override
  Future<ApiResult<Paged<AttendanceEntry>>> attendance(
    ListQuery query, {
    required int playerId,
    DateTime? from,
    DateTime? to,
  }) => _api.getPaged(
    '/club-admin/attendance',
    fromJson: AttendanceEntry.fromJson,
    query: query,
    extra: {
      'player_id': playerId,
      if (from != null) 'from': Formatters.date(from),
      if (to != null) 'to': Formatters.date(to),
    },
  );

  @override
  Future<ApiResult<void>> pay(int id, Json body, {required String idempotencyKey}) =>
      _api.post('$_path/$id/payments', body: body, idempotencyKey: idempotencyKey, parse: Parse.none);

  @override
  Future<ApiResult<void>> freeze(int id, Json body) => _api.post('$_path/$id/freeze', body: body, parse: Parse.none);

  @override
  Future<ApiResult<void>> unfreeze(int id) => _api.post('$_path/$id/unfreeze', parse: Parse.none);

  @override
  Future<ApiResult<void>> cancel(int id, Json body, {required String idempotencyKey}) =>
      _api.post('$_path/$id/cancel', body: body, idempotencyKey: idempotencyKey, parse: Parse.none);

  @override
  Future<ApiResult<MembershipQuote>> renewQuote({required int planId, required int previousId}) => _api.post(
    '$_path/quote',
    body: {'plan_id': planId, 'previous_membership_id': previousId},
    parse: Parse.object(MembershipQuote.fromJson),
  );

  @override
  Future<ApiResult<int>> renew(int id, Json body, {required String idempotencyKey}) => _api.post(
    '$_path/$id/renew',
    body: body,
    idempotencyKey: idempotencyKey,
    parse: Parse.field('membership', (j) => j.intv('id')),
  );

  @override
  Future<ApiResult<void>> consumeSession(int id, Json body, {required String idempotencyKey}) =>
      _api.post('$_path/$id/sessions', body: body, idempotencyKey: idempotencyKey, parse: Parse.none);

  @override
  Future<ApiResult<FileBlob>> invoice(int id) => _api.getBytes('$_path/$id/invoice');

  @override
  Future<ApiResult<FileBlob>> receipt(int transactionId) =>
      _api.getBytes('/club-admin/transactions/$transactionId/receipt');
}
