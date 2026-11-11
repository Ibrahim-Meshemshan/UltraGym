import 'package:dio/dio.dart';

import '../../../../core/core.dart';
import '../../../branches/domain/models/branch_models.dart';
import '../../domain/models/settings_models.dart';
import '../repo/settings_repository.dart';

class SettingsRemoteDataSource implements SettingsRepository {
  SettingsRemoteDataSource(this._api);

  final ApiClient _api;

  static const _club = '/club-admin/club', _branches = '/club-admin/branches';

  @override
  Future<ApiResult<ClubProfile>> club() => _api.getObject(_club, fromJson: ClubProfile.fromJson);

  @override
  Future<ApiResult<ClubProfile>> updateClub(Json body) =>
      _api.patch(_club, body: body, parse: Parse.object(ClubProfile.fromJson));

  @override
  Future<ApiResult<ClubSettings>> updateSettings(Json body) =>
      _api.patch('$_club/settings', body: body, parse: Parse.object(ClubSettings.fromJson));

  @override
  Future<ApiResult<NotificationCatalog>> notificationTypes() =>
      _api.getObject('$_club/notification-types', fromJson: NotificationCatalog.fromJson);

  @override
  Future<ApiResult<void>> uploadLogo(FormData form) => _api.upload('$_club/logo', form: form, parse: Parse.none);

  @override
  Future<ApiResult<void>> deleteLogo() => _api.delete('$_club/logo', parse: Parse.none);

  @override
  Future<ApiResult<List<Branch>>> branches() =>
      _api.getList(_branches, fromJson: Branch.fromJson, query: const {'per_page': 100});

  @override
  Future<ApiResult<Branch>> saveBranch(Json body, {int? id, String? idempotencyKey}) => id == null
      ? _api.post(_branches, body: body, idempotencyKey: idempotencyKey, parse: Parse.object(Branch.fromJson))
      : _api.patch('$_branches/$id', body: body, parse: Parse.object(Branch.fromJson));

  @override
  Future<ApiResult<Branch>> setBranchStatus(int id, String status) =>
      _api.post('$_branches/$id/status', body: {'status': status}, parse: Parse.object(Branch.fromJson));

  @override
  Future<ApiResult<void>> archiveBranch(int id) => _api.delete('$_branches/$id', parse: Parse.none);
}
