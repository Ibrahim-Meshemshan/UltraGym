import '../../../../core/core.dart';
import '../../domain/models/announcements_models.dart';
import '../repo/announcements_repository.dart';

class AnnouncementsRemoteDataSource implements AnnouncementsRepository {
  AnnouncementsRemoteDataSource(this._api);

  final ApiClient _api;

  static const _path = '/club-admin/announcements';

  @override
  Future<ApiResult<Paged<Announcement>>> announcements(ListQuery query) =>
      _api.getPaged(_path, fromJson: Announcement.fromJson, query: query);

  @override
  Future<ApiResult<Announcement>> save(Json body, {int? id, String? idempotencyKey}) => id == null
      ? _api.post(_path, body: body, idempotencyKey: idempotencyKey, parse: Parse.object(Announcement.fromJson))
      : _api.patch('$_path/$id', body: body, parse: Parse.object(Announcement.fromJson));

  @override
  Future<ApiResult<void>> delete(int id) => _api.delete('$_path/$id', parse: Parse.none);
}
