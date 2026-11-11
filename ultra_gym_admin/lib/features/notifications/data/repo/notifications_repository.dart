import '../../../../core/core.dart';
import '../../domain/models/notification_models.dart';

/// إشعاراتي بالنادي الحالي (الأحدث أولاً) وعدّاد الجرس.
abstract interface class NotificationsRepository {
  Future<ApiResult<int>> unreadCount();

  Future<ApiResult<Paged<AppNotification>>> list(ListQuery query);

  Future<ApiResult<void>> markRead(int id);

  Future<ApiResult<void>> markAllRead();
}
