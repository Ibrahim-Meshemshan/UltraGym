import '../../../../core/core.dart';

/// اشتراك النادي بالمنصة (`BillingController::subscriptionPayload`): الحالي أو أحد السابقين.
class PlatformSubscription extends Equatable {
  const PlatformSubscription({
    required this.id,
    required this.status,
    this.planName,
    this.isTrial = false,
    this.isCurrent = false,
    this.cycle,
    this.startsOn,
    this.endsOn,
    this.graceEndsOn,
  });

  factory PlatformSubscription.fromJson(Json j) => PlatformSubscription(
    id: j.intv('id'),
    status: j.str('status'),
    planName: j.obj('plan').strOrNull('name'),
    isTrial: j.flag('is_trial'),
    isCurrent: j.flag('is_current'),
    cycle: j.strOrNull('billing_cycle'),
    startsOn: j.day('starts_at'),
    endsOn: j.day('ends_at'),
    graceEndsOn: j.day('grace_ends_at'),
  );

  final int id;

  /// `trial · active · grace · expired · locked · suspended · cancelled` (`Labels.tenantSubscription`).
  final String status;
  final String? planName, cycle;
  final bool isTrial, isCurrent;

  /// أيام (`*_at` هنا تواريخ `YYYY-MM-DD` بلا وقت): تُعرض كما هي.
  final DateTime? startsOn, endsOn, graceEndsOn;

  @override
  List<Object?> get props => [id, status, planName, isTrial, isCurrent, cycle, startsOn, endsOn, graceEndsOn];
}

/// `GET billing/subscription`: الحالي (null = لا اشتراك مسجّل)، السجل (حتى 20)، والمستحق للمنصة.
class BillingOverview extends Equatable {
  const BillingOverview({this.current, this.history = const [], this.outstanding = 0, this.overdueInvoices = 0});

  factory BillingOverview.fromJson(Json j) {
    final balance = j.obj('balance');
    return BillingOverview(
      current: switch (j.objOrNull('current')) {
        final c? => PlatformSubscription.fromJson(c),
        null => null,
      },
      history: asList(j['history'], PlatformSubscription.fromJson),
      outstanding: balance.dbl('outstanding'),
      overdueInvoices: balance.intv('overdue_invoices'),
    );
  }

  final PlatformSubscription? current;
  final List<PlatformSubscription> history;

  /// بالدولار: مجموع المتبقي من الفواتير غير المسددة، وعدد المتأخرة منها.
  final double outstanding;
  final int overdueInvoices;

  @override
  List<Object?> get props => [current, history, outstanding, overdueInvoices];
}

/// استعمال حد واحد من حدود الباقة (`GET club.usage.<key>`؛ `limit` null = بلا حد).
class UsageLine extends Equatable {
  const UsageLine({required this.used, this.limit});

  factory UsageLine.fromJson(Json j) => UsageLine(used: j.intv('used'), limit: j.intOrNull('limit'));

  final int used;
  final int? limit;

  /// نسبة الشريط فقط (لا حالة تُحسب منها): null بلا حد.
  double? get ratio => limit == null || limit! <= 0 ? null : (used / limit!).clamp(0, 1).toDouble();
  bool get reached => limit != null && used >= limit!;

  @override
  List<Object?> get props => [used, limit];
}

/// الاستعمال مقابل الحدود (`GET club`): الأعضاء والموظفون (المالك والاستقبال) والفروع، وأيام الاشتراك المتبقية.
class PlanUsage extends Equatable {
  const PlanUsage({required this.players, required this.staff, required this.branches, this.daysRemaining});

  factory PlanUsage.fromJson(Json j) {
    final u = j.obj('usage');
    return PlanUsage(
      players: UsageLine.fromJson(u.obj('players')),
      staff: UsageLine.fromJson(u.obj('staff')),
      branches: UsageLine.fromJson(u.obj('branches')),
      daysRemaining: j.objOrNull('subscription')?.intOrNull('days_remaining'),
    );
  }

  final UsageLine players, staff, branches;
  final int? daysRemaining;

  @override
  List<Object?> get props => [players, staff, branches, daysRemaining];
}

/// دفعة مسجّلة على فاتورة (يسجلها فريق المنصة).
class InvoicePayment extends Equatable {
  const InvoicePayment({required this.id, required this.amount, this.method, this.reference, this.paidOn});

  factory InvoicePayment.fromJson(Json j) => InvoicePayment(
    id: j.intv('id'),
    amount: j.dbl('amount'),
    method: j.strOrNull('method'),
    reference: j.strOrNull('reference_number'),
    paidOn: j.day('paid_at'),
  );

  final int id;
  final double amount;
  final String? method, reference;
  final DateTime? paidOn;

  @override
  List<Object?> get props => [id, amount, method, reference, paidOn];
}

/// فاتورة المنصة للنادي (`BillingController::invoicePayload`)؛ التفاصيل تضيف `payments`.
class PlatformInvoice extends Equatable {
  const PlatformInvoice({
    required this.id,
    required this.number,
    required this.status,
    this.planName,
    this.cycle,
    this.periodStart,
    this.periodEnd,
    this.subtotal = 0,
    this.discount = 0,
    this.total = 0,
    this.paid = 0,
    this.remaining = 0,
    this.isOverdue = false,
    this.issuedOn,
    this.dueOn,
    this.paidAt,
    this.cancellationReason,
    this.payments = const [],
  });

  factory PlatformInvoice.fromJson(Json j) => PlatformInvoice(
    id: j.intv('id'),
    number: j.str('number'),
    status: j.str('status'),
    planName: j.strOrNull('plan_name'),
    cycle: j.strOrNull('billing_cycle'),
    periodStart: j.day('period_start'),
    periodEnd: j.day('period_end'),
    subtotal: j.dbl('subtotal'),
    discount: j.dbl('discount'),
    total: j.dbl('total'),
    paid: j.dbl('paid_amount'),
    remaining: j.dbl('remaining_amount'),
    isOverdue: j.flag('is_overdue'),
    issuedOn: j.day('issued_at'),
    dueOn: j.day('due_date'),
    paidAt: j.date('paid_at'),
    cancellationReason: j.strOrNull('cancellation_reason'),
    payments: asList(j['payments'], InvoicePayment.fromJson),
  );

  final int id;
  final String number;

  /// `pending · partially_paid · paid · cancelled · refunded`، و `is_overdue` من الخادم.
  final String status;
  final String? planName, cycle, cancellationReason;
  final DateTime? periodStart, periodEnd, issuedOn, dueOn;

  /// UTC (وقت السداد الكامل).
  final DateTime? paidAt;
  final double subtotal, discount, total, paid, remaining;
  final bool isOverdue;
  final List<InvoicePayment> payments;

  LabelSpec get label => Labels.invoice(status, overdue: isOverdue);

  @override
  List<Object?> get props => [id, number, status, total, paid, remaining, isOverdue, dueOn, payments];
}
