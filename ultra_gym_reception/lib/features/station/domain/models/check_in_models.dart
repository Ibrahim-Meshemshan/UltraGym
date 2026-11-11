import '../../../../core/core.dart';
import 'station_models.dart';

/// اشتراك العضو كما يرجع مع البحث ونتيجة الدخول (`membership`): الحالة والأيام والدين محسوبة من الخادم.
class MemberMembership extends Equatable {
  const MemberMembership({
    required this.id,
    required this.planName,
    required this.status,
    required this.statusLabel,
    this.isSessions = false,
    this.startsOn,
    this.endsOn,
    this.frozenUntil,
    this.daysRemaining,
    this.sessionsRemaining,
    this.dueUsd = 0,
  });

  factory MemberMembership.fromJson(Json j) => MemberMembership(
    id: j.intv('id'),
    planName: j.obj('plan').str('name', '—'),
    status: j.str('status'),
    statusLabel: j.strOrNull('status_label') ?? Labels.membershipStatus(j.strOrNull('status')).text,
    isSessions: j.strOrNull('type') == 'sessions',
    startsOn: j.day('starts_on'),
    endsOn: j.day('ends_on'),
    frozenUntil: j.day('frozen_until'),
    daysRemaining: j.intOrNull('days_remaining'),
    sessionsRemaining: j.intOrNull('sessions_remaining'),
    dueUsd: j.dbl('due_usd'),
  );

  final int id;
  final String planName, status, statusLabel;
  final bool isSessions;
  final DateTime? startsOn, endsOn, frozenUntil;
  final int? daysRemaining, sessionsRemaining;
  final double dueUsd;

  /// خانة "المتبقي" ببطاقة النتيجة حسب الحالة، بقيم الخادم كما هي.
  ({String label, String value}) get remaining => switch (status) {
    'frozen' => (label: 'مجمّد حتى', value: Formatters.date(frozenUntil)),
    'upcoming' => (label: 'يبدأ', value: Formatters.date(startsOn)),
    'expired' || 'grace' || 'cancelled' => (label: 'انتهى', value: Formatters.date(endsOn)),
    _ when isSessions => (label: 'الجلسات المتبقية', value: Formatters.number(sessionsRemaining)),
    _ => (label: 'المتبقي', value: daysRemaining == null ? '—' : Formatters.days(daysRemaining!)),
  };

  @override
  List<Object?> get props => [
    id,
    planName,
    status,
    statusLabel,
    isSessions,
    startsOn,
    endsOn,
    frozenUntil,
    daysRemaining,
    sessionsRemaining,
    dueUsd,
  ];
}

/// نتيجة البحث السريع (`GET club-admin/players/lookup?q=&branch_id=`) مع حكم الخادم: يدخل أو سبب المنع.
class LookupPlayer extends Equatable {
  const LookupPlayer({
    required this.id,
    required this.name,
    this.phone,
    this.memberCode,
    this.membership,
    this.canEnter = false,
    this.rejectionMessage,
  });

  factory LookupPlayer.fromJson(Json j) => LookupPlayer(
    id: j.intv('id'),
    name: j.str('name', '—'),
    phone: j.strOrNull('phone'),
    memberCode: j.strOrNull('member_code'),
    membership: switch (j.objOrNull('membership')) {
      final m? => MemberMembership.fromJson(m),
      null => null,
    },
    canEnter: j.flag('can_enter'),
    rejectionMessage: j.strOrNull('rejection_message'),
  );

  final int id;
  final String name;
  final String? phone, memberCode;
  final MemberMembership? membership;
  final bool canEnter;
  final String? rejectionMessage;

  @override
  List<Object?> get props => [id, name, phone, memberCode, membership, canEnter, rejectionMessage];
}

/// نوع النتيجة: مقبول (201)، مكرر خلال المدة (200 `ALREADY_CHECKED_IN`)، أو مرفوض (409 والسجل محفوظ).
enum CheckInKind { accepted, duplicate, rejected }

/// نتيجة `POST club-admin/attendance/check-in`: السجل + العضو واشتراكه + رسالة الخادم.
/// الرفض (409) يصل نتيجةً لا خطأً لأن الخادم يحفظه ويرجع العضو معه.
class CheckInResult extends Equatable {
  const CheckInResult({
    required this.kind,
    required this.message,
    required this.record,
    required this.name,
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
          : (record.isRejected ? CheckInKind.rejected : CheckInKind.accepted),
      message: message,
      code: record.isRejected ? (record.rejectionReason ?? code) : null,
      record: record,
      name: player.str('name', record.playerName),
      memberCode: player.strOrNull('member_code'),
      phone: player.strOrNull('phone'),
      membership: switch (player.objOrNull('membership')) {
        final m? => MemberMembership.fromJson(m),
        null => null,
      },
      sessionConsumed: j['session_consumption'] is Map,
    );
  }

  final CheckInKind kind;

  /// رسالة الخادم كما هي ("تم تسجيل الدخول"، "مسجّل دخوله مسبقاً منذ…"، سبب الرفض).
  final String message;

  /// سبب الرفض (`EXPIRED`، `GENDER_HOURS`…).
  final String? code;
  final AttendanceEntry record;
  final String name;
  final String? memberCode, phone;
  final MemberMembership? membership;
  final bool sessionConsumed;

  bool get inGrace => record.inGrace;

  @override
  List<Object?> get props => [kind, message, code, record, name, memberCode, phone, membership, sessionConsumed];
}

/// ما كتبه الموظف أو قرأه القارئ بالحقل: رمز QR، أو معرّف عضو، أو نص بحث (اسم أو موبايل).
sealed class StationInput {
  const StationInput();

  /// `UG1.` ← رمز QR من تطبيق العضو (كما هو: التوقيع حساس للأحرف)؛ `ABC-123456` ← معرّف بأحرف كبيرة؛
  /// غير ذلك بحث. null للفارغ.
  static StationInput? parse(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;
    if (text.startsWith('UG1.')) return QrInput(text);
    if (_code.hasMatch(text)) return CodeInput(text.toUpperCase());
    return SearchInput(text);
  }

  static final _code = RegExp(r'^[A-Za-z]{2,8}-\d{3,12}$');
}

final class QrInput extends StationInput {
  const QrInput(this.token);
  final String token;
}

final class CodeInput extends StationInput {
  const CodeInput(this.code);
  final String code;
}

final class SearchInput extends StationInput {
  const SearchInput(this.query);
  final String query;
}
