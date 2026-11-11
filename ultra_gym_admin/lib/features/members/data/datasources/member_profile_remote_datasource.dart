import 'package:dio/dio.dart';

import '../../../../core/core.dart';
import '../../domain/models/member_models.dart';
import '../../domain/models/member_profile_models.dart';
import '../repo/member_profile_repository.dart';

class MemberProfileRemoteDataSource implements MemberProfileRepository {
  MemberProfileRemoteDataSource(this._api);

  final ApiClient _api;

  static const _players = '/club-admin/players';

  @override
  Future<ApiResult<MemberProfile>> profile(int id) => _api.getObject('$_players/$id', fromJson: MemberProfile.fromJson);

  @override
  Future<ApiResult<void>> update(int id, Json body) => _api.patch('$_players/$id', body: body, parse: Parse.none);

  @override
  Future<ApiResult<void>> suspend(int id, String reason) =>
      _api.post('$_players/$id/suspend', body: {'reason': reason}, parse: Parse.none);

  @override
  Future<ApiResult<void>> activate(int id) => _api.post('$_players/$id/activate', parse: Parse.none);

  @override
  Future<ApiResult<NewMember>> resetPassword(int id) =>
      _api.post('$_players/$id/reset-password', parse: Parse.object(NewMember.fromJson));

  @override
  Future<ApiResult<void>> uploadPhoto(int id, FormData form) =>
      _api.upload('$_players/$id/photo', form: form, parse: Parse.none);

  @override
  Future<ApiResult<Paged<MembershipItem>>> memberships(int id, ListQuery query) => _api.getPaged(
    '/club-admin/memberships',
    fromJson: MembershipItem.fromJson,
    query: query,
    extra: {'player_id': id, 'sort_by': 'starts_on', 'sort_dir': 'desc'},
  );

  @override
  Future<ApiResult<Paged<AttendanceEntry>>> attendance(int id, ListQuery query) => _api.getPaged(
    '/club-admin/attendance',
    fromJson: AttendanceEntry.fromJson,
    query: query,
    extra: {'player_id': id},
  );

  @override
  Future<ApiResult<Paged<PaymentEntry>>> payments(int id, ListQuery query) => _api.getPaged(
    '/club-admin/transactions',
    fromJson: PaymentEntry.fromJson,
    query: query,
    extra: {'player_id': id},
  );
}
