import '../../../../core/core.dart';
import '../../domain/models/staff_models.dart';
import '../repo/staff_repository.dart';

class StaffRemoteDataSource implements StaffRepository {
  StaffRemoteDataSource(this._api);

  final ApiClient _api;

  static const _rec = '/club-admin/receptionists',
      _staff = '/club-admin/staff-members',
      _accounts = '/club-admin/accounts';

  @override
  Future<ApiResult<StaffUsage>> usage() => _api.getObject('/club-admin/club', fromJson: StaffUsage.fromJson);

  @override
  Future<ApiResult<Paged<Receptionist>>> receptionists(ListQuery query) =>
      _api.getPaged(_rec, fromJson: Receptionist.fromJson, query: query);

  @override
  Future<ApiResult<ReceptionistCreated>> addReceptionist(Json body, {String? idempotencyKey}) =>
      _api.post(_rec, body: body, idempotencyKey: idempotencyKey, parse: Parse.object(ReceptionistCreated.fromJson));

  @override
  Future<ApiResult<Receptionist>> updateReceptionist(int id, Json body) =>
      _api.patch('$_rec/$id', body: body, parse: Parse.object(Receptionist.fromJson));

  @override
  Future<ApiResult<void>> setReceptionistBranches(int id, List<int> branchIds) =>
      _api.put('$_rec/$id/branches', body: {'branch_ids': branchIds}, parse: Parse.none);

  @override
  Future<ApiResult<void>> suspendReceptionist(int id, String reason) =>
      _api.post('$_rec/$id/suspend', body: {'reason': reason}, parse: Parse.none);

  @override
  Future<ApiResult<void>> activateReceptionist(int id) => _api.post('$_rec/$id/activate', parse: Parse.none);

  @override
  Future<ApiResult<void>> archiveReceptionist(int id) => _api.delete('$_rec/$id', parse: Parse.none);

  @override
  Future<ApiResult<void>> restoreReceptionist(int id) => _api.post('$_rec/$id/restore', parse: Parse.none);

  /// الأرشيف (`archived=only`) يرجع الموظف بلا علامة، فنعلّمه هنا.
  @override
  Future<ApiResult<Paged<StaffMember>>> staffMembers(ListQuery query) async {
    final r = await _api.getPaged(_staff, fromJson: StaffMember.fromJson, query: query);
    if (query.filter('archived') != 'only') return r;
    return switch (r) {
      ApiSuccess(:final data, :final message, :final meta) => ApiSuccess(
        data.copyWithItems([for (final s in data.items) s.asArchived()]),
        message: message,
        meta: meta,
      ),
      ApiFailure(:final failure) => ApiFailure(failure),
    };
  }

  @override
  Future<ApiResult<StaffMember>> saveStaffMember(Json body, {int? id, String? idempotencyKey}) => id == null
      ? _api.post(_staff, body: body, idempotencyKey: idempotencyKey, parse: Parse.object(StaffMember.fromJson))
      : _api.patch('$_staff/$id', body: body, parse: Parse.object(StaffMember.fromJson));

  @override
  Future<ApiResult<void>> archiveStaffMember(int id) => _api.delete('$_staff/$id', parse: Parse.none);

  @override
  Future<ApiResult<void>> restoreStaffMember(int id) => _api.post('$_staff/$id/restore', parse: Parse.none);

  @override
  Future<ApiResult<Paged<ClubAccount>>> accounts(ListQuery query) =>
      _api.getPaged(_accounts, fromJson: ClubAccount.fromJson, query: query);

  @override
  Future<ApiResult<ResetResult>> resetPasswords(Json body) async {
    final r = await _api.post('$_accounts/reset-passwords', body: body, parse: Parse.object(ResetResult.fromJson));
    return switch (r) {
      ApiSuccess(:final data, :final message) => ApiSuccess(data.withMessage(message), message: message),
      ApiFailure(:final failure) => ApiFailure(failure),
    };
  }

  @override
  Future<ApiResult<FileBlob>> cardsPdf(List<IssuedCredential> credentials) =>
      _api.postBytes('$_accounts/cards/pdf', body: {'cards': [for (final c in credentials) c.card()]});

  @override
  Future<ApiResult<void>> regenerateCode(int userId) =>
      _api.post('$_accounts/$userId/regenerate-code', parse: Parse.none);

  @override
  Future<ApiResult<void>> endSessions(int userId) => _api.delete('$_accounts/$userId/sessions', parse: Parse.none);
}
