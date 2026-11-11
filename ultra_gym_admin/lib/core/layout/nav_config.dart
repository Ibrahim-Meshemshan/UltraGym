import 'package:flutter/material.dart';

import '../../features/auth/domain/models/auth_models.dart';
import '../../features/club_plan/domain/models/club_plan_models.dart';
import '../router/routes.dart';

/// عنصر بالقائمة الجانبية: المسار والاسم والأيقونة، ومن يراه حسب الجلسة.
class NavEntry {
  const NavEntry(this.route, this.label, this.icon, {this.allowed = _anyone, this.receptionLabel, this.feature});

  final String route, label;
  final IconData icon;

  /// هل تسمح الجلسة بالقسم؟ (الخادم يرفض على أي حال بـ 403؛ هذا للإخفاء والحماية من فتح الرابط يدوياً)
  final bool Function(Session session) allowed;

  /// اسم مختلف حين يراه الاستقبال بصلاحية أضيق (مثلاً "الخطط" دون الكوبونات).
  final String? receptionLabel;

  /// ميزة الباقة التي يحتاجها القسم (`PlanFeature`)؛ غير مشمولة ← يُخفى من القائمة، ورابطه يعرض "ليست ضمن باقتك".
  final String? feature;

  String labelFor(Session s) => !s.isClubOwner && receptionLabel != null ? receptionLabel! : label;

  /// المسار نفسه أو صفحة فرعية منه (`/members/12`).
  bool matches(String path) => path == route || path.startsWith('$route/');

  static bool _anyone(Session _) => true;
}

/// مجموعة بعنوان صغير (التشغيل، المالية...). بلا عنوان = أعلى القائمة.
class NavGroup {
  const NavGroup(this.title, this.entries);

  final String? title;
  final List<NavEntry> entries;
}

/// قائمة لوحة النادي حسب جدول الأدوار بـ CLAUDE.md وصفحة `Dashboard.html`.
/// وميزات الباقة (`GET /tenant/entitlements`) عبر `NavEntry.feature`.
abstract final class AdminNav {
  static bool _owner(Session s) => s.isClubOwner;
  static bool _staff(Session s) => s.isClubOwner && s.canManageStaff;

  static const dashboard = NavEntry(Routes.dashboard, 'الرئيسية', Icons.space_dashboard_rounded);

  static const groups = <NavGroup>[
    NavGroup(null, [dashboard]),
    NavGroup('التشغيل', [
      NavEntry(Routes.members, 'الأعضاء', Icons.groups_rounded),
      NavEntry(Routes.memberships, 'الاشتراكات والديون', Icons.credit_card_rounded),
      NavEntry(Routes.attendance, 'الحضور', Icons.login_rounded),
      NavEntry(Routes.dayPasses, 'الدخول اليومي', Icons.confirmation_number_rounded),
    ]),
    NavGroup('المالية', [
      NavEntry(Routes.cashSessions, 'الصندوق والحركات', Icons.point_of_sale_rounded),
      NavEntry(
        Routes.payroll,
        'الرواتب والسلف',
        Icons.receipt_long_rounded,
        allowed: _staff,
        feature: PlanFeature.advancedFinance,
      ),
      NavEntry(Routes.reports, 'التقارير', Icons.bar_chart_rounded),
    ]),
    NavGroup('النادي', [
      NavEntry(Routes.plans, 'الخطط والكوبونات', Icons.sell_rounded, receptionLabel: 'الخطط'),
      NavEntry(Routes.training, 'المدربون والتدريب', Icons.fitness_center_rounded),
      NavEntry(Routes.announcements, 'الإعلانات', Icons.campaign_rounded, allowed: _owner),
    ]),
    NavGroup('الإدارة', [
      NavEntry(Routes.settings, 'الإعدادات والفروع', Icons.settings_rounded, allowed: _owner),
      NavEntry(Routes.staff, 'الموظفون والحسابات', Icons.badge_rounded, allowed: _staff),
      NavEntry(
        Routes.receptionDevices,
        'أجهزة الاستقبال',
        Icons.tablet_android_rounded,
        allowed: _owner,
        feature: PlanFeature.offlineReception,
      ),
      NavEntry(Routes.billing, 'اشتراك النادي والدعم', Icons.verified_user_rounded, allowed: _owner),
    ]),
  ];

  /// كل الأقسام (لتسجيل مساراتها بالراوتر).
  static final List<NavEntry> all = [for (final g in groups) ...g.entries];

  /// المجموعات التي تراها الجلسة وتشملها الباقة (`has`، افتراضياً كل الميزات)، دون المجموعات الفارغة.
  static List<NavGroup> visibleFor(Session s, {bool Function(String? feature) has = _anyFeature}) {
    bool shows(NavEntry e) => e.allowed(s) && has(e.feature);
    return [
      for (final g in groups)
        if (g.entries.any(shows)) NavGroup(g.title, [...g.entries.where(shows)]),
    ];
  }

  static bool _anyFeature(String? _) => true;

  /// القسم الذي يتبعه المسار الحالي (null خارج الهيكل).
  static NavEntry? entryFor(String path) {
    for (final e in all) {
      if (e.matches(path)) return e;
    }
    return null;
  }
}
