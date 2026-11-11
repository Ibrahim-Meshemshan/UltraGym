import 'package:flutter/material.dart';

import '../../../../core/core.dart';

/// حركة بدفتر النادي (`GET club-admin/transactions`): قبض الاشتراكات، الاسترجاع، الدخول اليومي، الإيرادات والمصاريف،
/// الرواتب والسلف، والعكس. لا حذف ولا تعديل: الخطأ يُصحَّح بحركة عكس (للمالك).
class LedgerEntry extends Equatable {
  const LedgerEntry({
    required this.id,
    required this.receiptNumber,
    required this.type,
    required this.typeLabel,
    required this.direction,
    required this.currency,
    required this.amount,
    required this.amountUsd,
    this.exchangeRate,
    this.branchId,
    this.branchName,
    this.cashSessionId,
    this.categoryName,
    this.membershipId,
    this.dayPassId,
    this.playerId,
    this.playerName,
    this.staffName,
    this.description,
    this.isReversed = false,
    this.reversedAt,
    this.reversalOfId,
    this.businessDate,
    this.occurredAt,
    this.createdBy,
    this.reversedByReceipt,
    this.amountSypEquivalent,
  });

  factory LedgerEntry.fromJson(Json j) {
    final branch = j.objOrNull('branch');
    final player = j.objOrNull('player');
    return LedgerEntry(
      id: j.intv('id'),
      receiptNumber: j.str('receipt_number', '—'),
      type: j.str('type'),
      typeLabel: j.str('type_label', '—'),
      direction: j.str('direction', 'in'),
      currency: j.str('currency', 'USD'),
      amount: j.dbl('amount'),
      amountUsd: j.dbl('amount_usd'),
      exchangeRate: j.dblOrNull('exchange_rate'),
      branchId: branch?.intOrNull('id'),
      branchName: branch?.strOrNull('name'),
      cashSessionId: j.intOrNull('cash_session_id'),
      categoryName: j.objOrNull('category')?.strOrNull('name'),
      membershipId: j.intOrNull('membership_id'),
      dayPassId: j.intOrNull('day_pass_id'),
      playerId: player?.intOrNull('id'),
      playerName: player?.strOrNull('name'),
      staffName: j.objOrNull('staff_member')?.strOrNull('name'),
      description: j.strOrNull('description'),
      isReversed: j.flag('is_reversed'),
      reversedAt: j.date('reversed_at'),
      reversalOfId: j.intOrNull('reversal_of_id'),
      businessDate: j.day('business_date'),
      occurredAt: j.date('occurred_at'),
      createdBy: j.objOrNull('created_by')?.strOrNull('name'),
      reversedByReceipt: j.objOrNull('reversed_by_transaction')?.strOrNull('receipt_number'),
      amountSypEquivalent: j.dblOrNull('amount_syp_equivalent'),
    );
  }

  final int id;
  final String receiptNumber, type, typeLabel, direction, currency;
  final double amount, amountUsd;
  final double? exchangeRate;
  final int? branchId, cashSessionId, membershipId, dayPassId, playerId, reversalOfId;
  final String? branchName, categoryName, playerName, staffName, description, createdBy;
  final bool isReversed;
  final DateTime? reversedAt, businessDate, occurredAt;

  /// التفاصيل فقط (`GET transactions/{id}`): إيصال حركة العكس، وما يعادل مبلغ الدولار بالليرة.
  final String? reversedByReceipt;
  final double? amountSypEquivalent;

  bool get isIn => direction == 'in';
  bool get isReversal => type == TransactionTypes.reversal;

  /// الخادم يرفض عكس حركة عكسية أو معكوسة (`CONFLICT` / `ALREADY_REVERSED`)، فالزر يختفي لهما.
  bool get canReverse => !isReversed && !isReversal;

  @override
  List<Object?> get props => [
    id,
    receiptNumber,
    type,
    typeLabel,
    direction,
    currency,
    amount,
    amountUsd,
    exchangeRate,
    branchId,
    branchName,
    cashSessionId,
    categoryName,
    membershipId,
    dayPassId,
    playerId,
    playerName,
    staffName,
    description,
    isReversed,
    reversedAt,
    reversalOfId,
    businessDate,
    occurredAt,
    createdBy,
    reversedByReceipt,
    amountSypEquivalent,
  ];
}

