import '../../../../core/core.dart';

/// سطر بسجل الحضور `GET club-admin/attendance?player_id=`.
class AttendanceEntry extends Equatable {
  const AttendanceEntry({
    required this.id,
    required this.status,
    this.checkedInAt,
    this.branchName,
    this.method,
    this.inGrace = false,
    this.rejectionMessage,
    this.rejectionReason,
  });

  factory AttendanceEntry.fromJson(Json j) => AttendanceEntry(
    id: j.intv('id'),
    status: j.str('status'),
    checkedInAt: j.date('checked_in_at'),
    branchName: j.objOrNull('branch')?.strOrNull('name'),
    method: j.strOrNull('method'),
    inGrace: j.flag('in_grace'),
    rejectionMessage: j.strOrNull('rejection_message'),
    rejectionReason: j.strOrNull('rejection_reason'),
  );

  final int id;
  final String status;
  final DateTime? checkedInAt;
  final String? branchName, method, rejectionMessage;

  /// رمز سبب الرفض (`EXPIRED`، `FROZEN`…).
  final String? rejectionReason;
  final bool inGrace;

  /// طريقة الدخول بالعربية.
  String get methodLabel => switch (method) {
    'qr' => 'QR',
    'manual' => 'يدوي',
    'code' => 'بالمعرّف',
    'day_pass' => 'دخول يومي',
    _ => '—',
  };

  @override
  List<Object?> get props => [id, status, checkedInAt, branchName, method, inGrace, rejectionMessage, rejectionReason];
}

/// حركة مالية للعضو `GET club-admin/transactions?player_id=` (الدفعات والاسترجاع).
class PaymentEntry extends Equatable {
  const PaymentEntry({
    required this.id,
    required this.typeLabel,
    required this.currency,
    required this.amount,
    this.direction = 'in',
    this.receiptNumber,
    this.businessDate,
    this.isReversed = false,
    this.amountUsd,
    this.occurredAt,
    this.createdBy,
  });

  factory PaymentEntry.fromJson(Json j) => PaymentEntry(
    id: j.intv('id'),
    typeLabel: j.str('type_label', '—'),
    currency: j.str('currency', 'USD'),
    amount: j.dbl('amount'),
    direction: j.str('direction', 'in'),
    receiptNumber: j.strOrNull('receipt_number'),
    businessDate: j.day('business_date'),
    isReversed: j.flag('is_reversed'),
    amountUsd: j.dblOrNull('amount_usd'),
    occurredAt: j.date('occurred_at'),
    createdBy: j.objOrNull('created_by')?.strOrNull('name'),
  );

  final int id;
  final String typeLabel, currency, direction;
  final double amount;
  final String? receiptNumber;
  final DateTime? businessDate;
  final bool isReversed;

  /// المبلغ بالدولار بسعر يوم الدفع (من الخادم)، ووقت الحركة (UTC)، ومن سجّلها.
  final double? amountUsd;
  final DateTime? occurredAt;
  final String? createdBy;

  bool get isOut => direction == 'out';

  @override
  List<Object?> get props => [
    id,
    typeLabel,
    currency,
    amount,
    direction,
    receiptNumber,
    businessDate,
    isReversed,
    amountUsd,
    occurredAt,
    createdBy,
  ];
}

/// تبويبات سجل العضو.
enum MemberHistoryTab { memberships, attendance, payments }
