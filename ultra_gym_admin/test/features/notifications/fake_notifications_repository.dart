import 'package:ultra_gym_admin/core/networking/api_result.dart';
import 'package:ultra_gym_admin/core/networking/list_query.dart';
import 'package:ultra_gym_admin/core/networking/paged.dart';
import 'package:ultra_gym_admin/features/notifications/data/repo/notifications_repository.dart';
import 'package:ultra_gym_admin/features/notifications/domain/models/notification_models.dart';

final cashLeftOpen = AppNotification(
  id: 1,
  type: 'club_cash_left_open',
  screen: 'cash_session',
  title: 'صندوق لم يُغلق',
  body: 'وردية #47 من أمس ما زالت مفتوحة بفرع المالكي.',
  data: const {'cash_session_id': '47'},
  createdAt: DateTime.now().toUtc().subtract(const Duration(minutes: 5)),
);

final dailySummary = AppNotification(
  id: 2,
  type: 'club_daily_summary',
  screen: 'memberships',
  title: 'ملخص الصباح',
  body: '38 اشتراكاً تنتهي خلال 3 أيام.',
  isRead: true,
  createdAt: DateTime.now().toUtc().subtract(const Duration(hours: 3)),
);

/// مستودع إشعارات وهمي: عدد ثابت وقائمة صفحة واحدة، ويسجّل ما عُلّم مقروءاً.
class FakeNotificationsRepository implements NotificationsRepository {
  FakeNotificationsRepository({this.count = 1, List<AppNotification>? items})
    : items = items ?? [cashLeftOpen, dailySummary];

  int count;
  final List<AppNotification> items;
  ApiResult<int>? countResult;
  final read = <int>[];
  var readAll = 0;

  @override
  Future<ApiResult<int>> unreadCount() async => countResult ?? ApiSuccess(count);

  @override
  Future<ApiResult<Paged<AppNotification>>> list(ListQuery query) async => ApiSuccess(Paged(items: items));

  @override
  Future<ApiResult<void>> markRead(int id) async {
    read.add(id);
    count--;
    return const ApiSuccess(null);
  }

  @override
  Future<ApiResult<void>> markAllRead() async {
    readAll++;
    count = 0;
    return const ApiSuccess(null);
  }
}
