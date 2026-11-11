import '../../../../core/core.dart';

/// تذكرة دعم مع فريق المنصة (`SupportTicketController::ticketPayload`). لا ملاحظات داخلية ولا أسماء المشرفين.
class SupportTicket extends Equatable {
  const SupportTicket({
    required this.id,
    required this.number,
    required this.subject,
    required this.category,
    required this.priority,
    required this.status,
    this.repliesCount = 0,
    this.lastReplyAt,
    this.awaitingReply = false,
    this.createdAt,
  });

  factory SupportTicket.fromJson(Json j) => SupportTicket(
    id: j.intv('id'),
    number: j.str('number'),
    subject: j.str('subject'),
    category: j.str('category'),
    priority: j.str('priority'),
    status: j.str('status'),
    repliesCount: j.intv('replies_count'),
    lastReplyAt: j.date('last_reply_at'),
    awaitingReply: j.flag('awaiting_reply'),
    createdAt: j.date('created_at'),
  );

  final int id;
  final String number, subject;

  /// `technical · billing · inquiry · feature_request`.
  final String category;

  /// `low · medium · high · urgent`.
  final String priority;

  /// `open · in_progress · resolved · closed`.
  final String status;
  final int repliesCount;
  final DateTime? lastReplyAt, createdAt;

  /// آخر رد من فريق الدعم والتذكرة غير مغلقة (من الخادم).
  final bool awaitingReply;

  bool get isClosed => status == 'closed';

  @override
  List<Object?> get props => [id, number, subject, category, priority, status, repliesCount, lastReplyAt, awaitingReply];
}

/// مرفق رد: رابط موقّع مؤقت يُفتح مباشرة (لا يحتاج التوكن).
class TicketAttachment extends Equatable {
  const TicketAttachment({required this.id, required this.name, this.url, this.sizeKb = 0});

  factory TicketAttachment.fromJson(Json j) =>
      TicketAttachment(id: j.intv('id'), name: j.str('name'), url: j.strOrNull('url'), sizeKb: j.intv('size_kb'));

  final int id;
  final String name;
  final String? url;
  final int sizeKb;

  @override
  List<Object?> get props => [id, name, url, sizeKb];
}

/// رسالة بالتذكرة: من النادي (`user`) أو من "فريق الدعم" (`support`).
class TicketReply extends Equatable {
  const TicketReply({
    required this.id,
    required this.fromSupport,
    required this.author,
    required this.message,
    this.attachments = const [],
    this.createdAt,
  });

  factory TicketReply.fromJson(Json j) {
    final a = j.obj('author');
    return TicketReply(
      id: j.intv('id'),
      fromSupport: a.str('type') == 'support',
      author: a.str('name'),
      message: j.str('message'),
      attachments: asList(j['attachments'], TicketAttachment.fromJson),
      createdAt: j.date('created_at'),
    );
  }

  final int id;
  final bool fromSupport;
  final String author, message;
  final List<TicketAttachment> attachments;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [id, fromSupport, author, message, attachments, createdAt];
}

/// `GET support/tickets/{id}`: التذكرة وآخر 200 رد بالترتيب الزمني.
class TicketThread extends Equatable {
  const TicketThread({required this.ticket, this.replies = const [], this.truncated = false});

  factory TicketThread.fromJson(Json j) => TicketThread(
    ticket: SupportTicket.fromJson(j.obj('ticket')),
    replies: asList(j['replies'], TicketReply.fromJson),
    truncated: j.flag('replies_truncated'),
  );

  final SupportTicket ticket;
  final List<TicketReply> replies;
  final bool truncated;

  @override
  List<Object?> get props => [ticket, replies, truncated];
}

/// نصوص الدعم: قيم الخادم الثابتة بلا تسمية بالرد.
abstract final class SupportTexts {
  static const categories = [
    (value: 'technical', label: 'مشكلة تقنية'),
    (value: 'billing', label: 'الاشتراك والفواتير'),
    (value: 'inquiry', label: 'استفسار'),
    (value: 'feature_request', label: 'طلب ميزة'),
  ];

  static const priorities = [
    (value: 'low', label: 'منخفضة'),
    (value: 'medium', label: 'متوسطة'),
    (value: 'high', label: 'عالية'),
    (value: 'urgent', label: 'عاجلة'),
  ];

  static const statuses = [
    (value: 'open', label: 'مفتوحة'),
    (value: 'in_progress', label: 'قيد المعالجة'),
    (value: 'resolved', label: 'محلولة'),
    (value: 'closed', label: 'مغلقة'),
  ];

  /// امتدادات المرفقات المقبولة بالخادم (`TicketAttachments::rules`)، حتى 5 ملفات و 5MB لكل ملف.
  static const attachmentExtensions = [
    'jpg', 'jpeg', 'png', 'webp', 'gif', 'pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt', 'mp3', 'm4a', 'ogg', 'wav', //
  ];
  static const maxAttachments = 5;
  static const maxAttachmentBytes = 5 * 1024 * 1024;

  static String category(String v) => _label(categories, v);
  static String priority(String v) => _label(priorities, v);

  /// "بانتظار ردك" يغلب الحالة حين يكون آخر رد من الدعم.
  static ({String label, UTone tone}) status(SupportTicket t) => t.awaitingReply
      ? (label: 'بانتظار ردك', tone: UTone.info)
      : switch (t.status) {
          'open' => (label: 'مفتوحة', tone: UTone.warning),
          'in_progress' => (label: 'قيد المعالجة', tone: UTone.info),
          'resolved' => (label: 'محلولة', tone: UTone.success),
          'closed' => (label: 'مغلقة', tone: UTone.neutral),
          _ => (label: t.status, tone: UTone.neutral),
        };

  static String size(int kb) => kb >= 1024 ? '${(kb / 1024).toStringAsFixed(1)} MB' : '$kb KB';

  static String _label(List<FormOption<String>> options, String v) {
    for (final o in options) {
      if (o.value == v) return o.label;
    }
    return v;
  }
}
