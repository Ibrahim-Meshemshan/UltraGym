import '../../../../core/core.dart';

/// موظف بقائمة الرواتب (`ClubPayloads::staffMember`): الراتب بعملته والسلف المفتوحة محسوبة من الخادم.
class PayrollStaff extends Equatable {
  const PayrollStaff({
    required this.id,
    required this.name,
    required this.type,
    this.jobTitle,
    this.branchId,
    this.branchName,
    required this.salaryCurrency,
    required this.salaryAmount,
    required this.openAdvancesUsd,
  });

  factory PayrollStaff.fromJson(Json json) => PayrollStaff(
    id: json.intv('id'),
    name: json.str('name'),
    type: json.str('type'),
    jobTitle: json.strOrNull('job_title'),
    branchId: json.obj('branch').intOrNull('id'),
    branchName: json.obj('branch').strOrNull('name'),
    salaryCurrency: json.str('salary_currency', 'USD'),
    salaryAmount: json.dbl('salary_amount'),
    openAdvancesUsd: json.dbl('open_advances_usd'),
  );

  final int id;
  final String name, type, salaryCurrency;
  final String? jobTitle, branchName;
  final int? branchId;
  final num salaryAmount, openAdvancesUsd;

  @override
  List<Object?> get props => [id, name, type, jobTitle, branchName, salaryCurrency, salaryAmount, openAdvancesUsd];
}

/// معاينة راتب شهر (`GET payroll/staff/{id}/preview`): الأساسي بالدولار، العمولة وعدد عملائها، السلف المفتوحة.
class SalaryPreview extends Equatable {
  const SalaryPreview({
    required this.staff,
    required this.period,
    required this.baseUsd,
    required this.commissionUsd,
    required this.commissionClients,
    required this.openAdvancesUsd,
    required this.suggestedNetUsd,
    required this.alreadyPaid,
    this.exchangeRate,
  });

  factory SalaryPreview.fromJson(Json json) => SalaryPreview(
    staff: PayrollStaff.fromJson(json.obj('staff_member')),
    period: json.str('period'),
    baseUsd: json.dbl('base_usd'),
    commissionUsd: json.dbl('commission_usd'),
    commissionClients: json.intv('commission_clients'),
    openAdvancesUsd: json.dbl('open_advances_usd'),
    suggestedNetUsd: json.dbl('suggested_net_usd'),
    alreadyPaid: json.flag('already_paid'),
    exchangeRate: json.dblOrNull('exchange_rate'),
  );

  final PayrollStaff staff;
  final String period;
  final num baseUsd, commissionUsd, openAdvancesUsd, suggestedNetUsd;
  final int commissionClients;
  final bool alreadyPaid;

  /// null = لا سعر صرف معتمد (الصرف بالليرة يُرفض).
  final num? exchangeRate;

  @override
  List<Object?> get props => [
    staff,
    period,
    baseUsd,
    commissionUsd,
    commissionClients,
    openAdvancesUsd,
    suggestedNetUsd,
    alreadyPaid,
    exchangeRate,
  ];
}

/// راتب مدفوع (`GET payroll/salaries`): الأسطر كما ثبّتها الخادم، وحركة الصرف للإيصال (null حين الصافي صفر).
class SalaryPayment extends Equatable {
  const SalaryPayment({
    required this.id,
    required this.staffId,
    required this.staffName,
    required this.period,
    required this.baseUsd,
    required this.commissionUsd,
    required this.bonusUsd,
    required this.deductionsUsd,
    required this.advanceDeductionUsd,
    required this.netUsd,
    required this.status,
    this.note,
    this.transactionId,
    this.createdAt,
  });

  factory SalaryPayment.fromJson(Json json) => SalaryPayment(
    id: json.intv('id'),
    staffId: json.obj('staff_member').intv('id'),
    staffName: json.obj('staff_member').str('name'),
    period: json.str('period'),
    baseUsd: json.dbl('base_usd'),
    commissionUsd: json.dbl('commission_usd'),
    bonusUsd: json.dbl('bonus_usd'),
    deductionsUsd: json.dbl('deductions_usd'),
    advanceDeductionUsd: json.dbl('advance_deduction_usd'),
    netUsd: json.dbl('net_usd'),
    status: json.str('status'),
    note: json.strOrNull('note'),
    transactionId: json.intOrNull('transaction_id'),
    createdAt: json.date('created_at'),
  );

