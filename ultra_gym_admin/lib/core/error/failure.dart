import 'package:equatable/equatable.dart';

/// نوع الخطأ. الواجهة تتصرف حسبه (وحسب `code` لرموز الأعمال) وليس حسب نص الرسالة.
enum FailureType {
  unauthenticated,
  invalidCredentials,
  passwordChangeRequired,
  temporaryPasswordExpired,
  accountSuspended,
  noActiveMembership,
  appNotAllowedForRole,
  tenantSuspended,
  subscriptionInactive,
  subscriptionExpired,
  featureNotAvailable,
  forbidden,
  branchForbidden,
  planLimitReached,
  notFound,
  conflict,
  validation,
  tooManyRequests,
  maintenance,
  server,
  network,
  timeout,
  offline,
  cancelled,
  unknown;

  /// من حقل `code` الثابت بالباك اند.
  static FailureType? fromCode(String? code) => code == null ? null : _byCode[code];

  /// احتياط من رقم حالة HTTP حين لا يوجد `code` معروف.
  static FailureType fromStatus(int? status) => switch (status) {
    401 => unauthenticated,
    403 => forbidden,
    404 => notFound,
    409 => conflict,
    422 => validation,
    429 => tooManyRequests,
    503 => maintenance,
    final int s when s >= 500 => server,
    _ => unknown,
  };

  static const _byCode = <String, FailureType>{
    'UNAUTHENTICATED': unauthenticated,
    'INVALID_CREDENTIALS': invalidCredentials,
    'PASSWORD_CHANGE_REQUIRED': passwordChangeRequired,
    'TEMPORARY_PASSWORD_EXPIRED': temporaryPasswordExpired,
    'ACCOUNT_SUSPENDED': accountSuspended,
    'NO_ACTIVE_MEMBERSHIP': noActiveMembership,
    'APP_NOT_ALLOWED_FOR_ROLE': appNotAllowedForRole,
    'TENANT_SUSPENDED': tenantSuspended,
    'SUBSCRIPTION_INACTIVE': subscriptionInactive,
    'SUBSCRIPTION_LOCKED': subscriptionInactive,
    'SUBSCRIPTION_EXPIRED': subscriptionExpired,
    'FEATURE_NOT_AVAILABLE': featureNotAvailable,
    'FORBIDDEN': forbidden,
    'BRANCH_FORBIDDEN': branchForbidden,
    'PLAN_LIMIT_REACHED': planLimitReached,
    'NOT_FOUND': notFound,
    'VALIDATION_ERROR': validation,
    'TOO_MANY_REQUESTS': tooManyRequests,
    'MAINTENANCE': maintenance,
    'SERVER_ERROR': server,
  };
}

/// خطأ موحّد يصل للواجهة بدل أي استثناء. الرسالة عربية جاهزة: ماذا حدث ثم ماذا تفعل.
class Failure extends Equatable {
  const Failure({
    required this.type,
    required this.message,
    this.code,
    this.statusCode,
    this.errors = const {},
    this.data,
    this.retryAfter,
  });

  final FailureType type;
  final String message;

  /// رمز الباك اند كما هو (مثل `CASH_SESSION_REQUIRED`) لرموز الأعمال ذات الفعل الخاص.
  final String? code;
  final int? statusCode;

  /// أخطاء الحقول (422) بمفاتيح لارافيل المنقّطة: `owner.phone`.
  final Map<String, List<String>> errors;

  /// تفاصيل إضافية من `data` (مثل `feature` أو سجل الدخول المرفوض).
  final Object? data;
  final Duration? retryAfter;

  bool hasCode(String value) => code == value;

  bool get isNetwork => type == FailureType.network || type == FailureType.timeout || type == FailureType.offline;

  /// أخطاء تنهي الجلسة أو تحجبها: يتصرف بها AuthBloc والراوتر.
  bool get isSession => const {
    FailureType.unauthenticated,
    FailureType.passwordChangeRequired,
    FailureType.accountSuspended,
    FailureType.tenantSuspended,
    FailureType.subscriptionInactive,
  }.contains(type);

  /// الميزة غير المشمولة بالباقة (`FEATURE_NOT_AVAILABLE` ← `data.feature`).
  String? get feature => data is Map ? (data! as Map)['feature']?.toString() : null;

  /// أول رسالة لكل حقل.
  Map<String, String> get fieldErrors => {
    for (final e in errors.entries)
      if (e.value.isNotEmpty) e.key: e.value.first,
  };

  /// خطأ حقل بالاسم الكامل، أو أول خطأ داخله: `fieldError('owner')` يطابق `owner.phone`.
  String? fieldError(String field) {
    final exact = errors[field];
    if (exact != null && exact.isNotEmpty) return exact.first;
    for (final e in errors.entries) {
      if (e.key.startsWith('$field.') && e.value.isNotEmpty) return e.value.first;
    }
    return null;
  }

  @override
  List<Object?> get props => [type, message, code, statusCode, errors, retryAfter];
}
