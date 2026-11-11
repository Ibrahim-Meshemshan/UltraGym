import '../../../../core/core.dart';

/// النادي كما يرجعه الخادم بالدخول و `me`.
class TenantRef extends Equatable {
  const TenantRef({required this.id, required this.name, this.slug = '', this.logoUrl, this.timezone});

  factory TenantRef.fromJson(Json j) => TenantRef(
        id: j.intv('id'),
        name: j.str('name'),
        slug: j.str('slug'),
        logoUrl: j.strOrNull('logo_url'),
        timezone: j.strOrNull('timezone'),
      );

  final int id;
  final String name, slug;
  final String? logoUrl, timezone;

  /// الحرف الأول لصورة النادي البديلة.
  String get initial => name.isEmpty ? '؟' : String.fromCharCode(name.runes.first);

  @override
  List<Object?> get props => [id, name, slug, logoUrl, timezone];
}

/// نادٍ يختاره المستخدم حين يرتبط حسابه بأكثر من نادٍ.
class TenantChoice extends Equatable {
  const TenantChoice({required this.tenant, this.roles = const []});

  factory TenantChoice.fromJson(Json j) => TenantChoice(tenant: TenantRef.fromJson(j.obj('tenant')), roles: j.strList('roles'));

  final TenantRef tenant;
  final List<String> roles;

  @override
  List<Object?> get props => [tenant, roles];
}

class AuthUser extends Equatable {
  const AuthUser({required this.id, required this.name, this.phone, this.email});

  factory AuthUser.fromJson(Json j) =>
      AuthUser(id: j.intv('id'), name: j.str('name'), phone: j.strOrNull('phone'), email: j.strOrNull('email'));

  final int id;
  final String name;
  final String? phone, email;

  @override
  List<Object?> get props => [id, name, phone, email];
}

/// الجلسة الحالية: من رد الدخول أو `me`. الصلاحيات من الخادم ولا تُحسب بالواجهة.
class Session extends Equatable {
  const Session({
    required this.user,
    this.tenant,
    this.roles = const [],
    this.permissions = const {},
    this.mustChangePassword = false,
    this.memberCode,
    this.otherTenantsCount = 0,
    this.isImpersonated = false,
    this.expiresAt,
  });

  /// يقبل كل أشكال الردود: دخول النادي و `me` (الحساب داخل `user` و `roles`)، ودخول لوحة المنصة
  /// (الحساب داخل `admin` ودوره `admin.role`)، و `me` لوحة المنصة (الحساب بالجذر مع `role`).
  factory Session.fromJson(Json j) {
    final account = j.objOrNull('user') ?? j.objOrNull('admin') ?? j;
    final role = j.strOrNull('role') ?? account.strOrNull('role');
    final roles = j.strList('roles');
    return Session(
      user: AuthUser.fromJson(account),
      tenant: j.objOrNull('tenant') == null ? null : TenantRef.fromJson(j.obj('tenant')),
      roles: [...roles, if (role != null && !roles.contains(role)) role],
      permissions: {for (final e in j.obj('permissions').entries) e.key: e.value == true},
      mustChangePassword: j.flag('must_change_password') || account.flag('must_change_password'),
      memberCode: j.strOrNull('member_code'),
      otherTenantsCount: j.intv('other_tenants_count'),
      isImpersonated: j.flag('is_impersonated'),
      expiresAt: j.date('expires_at') ?? j.obj('session').date('expires_at'),
    );
  }

  final AuthUser user;
  final TenantRef? tenant;
  final List<String> roles;
  final Map<String, bool> permissions;
  final bool mustChangePassword, isImpersonated;
  final String? memberCode;
  final int otherTenantsCount;
  final DateTime? expiresAt;

  bool hasRole(String role) => roles.contains(role);
  bool can(String permission) => permissions[permission] ?? false;

  bool get isClubOwner => hasRole('club_owner');
  bool get isReceptionist => hasRole('receptionist');
  bool get isPlatformOwner => hasRole('owner');
  bool get canViewFinance => can('can_view_finance');
  bool get canManageStaff => can('can_manage_staff');
  bool get canSwitchTenant => otherTenantsCount > 0;

  Session copyWith({bool? mustChangePassword}) => Session(
        user: user,
        tenant: tenant,
        roles: roles,
        permissions: permissions,
        mustChangePassword: mustChangePassword ?? this.mustChangePassword,
        memberCode: memberCode,
        otherTenantsCount: otherTenantsCount,
        isImpersonated: isImpersonated,
        expiresAt: expiresAt,
      );

  @override
  List<Object?> get props =>
      [user, tenant, roles, permissions, mustChangePassword, memberCode, otherTenantsCount, isImpersonated, expiresAt];
}

/// نتيجة طلب الدخول: جلسة جاهزة، أو قائمة نوادٍ للاختيار ثم إعادة الطلب مع `tenant_id`.
sealed class LoginOutcome extends Equatable {
  const LoginOutcome();
}

final class LoginSucceeded extends LoginOutcome {
  const LoginSucceeded(this.session);

  final Session session;

  @override
  List<Object?> get props => [session];
}

final class LoginNeedsTenant extends LoginOutcome {
  const LoginNeedsTenant(this.tenants);

  final List<TenantChoice> tenants;

  @override
  List<Object?> get props => [tenants];
}

/// رد `GET /app-version`: التحديث الإجباري يمنع الاستعمال.
class AppVersionInfo extends Equatable {
  const AppVersionInfo({
    required this.current,
    this.latest,
    this.minSupported,
    this.updateAvailable = false,
    this.forceUpdate = false,
    this.storeUrl,
    this.releaseNotes,
  });

  factory AppVersionInfo.fromJson(Json j, String current) => AppVersionInfo(
        current: current,
        latest: j.strOrNull('latest_version'),
        minSupported: j.strOrNull('min_supported_version'),
        updateAvailable: j.flag('update_available'),
        forceUpdate: j.flag('force_update'),
        storeUrl: j.strOrNull('store_url'),
        releaseNotes: j.strOrNull('release_notes'),
      );

  final String current;
  final String? latest, minSupported, storeUrl, releaseNotes;
  final bool updateAvailable, forceUpdate;

  @override
  List<Object?> get props => [current, latest, minSupported, updateAvailable, forceUpdate, storeUrl, releaseNotes];
}
