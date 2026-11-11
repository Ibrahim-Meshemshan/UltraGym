import '../../../../core/core.dart';
import '../../domain/models/notification_models.dart';
import '../repo/notifications_repository.dart';

class NotificationsRemoteDataSource implements NotificationsRepository {
  NotificationsRemoteDataSource(this._api);

  final ApiClient _api;
  static const _base = '/notifications';

  @override
  Future<ApiResult<int>> unreadCount() => _api.get('$_base/unread-count', parse: Parse.intField('unread_count'));

  @override
  Future<ApiResult<Paged<AppNotification>>> list(ListQuery query) =>
      _api.getPaged(_base, fromJson: AppNotification.fromJson, query: query);

  @override
  Future<ApiResult<void>> markRead(int id) => _api.post('$_base/$id/read', parse: Parse.none);

  @override
  Future<ApiResult<void>> markAllRead() => _api.post('$_base/read-all', parse: Parse.none);
}
