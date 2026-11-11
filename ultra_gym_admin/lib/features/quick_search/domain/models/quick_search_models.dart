import '../../../../core/core.dart';

/// نتيجة البحث السريع `GET club-admin/players/lookup`: العضو + اشتراكه الحالي + إمكانية دخوله
/// للفرع المرسل (`can_enter` وسبب الرفض محسوبان بالخادم، لا تُحسب محلياً).
class LookupPlayer extends Equatable {
  const LookupPlayer({
    required this.id,
    required this.name,
    this.phone,
    this.memberCode,
    this.membership,
    this.canEnter = false,
    this.rejectionReason,
    this.rejectionMessage,
  });

  factory LookupPlayer.fromJson(Json j) => LookupPlayer(
    id: j.intv('id'),
    name: j.str('name'),
    phone: j.strOrNull('phone'),
    memberCode: j.strOrNull('member_code'),
    membership: switch (j.objOrNull('membership')) {
      final m? => LookupMembership.fromJson(m),
      null => null,
    },
    canEnter: j.flag('can_enter'),
    rejectionReason: j.strOrNull('rejection_reason'),
    rejectionMessage: j.strOrNull('rejection_message'),
  );

  final int id;
  final String name;
  final String? phone, memberCode;
  final LookupMembership? membership;
  final bool canEnter;

  /// رمز الرفض (`EXPIRED`، `FROZEN`...) ورسالته العربية الجاهزة.
  final String? rejectionReason, rejectionMessage;

  @override
  List<Object?> get props => [id, name, phone, memberCode, membership, canEnter, rejectionReason, rejectionMessage];
}

/// الاشتراك الحالي كما يظهر بنتيجة البحث (الحالة والأيام والدين من الخادم).
class LookupMembership extends Equatable {
  const LookupMembership({
    required this.id,
    required this.status,
    this.statusLabel,
    this.planName,
    this.endsOn,
    this.daysRemaining,
    this.sessionsRemaining,
    this.dueUsd = 0,
  });

  factory LookupMembership.fromJson(Json j) => LookupMembership(
    id: j.intv('id'),
    status: j.str('status'),
    statusLabel: j.strOrNull('status_label'),
    planName: j.obj('plan').strOrNull('name'),
    endsOn: j.day('ends_on'),
    daysRemaining: j.intOrNull('days_remaining'),
    sessionsRemaining: j.intOrNull('sessions_remaining'),
    dueUsd: j.dbl('due_usd'),
  );

  final int id;
  final String status;
  final String? statusLabel, planName;
  final DateTime? endsOn;
  final int? daysRemaining, sessionsRemaining;
  final double dueUsd;

  bool get hasDebt => dueUsd > 0;

  @override
  List<Object?> get props => [id, status, statusLabel, planName, endsOn, daysRemaining, sessionsRemaining, dueUsd];
}
