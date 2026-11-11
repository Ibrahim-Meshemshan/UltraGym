import '../../../../core/core.dart';
import '../../../members/domain/models/member_history_models.dart';
import 'memberships_models.dart';

export '../../../members/domain/models/member_history_models.dart' show AttendanceEntry, PaymentEntry;
export 'sale_models.dart' show MembershipQuote;

/// تفاصيل اشتراك `GET club-admin/memberships/{id}`: الصف نفسه + الحساب والتجميد والدفعات.
/// كل الحالات والمبالغ والأيام من الخادم كما هي.
class MembershipDetail extends Equatable {
  const MembershipDetail({
    required this.membership,
    this.planId,
    this.branchId,
    this.trainerId,
    this.priceUsd = 0,
    this.discountUsd = 0,
    this.dueSyp = 0,
    this.sessionsUsed = 0,
    this.commissionUsd,
    this.couponCode,
    this.freezes = const FreezeAllowance(),
    this.previousMembershipId,
    this.cancelledAt,
    this.cancellationReason,
    this.notes,
    this.createdAt,
    this.transactions = const [],
  });

  factory MembershipDetail.fromJson(Json j) => MembershipDetail(
    membership: MembershipRow.fromJson(j),
    planId: j.objOrNull('plan')?.intOrNull('id'),
    branchId: j.objOrNull('branch')?.intOrNull('id'),
    trainerId: j.objOrNull('trainer')?.intOrNull('id'),
    priceUsd: j.dbl('price_usd'),
    discountUsd: j.dbl('discount_usd'),
    dueSyp: j.dbl('due_syp'),
    sessionsUsed: j.intv('sessions_used'),
    commissionUsd: j.dblOrNull('trainer_commission_usd'),
    couponCode: j.objOrNull('coupon')?.strOrNull('code'),
    freezes: FreezeAllowance.fromJson(j.obj('freezes')),
    previousMembershipId: j.intOrNull('previous_membership_id'),
    cancelledAt: j.date('cancelled_at'),
    cancellationReason: j.strOrNull('cancellation_reason'),
    notes: j.strOrNull('notes'),
    createdAt: j.date('created_at'),
    transactions: asList(j['transactions'], PaymentEntry.fromJson),
  );

  final MembershipRow membership;
  final int? planId, branchId, trainerId, previousMembershipId;
  final double priceUsd, discountUsd, dueSyp;
  final double? commissionUsd;
  final int sessionsUsed;
  final String? couponCode, cancellationReason, notes;
  final FreezeAllowance freezes;
  final DateTime? cancelledAt, createdAt;
  final List<PaymentEntry> transactions;

  int get id => membership.id;
  String get status => membership.status;
  bool get isCancelled => status == 'cancelled';
  bool get isFrozen => status == 'frozen';
  bool get hasDebt => !isCancelled && membership.dueUsd > 0;

  /// التجميد مسموح بالخادم لاشتراك فعّال أو لم يبدأ (وإلا `MEMBERSHIP_NOT_ACTIVE`). الرصيد يفحصه الخادم.
  bool get canFreeze => status == 'active' || status == 'upcoming';

  /// استهلاك جلسة يدوياً: اشتراك جلسات فعّال (الخادم يرفض غيره برسالة).
  bool get canConsumeSession => membership.isSessions && status == 'active';

  @override
  List<Object?> get props => [
    membership,
    planId,
    branchId,
    trainerId,
    priceUsd,
    discountUsd,
    dueSyp,
    sessionsUsed,
    commissionUsd,
    couponCode,
    freezes,
    previousMembershipId,
    cancelledAt,
    cancellationReason,
    notes,
    createdAt,
    transactions,
  ];
}

/// حدود التجميد للاشتراك (من الخطة) وما استُخدم منها، وسجل التجميدات.
class FreezeAllowance extends Equatable {
  const FreezeAllowance({
    this.maxFreezes = 0,
    this.maxDays = 0,
    this.used = 0,
    this.daysUsed = 0,
    this.history = const [],
  });

  factory FreezeAllowance.fromJson(Json j) => FreezeAllowance(
    maxFreezes: j.intv('max_freezes'),
    maxDays: j.intv('max_freeze_days'),
    used: j.intv('freezes_used'),
    daysUsed: j.intv('freeze_days_used'),
    history: asList(j['history'], FreezeEntry.fromJson),
  );

  final int maxFreezes, maxDays, used, daysUsed;
  final List<FreezeEntry> history;

  @override
  List<Object?> get props => [maxFreezes, maxDays, used, daysUsed, history];
}

/// تجميد واحد: الفترة والأيام، وتاريخ فكّه المبكر إن فُكّ، والسبب.
class FreezeEntry extends Equatable {
  const FreezeEntry({required this.id, required this.days, this.startsOn, this.endsOn, this.endedEarlyOn, this.reason});

  factory FreezeEntry.fromJson(Json j) => FreezeEntry(
    id: j.intv('id'),
    days: j.intv('days'),
    startsOn: j.day('starts_on'),
    endsOn: j.day('ends_on'),
    endedEarlyOn: j.day('ended_early_on'),
    reason: j.strOrNull('reason'),
  );

  final int id, days;
  final DateTime? startsOn, endsOn, endedEarlyOn;
  final String? reason;

  @override
  List<Object?> get props => [id, days, startsOn, endsOn, endedEarlyOn, reason];
}

/// تبويبات صفحة الاشتراك.
enum MembershipDetailTab { payments, freezes, attendance }
