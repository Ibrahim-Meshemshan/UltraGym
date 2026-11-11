import '../../../../core/core.dart';

/// صف بقائمة الأعضاء `GET club-admin/players`: الحساب + الفرع + الاشتراك الحالي + مجموع الدين.
/// الحالة والدين والأيام المتبقية من الخادم كما هي.
class MemberRow extends Equatable {
  const MemberRow({
    required this.id,
    required this.name,
    required this.phone,
    this.memberCode,
    this.status = 'active',
    this.gender,
    this.branchName,
    this.photoUrl,
    this.membership,
    this.dueUsd = 0,
  });

  factory MemberRow.fromJson(Json j) => MemberRow(
    id: j.intv('id'),
    name: j.str('name'),
    phone: j.str('phone'),
    memberCode: j.strOrNull('member_code'),
    status: j.str('status', 'active'),
    gender: j.strOrNull('gender'),
    branchName: j.objOrNull('branch')?.strOrNull('name'),
    photoUrl: j.strOrNull('photo_url'),
    membership: switch (j.objOrNull('current_membership')) {
      final m? => CurrentMembership.fromJson(m),
      null => null,
    },
    dueUsd: j.dbl('due_usd'),
  );

  final int id;
  final String name, phone, status;
  final String? memberCode, gender, branchName, photoUrl;
  final CurrentMembership? membership;
  final double dueUsd;

  /// حساب العضو (لا الاشتراك): `suspended` ← شارة "حساب موقوف" بجانب الاسم.
  bool get isSuspended => status == 'suspended';
  bool get isArchived => status == 'archived';
  bool get hasDebt => dueUsd > 0;

  @override
  List<Object?> get props => [id, name, phone, memberCode, status, gender, branchName, photoUrl, membership, dueUsd];
}

/// الاشتراك الحالي كما يختاره الخادم (فعّال، ثم مجمّد، ثم سماح، ثم لم يبدأ، ثم الأحدث).
class CurrentMembership extends Equatable {
  const CurrentMembership({
    required this.id,
    required this.planName,
    required this.status,
    required this.statusLabel,
    this.type = 'duration',
    this.startsOn,
    this.endsOn,
    this.daysRemaining,
    this.sessionsRemaining,
    this.frozenUntil,
  });

  factory CurrentMembership.fromJson(Json j) => CurrentMembership(
    id: j.intv('id'),
    planName: j.obj('plan').str('name', '—'),
    type: j.str('type', 'duration'),
    status: j.str('status'),
    statusLabel: j.str('status_label', Labels.membershipStatus(j.strOrNull('status')).text),
    startsOn: j.day('starts_on'),
    endsOn: j.day('ends_on'),
    daysRemaining: j.intOrNull('days_remaining'),
    sessionsRemaining: j.intOrNull('sessions_remaining'),
    frozenUntil: j.day('frozen_until'),
  );

  final int id;
  final String planName, type, status, statusLabel;
  final DateTime? startsOn, endsOn, frozenUntil;
  final int? daysRemaining, sessionsRemaining;

  bool get isSessions => type == 'sessions';

  @override
  List<Object?> get props => [
    id,
    planName,
    type,
    status,
    statusLabel,
    startsOn,
    endsOn,
    daysRemaining,
    sessionsRemaining,
    frozenUntil,
  ];
}

/// أعداد التبويبين (من `meta.pagination.total` لطلب بصف واحد).
class MemberCounts extends Equatable {
  const MemberCounts({required this.members, required this.archived});

  final int members, archived;

  @override
  List<Object?> get props => [members, archived];
}

/// رد `POST club-admin/players`: بيانات الدخول تظهر مرة واحدة فقط.
/// حساب موجود مسبقاً (`is_existing_account`) يُربط بالنادي بلا كلمة سر جديدة.
class NewMember extends Equatable {
  const NewMember({
    required this.id,
    required this.name,
    required this.phone,
    this.memberCode,
    this.isExistingAccount = false,
    this.temporaryPassword,
    this.passwordExpiresAt,
    this.whatsappMessage,
  });

  factory NewMember.fromJson(Json j) => NewMember(
    id: j.intv('id'),
    name: j.str('name'),
    phone: j.str('phone'),
    memberCode: j.strOrNull('member_code'),
    isExistingAccount: j.flag('is_existing_account'),
    temporaryPassword: j.strOrNull('temporary_password'),
    passwordExpiresAt: j.date('temporary_password_expires_at'),
    whatsappMessage: j.strOrNull('whatsapp_message'),
  );

  final int id;
  final String name, phone;
  final String? memberCode, temporaryPassword, whatsappMessage;
  final DateTime? passwordExpiresAt;
  final bool isExistingAccount;

  @override
  List<Object?> get props => [
    id,
    name,
    phone,
    memberCode,
    isExistingAccount,
    temporaryPassword,
    passwordExpiresAt,
    whatsappMessage,
  ];
}

/// التبويب: الأعضاء الحاليون أو الأرشيف (`archived=only`).
enum MembersTab { current, archive }

/// فلاتر القائمة بمفاتيح الخادم.
abstract final class MemberFilters {
  static const membershipStatus = 'membership_status';
  static const hasDebt = 'has_debt';
  static const branchId = 'branch_id';
  static const gender = 'gender';

  /// قيم `membership_status` المقبولة بالخادم (لا فلتر "لم يبدأ").
  static const statuses = <FormOption<String>>[
    (value: 'active', label: 'فعّال'),
    (value: 'expiring', label: 'تنتهي قريباً'),
    (value: 'grace', label: 'بفترة السماح'),
    (value: 'frozen', label: 'مجمّد'),
    (value: 'expired', label: 'منتهٍ'),
    (value: 'none', label: 'بلا اشتراك'),
  ];

  static const genders = <FormOption<String>>[(value: 'male', label: 'ذكر'), (value: 'female', label: 'أنثى')];
}
