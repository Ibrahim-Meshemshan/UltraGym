import '../../../../core/core.dart';
import 'member_models.dart';

// سطور تبويبي الحضور والدفعات بملف منفصل (حد 300 سطر).
export 'member_history_models.dart';

/// ملف العضو الكامل `GET club-admin/players/{id}`: الحساب + الملف + الاشتراك الحالي + الإحصاءات.
/// الحالة والدين والأيام والزيارات من الخادم كما هي.
class MemberProfile extends Equatable {
  const MemberProfile({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.status = 'active',
    this.suspendedAt,
    this.suspensionReason,
    this.joinedAt,
    this.archivedAt,
    this.memberCode,
    this.mustChangePassword = false,
    this.lastLoginAt,
    this.branchId,
    this.branchName,
    this.gender,
    this.birthDate,
    this.emergencyName,
    this.emergencyPhone,
    this.address,
    this.notes,
    this.photoUrl,
    this.membership,
    this.membershipsCount = 0,
    this.dueUsd = 0,
    this.stats = const MemberStats(),
    this.measurement,
  });

  factory MemberProfile.fromJson(Json j) {
    final p = j.obj('profile');
    return MemberProfile(
      id: j.intv('id'),
      name: j.str('name'),
      phone: j.str('phone'),
      email: j.strOrNull('email'),
      status: j.str('status', 'active'),
      suspendedAt: j.date('suspended_at'),
      suspensionReason: j.strOrNull('suspension_reason'),
      joinedAt: j.date('joined_at'),
      archivedAt: j.date('archived_at'),
      memberCode: j.strOrNull('member_code'),
      mustChangePassword: j.flag('must_change_password'),
      lastLoginAt: j.date('last_login_at'),
      branchId: p.objOrNull('branch')?.intOrNull('id'),
      branchName: p.objOrNull('branch')?.strOrNull('name'),
      gender: p.strOrNull('gender'),
      birthDate: p.day('birth_date'),
      emergencyName: p.strOrNull('emergency_contact_name'),
      emergencyPhone: p.strOrNull('emergency_contact_phone'),
      address: p.strOrNull('address'),
      notes: p.strOrNull('notes'),
      photoUrl: p.strOrNull('photo_url'),
      membership: switch (j.objOrNull('current_membership')) {
        final m? => MembershipItem.fromJson(m),
        null => null,
      },
      membershipsCount: j.intv('memberships_count'),
      dueUsd: j.dbl('due_usd'),
      stats: MemberStats.fromJson(j.obj('stats')),
      measurement: switch (j.objOrNull('latest_measurement')) {
        final m? => Measurement.fromJson(m),
        null => null,
      },
    );
  }

  final int id;
  final String name, phone, status;
  final String? email,
      suspensionReason,
      memberCode,
      branchName,
      gender,
      emergencyName,
      emergencyPhone,
      address,
      notes,
      photoUrl;
  final DateTime? suspendedAt, joinedAt, archivedAt, lastLoginAt, birthDate;
  final bool mustChangePassword;
  final int? branchId;
  final MembershipItem? membership;
  final int membershipsCount;
  final double dueUsd;
  final MemberStats stats;
  final Measurement? measurement;

  bool get isSuspended => status == 'suspended';
  bool get isArchived => archivedAt != null;
  bool get hasDebt => dueUsd > 0;

  /// قيم نموذج التعديل بمفاتيح الخادم.
  Json get formValues => {
    'name': name,
    'phone': phone,
    'email': email,
    'gender': gender,
    'branch_id': branchId,
    'birth_date': birthDate,
    'emergency_contact_name': emergencyName,
    'emergency_contact_phone': emergencyPhone,
    'address': address,
    'notes': notes,
  };

  @override
  List<Object?> get props => [
    id,
    name,
    phone,
    email,
    status,
    suspendedAt,
    suspensionReason,
    joinedAt,
    archivedAt,
    memberCode,
    mustChangePassword,
    lastLoginAt,
    branchId,
    branchName,
    gender,
    birthDate,
    emergencyName,
    emergencyPhone,
    address,
    notes,
    photoUrl,
    membership,
    membershipsCount,
    dueUsd,
    stats,
    measurement,
  ];
}

/// اشتراك بالملف أو بسجل `GET club-admin/memberships?player_id=`: الحالة + المال + المدرب.
class MembershipItem extends CurrentMembership {
  const MembershipItem({
    required super.id,
    required super.planName,
    required super.status,
    required super.statusLabel,
    super.type,
    super.startsOn,
    super.endsOn,
    super.daysRemaining,
    super.sessionsRemaining,
    super.frozenUntil,
    this.sessionsTotal,
    this.branchName,
    this.trainerName,
    this.netUsd = 0,
    this.paidUsd = 0,
    this.dueUsd = 0,
  });

  factory MembershipItem.fromJson(Json j) {
    final base = CurrentMembership.fromJson(j);
    return MembershipItem(
      id: base.id,
      planName: base.planName,
      status: base.status,
      statusLabel: base.statusLabel,
      type: base.type,
      startsOn: base.startsOn,
      endsOn: base.endsOn,
      daysRemaining: base.daysRemaining,
      sessionsRemaining: base.sessionsRemaining,
      frozenUntil: base.frozenUntil,
      sessionsTotal: j.intOrNull('sessions_total'),
      branchName: j.objOrNull('branch')?.strOrNull('name'),
      trainerName: j.objOrNull('trainer')?.strOrNull('name'),
      netUsd: j.dbl('net_usd'),
      paidUsd: j.dbl('paid_usd'),
      dueUsd: j.dbl('due_usd'),
    );
  }

  final int? sessionsTotal;
  final String? branchName, trainerName;
  final double netUsd, paidUsd, dueUsd;

  @override
  List<Object?> get props => [...super.props, sessionsTotal, branchName, trainerName, netUsd, paidUsd, dueUsd];
}

/// أرقام النشاط من الخادم: الزيارات المقبولة ومجموع المدفوع.
class MemberStats extends Equatable {
  const MemberStats({this.visitsTotal = 0, this.visitsThisMonth = 0, this.lastVisitAt, this.paidTotalUsd = 0});

  factory MemberStats.fromJson(Json j) => MemberStats(
    visitsTotal: j.intv('visits_total'),
    visitsThisMonth: j.intv('visits_this_month'),
    lastVisitAt: j.date('last_visit_at'),
    paidTotalUsd: j.dbl('paid_total_usd'),
  );

  final int visitsTotal, visitsThisMonth;
  final DateTime? lastVisitAt;
  final double paidTotalUsd;

  @override
  List<Object?> get props => [visitsTotal, visitsThisMonth, lastVisitAt, paidTotalUsd];
}

/// آخر قياس جسم (يسجله النادي).
class Measurement extends Equatable {
  const Measurement({this.measuredOn, this.weightKg, this.heightCm, this.bodyFat});

  factory Measurement.fromJson(Json j) => Measurement(
    measuredOn: j.day('measured_on'),
    weightKg: j.dblOrNull('weight_kg'),
    heightCm: j.dblOrNull('height_cm'),
    bodyFat: j.dblOrNull('body_fat_percent'),
  );

  final DateTime? measuredOn;
  final double? weightKg, heightCm, bodyFat;

  @override
  List<Object?> get props => [measuredOn, weightKg, heightCm, bodyFat];
}
