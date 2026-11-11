import '../../../../core/core.dart';

/// حساب بصفحة الحسابات (`GET club-admin/accounts`): كل الأدوار وحالة التفعيل وسبب منع الإجراءات.
class ClubAccount extends Equatable {
  const ClubAccount({
    required this.id,
    required this.name,
    this.phone = '',
    this.memberCode = '',
    this.roles = const [],
    this.roleLabel = '',
    this.isOwner = false,
    this.isSelf = false,
    this.state = 'active',
    this.stateLabel = '',
    this.lastLoginAt,
    this.blockedReason,
    this.sharedAccount = false,
  });

  factory ClubAccount.fromJson(Json j) => ClubAccount(
    id: j.intv('id'),
    name: j.str('name', '—'),
    phone: j.str('phone'),
    memberCode: j.str('member_code'),
    roles: j.strList('roles'),
    roleLabel: j.str('role_label'),
    isOwner: j.flag('is_owner'),
    isSelf: j.flag('is_self'),
    state: j.str('state', 'active'),
    stateLabel: j.str('state_label'),
    lastLoginAt: j.date('last_login_at'),
    blockedReason: j.strOrNull('blocked_reason'),
    sharedAccount: j.flag('shared_account'),
  );

  final int id;
  final String name, phone, memberCode, roleLabel, state, stateLabel;
  final List<String> roles;
  final bool isOwner, isSelf, sharedAccount;
  final DateTime? lastLoginAt;

  /// سبب منع الإجراءات من الخادم (حساب المالك، حسابك...)، أو null.
  final String? blockedReason;

  /// كلمة السر: لا لحساب مرتبط بنادٍ آخر ولا لما يمنعه الخادم.
  bool get canResetPassword => blockedReason == null && !sharedAccount;

  @override
  List<Object?> get props => [
    id,
    name,
    phone,
    memberCode,
    roles,
    roleLabel,
    isOwner,
    isSelf,
    state,
    stateLabel,
    lastLoginAt,
    blockedReason,
    sharedAccount,
  ];
}

/// بيانات دخول صادرة (مرة واحدة) من `POST accounts/reset-passwords`، وهي نفسها جسم بطاقة الطباعة.
class IssuedCredential extends Equatable {
  const IssuedCredential({
    required this.userId,
    required this.name,
    this.roleLabel = '',
    this.memberCode = '',
    this.phone = '',
    required this.password,
    this.expiresAt,
    this.whatsappMessage,
  });

  factory IssuedCredential.fromJson(Json j) => IssuedCredential(
    userId: j.intv('user_id'),
    name: j.str('name', '—'),
    roleLabel: j.str('role_label'),
    memberCode: j.str('member_code'),
    phone: j.str('phone'),
    password: j.str('temporary_password'),
    expiresAt: j.strOrNull('expires_at'),
    whatsappMessage: j.strOrNull('whatsapp_message'),
  );

  final int userId;
  final String name, roleLabel, memberCode, phone, password;
  final String? expiresAt, whatsappMessage;

  /// بطاقة `POST accounts/cards/pdf` (الكلمات لا تُخزَّن بالخادم، فتُرسل من هنا).
  Json card() => {
    'name': name,
    'role_label': roleLabel,
    'member_code': memberCode,
    'phone': phone,
    'temporary_password': password,
    'expires_at': ?expiresAt,
  };

  @override
  List<Object?> get props => [userId, name, roleLabel, memberCode, phone, password, expiresAt, whatsappMessage];
}

/// نتيجة إعادة كلمات السر: الصادرة، والمتخطاة بسببها (حساب المالك، مرتبط بنادٍ آخر...).
class ResetResult extends Equatable {
  const ResetResult({this.credentials = const [], this.skipped = const [], this.message});

  factory ResetResult.fromJson(Json j) => ResetResult(
    credentials: j.list('credentials', IssuedCredential.fromJson),
    skipped: j.list('skipped', (s) => (name: s.str('name', '—'), reason: s.str('reason'))),
  );

  final List<IssuedCredential> credentials;
  final List<({String name, String reason})> skipped;
  final String? message;

  ResetResult withMessage(String? m) => ResetResult(credentials: credentials, skipped: skipped, message: m);

  @override
  List<Object?> get props => [credentials, skipped, message];
}

/// حد حسابات الموظفين بالباقة (`GET club-admin/club` ← `usage.staff`): المالك والاستقبال، لا المدربون والعمال.
class StaffUsage extends Equatable {
  const StaffUsage({this.used = 0, this.limit});

  factory StaffUsage.fromJson(Json j) {
    final s = j.obj('usage').obj('staff');
    return StaffUsage(used: s.intv('used'), limit: s.intOrNull('limit'));
  }

  final int used;

  /// null = بلا حد.
  final int? limit;

  bool get reached => limit != null && used >= limit!;

  @override
  List<Object?> get props => [used, limit];
}
