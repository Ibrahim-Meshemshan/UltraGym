import '../../../../core/core.dart';
import '../../data/repo/notifications_repository.dart';
import '../../domain/models/notification_models.dart';

/// قائمة الجرس: تُنشأ عند فتح القائمة (فتُحدَّث كل مرة)، صفحة 10 مع "عرض المزيد"،
/// وتعليم المقروء يعدّل العنصر محلياً بعد نجاح الطلب.
class NotificationsListCubit extends ListCubit<AppNotification> {
  NotificationsListCubit(NotificationsRepository repo)
    : _repo = repo,
      super(repo.list, query: const ListQuery(perPage: pageSize));

  static const pageSize = 10;

  final NotificationsRepository _repo;

  /// true إن نجح (أو كان مقروءاً أصلاً).
  Future<bool> markRead(AppNotification n) async {
    if (n.isRead) return true;
    final ok = (await _repo.markRead(n.id)) is ApiSuccess;
    if (ok && !isClosed) patchItems((items) => [for (final i in items) i.id == n.id ? i.asRead() : i]);
    return ok;
  }

  Future<ApiResult<void>> markAllRead() async {
    final r = await _repo.markAllRead();
    if (r is ApiSuccess && !isClosed) patchItems((items) => [for (final i in items) i.asRead()]);
    return r;
  }
}