  final int id, staffId;
  final String staffName, period, status;
  final num baseUsd, commissionUsd, bonusUsd, deductionsUsd, advanceDeductionUsd, netUsd;
  final String? note;
  final int? transactionId;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [id, staffId, period, netUsd, status, transactionId, createdAt];
}

/// قائمة الرواتب لشهر: الموظفون الفعّالون + رواتب الشهر المدفوعة لكل موظف.
class PayrollRoster extends Equatable {
  const PayrollRoster({required this.staff, required this.paid});

  final List<PayrollStaff> staff;
  final Map<int, SalaryPayment> paid;

  @override
  List<Object?> get props => [staff, paid];
}

/// سلفة (`GET payroll/advances`): المخصوم والمتبقي والحالة من الخادم.
class StaffAdvance extends Equatable {
  const StaffAdvance({
    required this.id,
    required this.staffId,
    required this.staffName,
    required this.amountUsd,
    required this.deductedUsd,
    required this.remainingUsd,
    required this.status,
    this.note,
    this.transactionId,
    this.createdAt,
  });

  factory StaffAdvance.fromJson(Json json) => StaffAdvance(
    id: json.intv('id'),
    staffId: json.obj('staff_member').intv('id'),
    staffName: json.obj('staff_member').str('name'),
    amountUsd: json.dbl('amount_usd'),
    deductedUsd: json.dbl('deducted_usd'),
    remainingUsd: json.dbl('remaining_usd'),
    status: json.str('status'),
    note: json.strOrNull('note'),
    transactionId: json.intOrNull('transaction_id'),
    createdAt: json.date('created_at'),
  );

  final int id, staffId;
  final String staffName, status;
  final num amountUsd, deductedUsd, remainingUsd;
  final String? note;
  final int? transactionId;
  final DateTime? createdAt;

  /// نسبة المخصوم لشريط العرض فقط.
  double get deductedShare => amountUsd <= 0 ? 0 : (deductedUsd / amountUsd).clamp(0, 1).toDouble();

  @override
  List<Object?> get props => [id, staffId, amountUsd, deductedUsd, remainingUsd, status, note, transactionId];
}

/// أرقام السلف (طلبات بصف واحد + `meta.summary.open_remaining_usd`).
class AdvanceStats extends Equatable {
  const AdvanceStats({required this.open, required this.openRemainingUsd, required this.settled});

  final int open, settled;
  final num openRemainingUsd;

  @override
  List<Object?> get props => [open, openRemainingUsd, settled];
}

/// نصوص الرواتب والسلف.
abstract final class PayrollTexts {
  static String type(String type) => switch (type) {
    'trainer' => 'مدرب',
    'worker' => 'عامل',
    _ => 'موظف',
  };

  /// "مدرب · الفرع الرئيسي" (المسمى الوظيفي إن وُجد بدل النوع).
  static String role(PayrollStaff s) => [s.jobTitle ?? type(s.type), ?s.branchName].join(' · ');

  /// `2026-11` ← "تشرين الثاني 2026".
  static String month(String period) {
    final p = periodDate(period);
    return p == null ? period : Formatters.monthYear(p);
  }

  static DateTime? periodDate(String period) => DateTime.tryParse('$period-01');

  /// `YYYY-MM` لشهر.
  static String periodOf(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';

  /// الشهر الحالي بتوقيت النادي ثم الخمسة السابقة.
  static List<String> recentPeriods(DateTime clubNow, {int count = 6}) => [
    for (var i = 0; i < count; i++) periodOf(DateTime(clubNow.year, clubNow.month - i)),
  ];

  static ({String label, UTone tone}) advanceStatus(String status) => switch (status) {
    'open' => (label: 'مفتوحة', tone: UTone.warning),
    'settled' => (label: 'مسددة', tone: UTone.success),
    'cancelled' => (label: 'ملغاة', tone: UTone.neutral),
    _ => (label: status, tone: UTone.neutral),
  };
}
