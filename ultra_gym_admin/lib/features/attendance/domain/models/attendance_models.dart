import '../../../../core/core.dart';
import '../../../members/domain/models/member_profile_models.dart';

/// صف سجل الحضور `GET club-admin/attendance`: سجل الدخول (نفس سجل ملف العضو) + العضو والاشتراك ومن سجّله.
/// الرد بلا معرّف العضو ولا خطته ولا الجهاز: الصف يعرض ما يرجعه الخادم فقط.
class AttendanceRow extends Equatable {
  const AttendanceRow({
    required this.entry,
    required this.playerId,
    required this.playerName,
    this.membershipId,
    this.isOffline = false,
    this.recordedBy,
  });

  factory AttendanceRow.fromJson(Json j) {
    final player = j.obj('player');
    return AttendanceRow(
      entry: AttendanceEntry.fromJson(j),
      playerId: player.intv('id'),
      playerName: player.str('name', '—'),
      membershipId: j.intOrNull('membership_id'),
      isOffline: j.flag('is_offline'),
      recordedBy: j.objOrNull('recorded_by')?.strOrNull('name'),
    );
  }

  final AttendanceEntry entry;
  final int playerId;
  final String playerName;
  final int? membershipId;
  final bool isOffline;
  final String? recordedBy;

  int get id => entry.id;

  @override
  List<Object?> get props => [entry, playerId, playerName, membershipId, isOffline, recordedBy];
}

/// حضور يوم العمل بفرع `GET club-admin/attendance/today?branch_id=`: الأرقام والدخول حسب الساعة كما من الخادم.
class AttendanceToday extends Equatable {
  const AttendanceToday({
    this.branchName,
    this.businessDate,
    this.accepted = 0,
    this.rejected = 0,
    this.inGrace = 0,
    this.dayPasses = 0,
    this.sessionsConsumed = 0,
    this.byHour = const {},
  });

  factory AttendanceToday.fromJson(Json j) => AttendanceToday(
    branchName: j.objOrNull('branch')?.strOrNull('name'),
    businessDate: j.day('business_date'),
    accepted: j.intv('accepted'),
    rejected: j.intv('rejected'),
    inGrace: j.intv('in_grace'),
    dayPasses: j.intv('day_passes'),
    sessionsConsumed: j.intv('sessions_consumed'),
    byHour: {for (final h in j.list('by_hour', (h) => h)) h.intv('hour'): h.intv('count')},
  );

  final String? branchName;
  final DateTime? businessDate;
  final int accepted, rejected, inGrace, dayPasses, sessionsConsumed;

  /// الساعة (0-23 بتوقيت النادي) ← عدد الدخول المقبول. الساعات الفارغة غائبة.
  final Map<int, int> byHour;

  /// يوم العمل يبدأ صباحاً وينتهي 2 فجراً: ساعات العرض من 6 حتى 1 بعد منتصف الليل، وأي ساعة أخرى فيها دخول.
  static const dayStart = 6;

  List<({int hour, int count})> get hours {
    final all = {for (var h = dayStart; h < dayStart + 20; h++) h % 24, ...byHour.keys};
    final sorted = all.toList()..sort((a, b) => ((a - dayStart) % 24).compareTo((b - dayStart) % 24));
    return [for (final h in sorted) (hour: h, count: byHour[h] ?? 0)];
  }

  /// ساعة الذروة (الأكثر دخولاً)، أو null بلا دخول.
  int? get peakHour =>
      byHour.isEmpty ? null : (byHour.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first.key;

  @override
  List<Object?> get props => [
    branchName,
    businessDate,
    accepted,
    rejected,
    inGrace,
    dayPasses,
    sessionsConsumed,
    byHour,
  ];
}

/// نوع نتيجة تسجيل الدخول: مقبول (201)، مكرر خلال المدة (200 `ALREADY_CHECKED_IN`)، أو مرفوض (409 والسجل محفوظ).
enum CheckInKind { accepted, duplicate, rejected }

/// نتيجة `POST club-admin/attendance/check-in`: السجل + بطاقة العضو واشتراكه + رسالة الخادم.
/// الرفض (409) يصل هنا نتيجةً لا خطأً لأن الخادم يحفظه ويرجع العضو معه.
class CheckInResult extends Equatable {
  const CheckInResult({
    required this.kind,
    required this.message,
    required this.record,
    required this.playerId,
    required this.playerName,
    this.code,
    this.memberCode,
    this.phone,
    this.membership,
    this.sessionConsumed = false,
  });

  factory CheckInResult.fromJson(Json j, {required String message, String? code}) {
    final record = AttendanceEntry.fromJson(j.obj('record'));
    final player = j.obj('player');
    return CheckInResult(
      kind: j.flag('duplicate')
          ? CheckInKind.duplicate
          : (record.status == 'rejected' ? CheckInKind.rejected : CheckInKind.accepted),
      message: message,
      code: code ?? record.rejectionReason,
      record: record,
      playerId: player.intv('id'),
      playerName: player.str('name', '—'),
      memberCode: player.strOrNull('member_code'),
      phone: player.strOrNull('phone'),
      membership: switch (player.objOrNull('membership')) {
        final m? => MembershipItem.fromJson(m),
        null => null,
      },
      sessionConsumed: j['session_consumption'] is Map,
    );
  }

  final CheckInKind kind;

  /// رسالة الخادم كما هي ("تم تسجيل الدخول"، "اللاعب مسجّل دخوله مسبقاً منذ…"، سبب الرفض).
  final String message;

  /// سبب الرفض (`EXPIRED`، `FROZEN`…) لاختيار الفعل التالي.
  final String? code;
  final AttendanceEntry record;
  final int playerId;
  final String playerName;
  final String? memberCode, phone;
  final MembershipItem? membership;
  final bool sessionConsumed;

  bool get inGrace => record.inGrace;

  @override
  List<Object?> get props => [
    kind,
    message,
    code,
    record,
    playerId,
    playerName,
    memberCode,
    phone,
    membership,
    sessionConsumed,
  ];
}

/// مفاتيح فلاتر السجل كما يقبلها الخادم.
abstract final class AttendanceFilters {
  static const status = 'status', method = 'method', from = 'from', to = 'to', branchId = 'branch_id';

  static const statuses = <FormOption<String>>[
    (value: 'accepted', label: 'المقبول'),
    (value: 'rejected', label: 'المرفوض'),
  ];

  static const methods = <FormOption<String>>[
    (value: 'manual', label: 'يدوي'),
    (value: 'code', label: 'بالمعرّف'),
    (value: 'qr', label: 'QR'),
    (value: 'day_pass', label: 'دخول يومي'),
  ];

  /// نافذة الخادم حين لا تُحدد فترة.
  static const defaultDays = 31;
}
