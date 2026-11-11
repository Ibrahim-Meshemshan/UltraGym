import '../../../../core/core.dart';

/// إشعار بجرس اللوحة (`GET /notifications`). `title` و `body` نصوص عربية جاهزة تُعرض كما هي،
/// و `screen` الشاشة التي يفتحها مع معرّفاتها بـ `data` (`none` = لا شيء يُفتح).
class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.type,
    required this.screen,
    required this.title,
    this.body = '',
    this.data = const {},
    this.isRead = false,
    this.createdAt,
  });

  factory AppNotification.fromJson(Json j) => AppNotification(
    id: j.intv('id'),
    type: j.str('type'),
    screen: j.str('screen', 'none'),
    title: j.str('title'),
    body: j.str('body'),
    data: j.obj('data'),
    isRead: j.flag('is_read'),
    createdAt: j.date('created_at'),
  );

  final int id;
  final String type, screen, title, body;
  final Json data;
  final bool isRead;
  final DateTime? createdAt;

  /// معرّف من `data` (`membership_id`، `player_id`...)، والخادم قد يرسله نصاً.
  int? ref(String key) => data.intOrNull(key);

  AppNotification asRead() => AppNotification(
    id: id,
    type: type,
    screen: screen,
    title: title,
    body: body,
    data: data,
    isRead: true,
    createdAt: createdAt,
  );

  @override
  List<Object?> get props => [id, type, screen, title, body, data, isRead, createdAt];
}
