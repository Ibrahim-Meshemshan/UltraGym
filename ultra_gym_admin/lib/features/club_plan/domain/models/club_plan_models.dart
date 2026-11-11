import '../../../../core/core.dart';

/// أسماء ميزات الباقة كما بـ `GET /tenant/entitlements.features`.
abstract final class PlanFeature {
  static const playerApp = 'player_app';
  static const qrAttendance = 'qr_attendance';
  static const offlineReception = 'offline_reception';
  static const advancedFinance = 'advanced_finance';
  static const advancedReports = 'advanced_reports';
  static const reportsExport = 'reports_export';
  static const customBranding = 'custom_branding';
  static const prioritySupport = 'priority_support';
}

/// حدود الباقة (`null` = غير محدود).
class PlanLimits extends Equatable {
  const PlanLimits({this.players, this.staff, this.branches, this.storageMb});

  factory PlanLimits.fromJson(Json j) => PlanLimits(
    players: j.intOrNull('players'),
    staff: j.intOrNull('staff'),
    branches: j.intOrNull('branches'),
    storageMb: j.intOrNull('storage_mb'),
  );

  final int? players, staff, branches, storageMb;

  @override
  List<Object?> get props => [players, staff, branches, storageMb];
}

/// حدود باقة النادي وميزاتها الفعلية (بعد استثناءات المنصة).
class Entitlements extends Equatable {
  const Entitlements({this.limits = const PlanLimits(), this.features = const {}});

  factory Entitlements.fromJson(Json j) {
    final f = j.obj('features');
    return Entitlements(
      limits: PlanLimits.fromJson(j.obj('limits')),
      features: {for (final e in f.entries) e.key: e.value == true},
    );
  }

  final PlanLimits limits;
  final Map<String, bool> features;

  /// ميزة لا يذكرها الخادم تُعامل كمتاحة: الإخفاء للتوضيح فقط، والخادم يرفض على أي حال.
  bool has(String feature) => features[feature] ?? true;

  @override
  List<Object?> get props => [limits, features];
}

/// اشتراك النادي الحالي بالمنصة (`GET club-admin/billing/subscription.current`، للمالك فقط).
class ClubSubscription extends Equatable {
  const ClubSubscription({required this.status, this.planName, this.isTrial = false, this.endsOn, this.graceEndsOn});

  factory ClubSubscription.fromJson(Json j) => ClubSubscription(
    status: j.str('status'),
    planName: j.obj('plan').strOrNull('name'),
    isTrial: j.flag('is_trial'),
    endsOn: j.day('ends_at'),
    graceEndsOn: j.day('grace_ends_at'),
  );

  /// `trial · active · grace · expired (قراءة فقط) · locked · suspended · cancelled`.
  final String status;
  final String? planName;
  final bool isTrial;
  final DateTime? endsOn, graceEndsOn;

  bool get inGrace => status == 'grace';
  bool get isReadOnly => status == 'expired';

  @override
  List<Object?> get props => [status, planName, isTrial, endsOn, graceEndsOn];
}
