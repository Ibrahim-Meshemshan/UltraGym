import '../../../../core/core.dart';
import 'staff_models.dart';

/// نصوص الموظفين والحسابات وألوان حالاتها بمكان واحد.
abstract final class StaffTexts {
  static const types = <FormOption<String>>[
    (value: 'trainer', label: 'مدرب'),
    (value: 'worker', label: 'عامل'),
    (value: 'other', label: 'آخر'),
  ];

  static const staffStatuses = <FormOption<String>>[
    (value: 'active', label: 'فعّال'),
    (value: 'inactive', label: 'متوقف'),
  ];

  static const receptionStatuses = <FormOption<String>>[
    (value: 'active', label: 'فعّال'),
    (value: 'suspended', label: 'موقوف'),
  ];

  static const roles = <FormOption<String>>[
    (value: 'club_owner', label: 'مالك النادي'),
    (value: 'receptionist', label: 'موظف استقبال'),
    (value: 'player', label: 'لاعب'),
  ];

  /// حالات الحسابات بترتيب `meta.summary`.
  static const states = <FormOption<String>>[
    (value: 'never_logged_in', label: 'لم يدخل بعد'),
    (value: 'pending_change', label: 'بانتظار تغيير الكلمة'),
    (value: 'expired', label: 'كلمة مؤقتة منتهية'),
    (value: 'active', label: 'فعّال'),
    (value: 'suspended', label: 'موقوف'),
  ];

  /// ما تقبله إعادة كلمات السر الجماعية (`state`).
  static const bulkStates = <FormOption<String>>[
    (value: 'never_logged_in', label: 'من لم يدخل بعد'),
    (value: 'expired', label: 'كلمته المؤقتة منتهية'),
  ];

  static String type(String t) => _label(types, t);

  static UTone typeTone(String t) => t == 'trainer' ? UTone.info : UTone.neutral;

  static UTone stateTone(String s) => switch (s) {
    'active' => UTone.success,
    'never_logged_in' => UTone.info,
    'pending_change' => UTone.warning,
    _ => UTone.danger,
  };

  /// شارة حساب الاستقبال: المؤرشف ثم الموقوف ثم من ينتظر تغيير كلمته.
  static ({String label, UTone tone}) reception(Receptionist r) => r.isArchived
      ? (label: 'مؤرشف', tone: UTone.neutral)
      : r.isSuspended
      ? (label: 'موقوف', tone: UTone.danger)
      : r.mustChangePassword
      ? (label: 'بانتظار تغيير كلمة السر', tone: UTone.warning)
      : (label: 'فعّال', tone: UTone.success);

  static ({String label, UTone tone}) staffStatus(StaffMember s) => s.archived
      ? (label: 'مؤرشف', tone: UTone.neutral)
      : s.isActive
      ? (label: 'فعّال', tone: UTone.success)
      : (label: 'متوقف', tone: UTone.neutral);

  static String salary(StaffMember s) =>
      s.salaryAmount <= 0 ? '—' : Formatters.money(s.salaryAmount, s.salaryCurrency);

  /// العمولة للمدرب فقط: `20%` أو `$5.00 لكل عميل` (المبلغ معزول LTR داخل الجملة العربية).
  static String commission(StaffMember s) {
    if (!s.isTrainer) return '—';
    if (s.commissionType == 'fixed') {
      return s.commissionFixedUsd <= 0 ? '—' : '${Formatters.ltr(Formatters.usd(s.commissionFixedUsd))} لكل عميل';
    }
    return s.commissionPercent <= 0 ? '—' : Formatters.ltr('${Formatters.number(s.commissionPercent)}%');
  }

  static String branches(List<BranchRef> b) => b.isEmpty ? '—' : b.map((x) => x.name).join('، ');

  static String lastLogin(DateTime? at) =>
      at == null ? 'لم يدخل بعد' : Formatters.relative(at, now: sl<ServerClock>().now());

  static String _label(List<FormOption<String>> options, String v) =>
      options.where((o) => o.value == v).firstOrNull?.label ?? v;
}
