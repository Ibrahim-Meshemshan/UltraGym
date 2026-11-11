import '../../../../core/core.dart';
import '../../../club_plan/domain/models/club_plan_models.dart';
import 'billing_models.dart';

/// نصوص اشتراك النادي: قيم الخادم الثابتة (`PlatformDocuments::EXPORT_VALUES`) وأسماء ميزات الباقة.
abstract final class BillingTexts {
  static String cycle(String? v) => switch (v) {
    'monthly' => 'شهري',
    'quarterly' => 'ربع سنوي',
    'semiannual' => 'نصف سنوي',
    'yearly' => 'سنوي',
    'custom' => 'مخصص',
    null => '—',
    _ => v,
  };

  static String method(String? v) => switch (v) {
    'cash' => 'نقداً',
    'bank_transfer' => 'حوالة بنكية',
    'other' => 'أخرى',
    null => '—',
    _ => v,
  };

  /// ترتيب العرض = ترتيب `PlanFeature`.
  static const features = {
    PlanFeature.playerApp: 'تطبيق العضو',
    PlanFeature.qrAttendance: 'دخول QR',
    PlanFeature.offlineReception: 'استقبال دون اتصال',
    PlanFeature.advancedFinance: 'المالية المتقدمة',
    PlanFeature.advancedReports: 'تقارير متقدمة',
    PlanFeature.reportsExport: 'تصدير التقارير',
    PlanFeature.customBranding: 'هوية مخصصة',
    PlanFeature.prioritySupport: 'دعم بأولوية',
  };

  /// أسماء الميزات المشمولة (ميزة جديدة لا نعرف اسمها تظهر بمفتاحها).
  static List<String> included(Map<String, bool> map) => [
    for (final e in map.entries)
      if (e.value) features[e.key] ?? e.key,
  ];

  static String title(PlatformSubscription s) =>
      [?s.planName, if (s.cycle != null) cycle(s.cycle)].join(' · ').ifEmpty('باقة النادي');

  /// سطر تحت العنوان: السماح حتى، أو الأيام المتبقية (من `GET club.subscription.days_remaining`).
  static String? note(PlatformSubscription s, int? daysRemaining) {
    if (s.status == 'grace' && s.graceEndsOn != null) {
      return 'السماح حتى ${Formatters.ltr(Formatters.date(s.graceEndsOn))}';
    }
    if (s.status == 'expired') return 'اللوحة للقراءة فقط حتى التجديد';
    return switch (daysRemaining) {
      null => null,
      0 => 'ينتهي اليوم',
      final d => 'ينتهي بعد ${Formatters.days(d)}',
    };
  }

  static String period(DateTime? from, DateTime? to) =>
      '${Formatters.ltr(Formatters.date(from))} ← ${Formatters.ltr(Formatters.date(to))}';

  /// "540 / 800" أو "14 / ∞".
  static String usage(UsageLine u) => '${u.used} / ${u.limit ?? '∞'}';

  /// حد التخزين بالباقة (لا استعمال له بالخادم).
  static String? storage(int? mb) => switch (mb) {
    null => null,
    >= 1024 => '${(mb / 1024).toStringAsFixed(mb % 1024 == 0 ? 0 : 1)} GB',
    _ => '$mb MB',
  };
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