/// مجاميع الدفتر للفلتر الحالي بالدولار المكافئ (`meta.totals`).
class LedgerTotals extends Equatable {
  const LedgerTotals({this.inUsd = 0, this.outUsd = 0, this.netUsd = 0});

  factory LedgerTotals.fromJson(Json j) =>
      LedgerTotals(inUsd: j.dbl('in_usd'), outUsd: j.dbl('out_usd'), netUsd: j.dbl('net_usd'));

  final double inUsd, outUsd, netUsd;

  @override
  List<Object?> get props => [inUsd, outUsd, netUsd];
}

/// رد العكس: الأصلية (معكوسة الآن) وحركة العكس بإيصالها الجديد.
class LedgerReversal extends Equatable {
  const LedgerReversal({required this.original, required this.reversal});

  factory LedgerReversal.fromJson(Json j) => LedgerReversal(
    original: LedgerEntry.fromJson(j.obj('original')),
    reversal: LedgerEntry.fromJson(j.obj('reversal')),
  );

  final LedgerEntry original, reversal;

  @override
  List<Object?> get props => [original, reversal];
}

/// تصنيف مالي (`GET club-admin/finance/categories`): للمصروف أو للإيراد.
class FinanceCategory extends Equatable {
  const FinanceCategory({
    required this.id,
    required this.kind,
    required this.name,
    this.active = true,
    this.transactionsCount,
  });

  factory FinanceCategory.fromJson(Json j) => FinanceCategory(
    id: j.intv('id'),
    kind: j.str('kind'),
    name: j.str('name', '—'),
    active: j.str('status', 'active') == 'active',
    transactionsCount: j.intOrNull('transactions_count'),
  );

  final int id;
  final String kind, name;
  final bool active;

  /// عدد حركاته (القائمة فقط؛ لا يرجع مع الإضافة والتعديل). المستخدم لا يُحذف بل يُوقف.
  final int? transactionsCount;

  bool get isIncome => kind == 'income';

  @override
  List<Object?> get props => [id, kind, name, active, transactionsCount];
}

/// أنواع الحركات كما بالخادم (`Ledger::TYPE_LABELS`).
abstract final class TransactionTypes {
  static const membershipPayment = 'membership_payment',
      membershipRefund = 'membership_refund',
      dayPass = 'day_pass',
      income = 'income',
      expense = 'expense',
      salary = 'salary',
      advance = 'advance',
      reversal = 'reversal';
}

/// مفاتيح فلاتر الدفتر وخياراتها.
abstract final class TransactionFilters {
  static const type = 'type',
      currency = 'currency',
      from = 'from',
      to = 'to',
      branchId = 'branch_id',
      includeReversed = 'include_reversed';

  /// الرواتب والسلف للمالك فقط (الخادم يخفيها عن الاستقبال أصلاً).
  static List<FormOption<String>> types({required bool finance}) => [
    (value: TransactionTypes.membershipPayment, label: 'دفعة اشتراك'),
    (value: TransactionTypes.membershipRefund, label: 'استرجاع اشتراك'),
    (value: TransactionTypes.dayPass, label: 'دخول يومي'),
    (value: TransactionTypes.income, label: 'إيراد'),
    (value: TransactionTypes.expense, label: 'مصروف'),
    if (finance) ...[(value: TransactionTypes.salary, label: 'راتب'), (value: TransactionTypes.advance, label: 'سلفة')],
    (value: TransactionTypes.reversal, label: 'عكس حركة'),
  ];

  static const currencies = <FormOption<String>>[(value: 'USD', label: 'دولار'), (value: 'SYP', label: 'ليرة')];

  static final allTypes = {for (final o in types(finance: true)) o.value};
}

/// نغمة شارة النوع (`Transactions.html`): الاشتراك أخضر، الإيراد فولت، المصروف أحمر، الاسترجاع عنبري،
/// الراتب والسلفة أزرق، والعكس محايد.
abstract final class TransactionLabels {
  static UTone tone(String type) => switch (type) {
    TransactionTypes.membershipPayment || TransactionTypes.dayPass => UTone.success,
    TransactionTypes.income => UTone.accent,
    TransactionTypes.expense => UTone.danger,
    TransactionTypes.membershipRefund => UTone.warning,
    TransactionTypes.salary || TransactionTypes.advance => UTone.info,
    _ => UTone.neutral,
  };

  static IconData icon(bool isIn) => isIn ? Icons.south_west_rounded : Icons.north_east_rounded;
}
