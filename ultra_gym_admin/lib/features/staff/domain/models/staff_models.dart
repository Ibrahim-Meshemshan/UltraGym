import '../../../../core/core.dart';

export 'account_models.dart';

/// مرجع فرع مختصر (`{id, name}`).
typedef BranchRef = ({int id, String name});

BranchRef _ref(Json j) => (id: j.intv('id'), name: j.str('name', '—'));

/// حساب موظف استقبال (`GET club-admin/receptionists`، `MemberController::memberPayload` + `branches`).
class Receptionist extends Equatable {
  const Receptionist({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.status = 'active',
    this.suspensionReason,
    this.memberCode = '',
    this.mustChangePassword = false,
    this.lastLoginAt,
    this.branches = const [],
  });

  factory Receptionist.fromJson(Json j) => Receptionist(
    id: j.intv('id'),
    name: j.str('name', '—'),
    phone: j.str('phone'),
    email: j.strOrNull('email'),
    status: j.str('status', 'active'),
    suspensionReason: j.strOrNull('suspension_reason'),
    memberCode: j.str('member_code'),
    mustChangePassword: j.flag('must_change_password'),
    lastLoginAt: j.date('last_login_at'),
    branches: j.list('branches', _ref),
  );

  final int id;
  final String name, phone, status, memberCode;
  final String? email, suspensionReason;
  final bool mustChangePassword;
  final DateTime? lastLoginAt;
  final List<BranchRef> branches;

  bool get isArchived => status == 'archived';
  bool get isSuspended => status == 'suspended';

  @override
  List<Object?> get props => [
    id,
    name,
    phone,
    email,
    status,
    suspensionReason,
    memberCode,
    mustChangePassword,
    lastLoginAt,
    branches,
  ];
}

/// رد إضافة حساب استقبال: الحساب + كلمة السر المؤقتة مرة واحدة (أو ربط حساب موجود بلا كلمة).
class ReceptionistCreated extends Equatable {
  const ReceptionistCreated({
    required this.account,
    this.isExistingAccount = false,
    this.temporaryPassword,
    this.expiresAt,
    this.whatsappMessage,
  });

  factory ReceptionistCreated.fromJson(Json j) => ReceptionistCreated(
    account: Receptionist.fromJson(j),
    isExistingAccount: j.flag('is_existing_account'),
    temporaryPassword: j.strOrNull('temporary_password'),
    expiresAt: j.date('temporary_password_expires_at'),
    whatsappMessage: j.strOrNull('whatsapp_message'),
  );

  final Receptionist account;
  final bool isExistingAccount;
  final String? temporaryPassword, whatsappMessage;
  final DateTime? expiresAt;

  @override
  List<Object?> get props => [account, isExistingAccount, temporaryPassword, expiresAt, whatsappMessage];
}

/// مدرب أو عامل (`GET club-admin/staff-members`، `ClubPayloads::staffMember`): سجل للرواتب والعمولات بلا حساب دخول.
class StaffMember extends Equatable {
  const StaffMember({
    required this.id,
    required this.name,
    this.phone,
    this.type = 'trainer',
    this.jobTitle,
    this.branch,
    this.salaryCurrency = 'USD',
    this.salaryAmount = 0,
    this.commissionType = 'percent',
    this.commissionPercent = 0,
    this.commissionFixedUsd = 0,
    this.status = 'active',
    this.hiredOn,
    this.notes,
    this.openAdvancesUsd = 0,
    this.archived = false,
  });

  factory StaffMember.fromJson(Json j) {
    final branch = j.obj('branch');
    return StaffMember(
      id: j.intv('id'),
      name: j.str('name', '—'),
      phone: j.strOrNull('phone'),
      type: j.str('type', 'trainer'),
      jobTitle: j.strOrNull('job_title'),
      branch: branch.isEmpty ? null : _ref(branch),
      salaryCurrency: j.str('salary_currency', 'USD'),
      salaryAmount: j.dbl('salary_amount'),
      commissionType: j.str('commission_type', 'percent'),
      commissionPercent: j.dbl('commission_percent'),
      commissionFixedUsd: j.dbl('commission_fixed_usd'),
      status: j.str('status', 'active'),
      hiredOn: j.strOrNull('hired_on'),
      notes: j.strOrNull('notes'),
      openAdvancesUsd: j.dbl('open_advances_usd'),
    );
  }

  final int id;
  final String name, type, salaryCurrency, commissionType, status;
  final String? phone, jobTitle, hiredOn, notes;
  final BranchRef? branch;
  final double salaryAmount, commissionPercent, commissionFixedUsd, openAdvancesUsd;

  /// من تبويب الأرشيف (الخادم يرجعه موقوفاً؛ القائمة نفسها تحدد أنه مؤرشف).
  final bool archived;

  bool get isTrainer => type == 'trainer';
  bool get isActive => status == 'active';

  StaffMember asArchived() => StaffMember(
    id: id,
    name: name,
    phone: phone,
    type: type,
    jobTitle: jobTitle,
    branch: branch,
    salaryCurrency: salaryCurrency,
    salaryAmount: salaryAmount,
    commissionType: commissionType,
    commissionPercent: commissionPercent,
    commissionFixedUsd: commissionFixedUsd,
    status: status,
    hiredOn: hiredOn,
    notes: notes,
    openAdvancesUsd: openAdvancesUsd,
    archived: true,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    phone,
    type,
    jobTitle,
    branch,
    salaryCurrency,
    salaryAmount,
    commissionType,
    commissionPercent,
    commissionFixedUsd,
    status,
    hiredOn,
    notes,
    openAdvancesUsd,
    archived,
  ];
}
