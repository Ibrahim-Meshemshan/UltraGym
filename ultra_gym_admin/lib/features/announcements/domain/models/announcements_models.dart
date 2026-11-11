
import '../../../../core/core.dart';

typedef AnnouncementBranch = ({int id, String name});

/// إعلان النادي للاعبيه كما بـ `GET club-admin/announcements`. الحالة `state` من الخادم:
/// `draft` (بلا `published_at`)، `published`، `expired` (`expires_at` مضى). النشر فوري: لا جدولة.
class Announcement extends Equatable {
  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    this.audience = 'all',
    this.branch,
    this.sendPush = false,
    this.pushedAt,
    this.pushRecipients,
    this.state = 'draft',
    this.publishedAt,
    this.expiresAt,
    this.createdAt,
  });

  factory Announcement.fromJson(Json j) {
    final b = j.objOrNull('branch');
    return Announcement(
      id: j.intv('id'),
      title: j.str('title', '—'),
      body: j.str('body'),
      audience: j.str('audience', 'all'),
      branch: b == null ? null : (id: b.intv('id'), name: b.str('name')),
      sendPush: j.flag('send_push'),
      pushedAt: j.date('pushed_at'),
      pushRecipients: j.intOrNull('push_recipients'),
      state: j.str('state', 'draft'),
      publishedAt: j.date('published_at'),
      expiresAt: j.date('expires_at'),
      createdAt: j.date('created_at'),
    );
  }

  final int id;
  final String title, body, audience, state;

  /// null = كل الفروع.
  final AnnouncementBranch? branch;
  final bool sendPush;

  /// الإشعار يُرسل مرة واحدة: بعد `pushed_at` لا يُعاد مهما تغيّر.
  final DateTime? pushedAt;
  final int? pushRecipients;
  final DateTime? publishedAt, expiresAt, createdAt;

  bool get isDraft => state == AnnouncementState.draft;
  bool get isPublished => state == AnnouncementState.published;
  bool get pushed => pushedAt != null;

  @override
  List<Object?> get props => [
    id,
    title,
    body,
    audience,
    branch,
    sendPush,
    pushedAt,
    pushRecipients,
    state,
    publishedAt,
    expiresAt,
    createdAt,
  ];
}

abstract final class AnnouncementState {
  static const draft = 'draft', published = 'published', expired = 'expired';

  /// فلتر `state` بالقائمة (بلا "الكل" = بلا فلتر).
  static const filter = 'state';
}

/// نصوص الإعلانات بالقائمة والنافذة.
abstract final class AnnouncementTexts {
  static const audiences = <FormOption<String>>[
    (value: 'all', label: 'الكل'),
    (value: 'active', label: 'الفعّالون'),
    (value: 'expired', label: 'المنتهية اشتراكاتهم'),
  ];

  static const states = <FormOption<String>>[
    (value: AnnouncementState.published, label: 'منشورة'),
    (value: AnnouncementState.draft, label: 'مسودات'),
    (value: AnnouncementState.expired, label: 'منتهية'),
  ];

  /// الجمهور بسطر التفاصيل.
  static String audience(String a) => switch (a) {
    'active' => 'الفعّالون',
    'expired' => 'المنتهية اشتراكاتهم',
    _ => 'كل الأعضاء',
  };

  static String branch(Announcement a) => a.branch?.name ?? 'كل الفروع';

  static ({String text, UTone tone}) state(String s) => switch (s) {
    AnnouncementState.published => (text: 'منشور', tone: UTone.success),
    AnnouncementState.expired => (text: 'منتهٍ', tone: UTone.neutral),
    _ => (text: 'مسودة', tone: UTone.neutral),
  };

  /// متى: "لم يُنشر"، "نُشر 2026-11-02 · حتى 2026-11-16"، "انتهى 2026-10-25".
  static String when(Announcement a) {
    String d(DateTime? t) => Formatters.ltr(Formatters.date(t, fromUtc: true));
    return switch (a.state) {
      AnnouncementState.draft => 'لم يُنشر',
      AnnouncementState.expired => 'انتهى ${d(a.expiresAt)}',
      _ => a.expiresAt == null ? 'نُشر ${d(a.publishedAt)}' : 'نُشر ${d(a.publishedAt)} · حتى ${d(a.expiresAt)}',
    };
  }

  /// شارة الإشعار: أُرسل (بعدد من وصلهم)، أو ينتظر الإرسال بالخلفية، أو لا شيء.
  static String? push(Announcement a) {
    if (a.pushed) {
      final n = a.pushRecipients;
      return n == null ? 'أُرسل إشعاراً' : 'أُرسل إشعاراً لـ ${Formatters.count(n, 'عضو', 'عضوين', 'أعضاء', many: 'عضواً')}';
    }
    return a.isPublished && a.sendPush ? 'الإشعار قيد الإرسال' : null;
  }
}
