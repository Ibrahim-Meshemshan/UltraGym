import '../../../../core/core.dart';

/// أرصدة الوردية الحية (للمفتوحة): الداخل والخارج والمتوقع بالدرج لكل عملة، من الخادم.
class CashTotals extends Equatable {
  const CashTotals({
    this.inUsd = 0,
    this.outUsd = 0,
    this.inSyp = 0,
    this.outSyp = 0,
    this.expectedUsd = 0,
    this.expectedSyp = 0,
  });

  factory CashTotals.fromJson(Json j) => CashTotals(
    inUsd: j.dbl('in_usd'),
    outUsd: j.dbl('out_usd'),
    inSyp: j.dbl('in_syp'),
    outSyp: j.dbl('out_syp'),
    expectedUsd: j.dbl('expected_usd'),
    expectedSyp: j.dbl('expected_syp'),
  );

  final double inUsd, outUsd, inSyp, outSyp, expectedUsd, expectedSyp;

  @override
  List<Object?> get props => [inUsd, outUsd, inSyp, outSyp, expectedUsd, expectedSyp];
}

/// سطر "حسب النوع" بتفاصيل الوردية: نوع الحركة واتجاهها بعملة واحدة، عددها ومجموعها.
class CashBreakdownLine extends Equatable {
  const CashBreakdownLine({
    required this.type,
    required this.label,
    this.direction = 'in',
    this.currency = 'USD',
    this.count = 0,
    this.total = 0,
  });

  factory CashBreakdownLine.fromJson(Json j) => CashBreakdownLine(
    type: j.str('type'),
    label: j.str('type_label', j.str('type')),
    direction: j.str('direction', 'in'),
    currency: j.str('currency', 'USD'),
    count: j.intv('count'),
    total: j.dbl('total'),
  );

  final String type, label, direction, currency;
  final int count;
  final double total;

  bool get isIn => direction == 'in';

  @override
  List<Object?> get props => [type, label, direction, currency, count, total];
}

/// وردية صندوق بفرع (`cash_session`): الافتتاحي، الأرصدة الحية وهي مفتوحة، ثم الجرد والفرق بعد الإغلاق.
class CashSession extends Equatable {
  const CashSession({
    required this.id,
    this.branchId,
    this.branchName,
    this.businessDate,
    this.status = 'open',
    this.openingUsd = 0,
    this.openingSyp = 0,
    this.expectedUsd,
    this.expectedSyp,
    this.closingUsd,
    this.closingSyp,
    this.differenceUsd,
    this.differenceSyp,
    this.openedBy,
    this.closedBy,
    this.openedAt,
    this.closedAt,
    this.notes,
    this.totals,
    this.breakdown = const [],
  });

  factory CashSession.fromJson(Json j) => CashSession(
    id: j.intv('id'),
    branchId: j.objOrNull('branch')?.intOrNull('id'),
    branchName: j.objOrNull('branch')?.strOrNull('name'),
    businessDate: j.day('business_date'),
    status: j.str('status', 'open'),
    openingUsd: j.dbl('opening_usd'),
    openingSyp: j.dbl('opening_syp'),
    expectedUsd: j.dblOrNull('expected_usd'),
    expectedSyp: j.dblOrNull('expected_syp'),
    closingUsd: j.dblOrNull('closing_usd'),
    closingSyp: j.dblOrNull('closing_syp'),
    differenceUsd: j.dblOrNull('difference_usd'),
    differenceSyp: j.dblOrNull('difference_syp'),
    openedBy: j.objOrNull('opened_by')?.strOrNull('name'),
    closedBy: j.objOrNull('closed_by')?.strOrNull('name'),
    openedAt: j.date('opened_at'),
    closedAt: j.date('closed_at'),
    notes: j.strOrNull('notes'),
    totals: j.objOrNull('totals') == null ? null : CashTotals.fromJson(j.obj('totals')),
    breakdown: asList(j['breakdown'], CashBreakdownLine.fromJson),
  );

  final int id;
  final int? branchId;
  final String? branchName;
  final DateTime? businessDate;

  /// `open` أو `closed`.
  final String status;
  final double openingUsd, openingSyp;

  /// المتوقع والجرد والفرق (الجرد − المتوقع؛ سالب = عجز) تُثبَّت عند الإغلاق.
  final double? expectedUsd, expectedSyp, closingUsd, closingSyp, differenceUsd, differenceSyp;
  final String? openedBy, closedBy;
  final DateTime? openedAt, closedAt;
  final String? notes;

  /// الأرصدة الحية (المفتوحة فقط، أو التفاصيل).
  final CashTotals? totals;

  /// "حسب النوع" (التفاصيل فقط).
  final List<CashBreakdownLine> breakdown;

  bool get isOpen => status == 'open';

  /// المتوقع بالدرج: الحي للمفتوحة، والمثبّت عند الإغلاق للمغلقة.
  double? get expectedUsdNow => totals?.expectedUsd ?? expectedUsd;
  double? get expectedSypNow => totals?.expectedSyp ?? expectedSyp;

  /// عدد الحركات كما بأسطر "حسب النوع" (للعرض فقط).
  int get transactionsCount => breakdown.fold(0, (s, l) => s + l.count);

  @override
  List<Object?> get props => [
    id,
    branchId,
    branchName,
    businessDate,
    status,
    openingUsd,
    openingSyp,
    expectedUsd,
    expectedSyp,
    closingUsd,
    closingSyp,
    differenceUsd,
    differenceSyp,
    openedBy,
    closedBy,
    openedAt,
    closedAt,
    notes,
    totals,
    breakdown,
  ];
}

/// صندوق فرع الآن (`GET cash-sessions/current`): الوردية المفتوحة أو لا شيء، والرصيد الافتتاحي المقترح
/// (جرد آخر وردية مغلقة).
class CashBox extends Equatable {
  const CashBox({required this.branchId, this.branchName, this.session, this.suggestedUsd = 0, this.suggestedSyp = 0});

  factory CashBox.fromJson(Json j) => CashBox(
    branchId: j.obj('branch').intv('id'),
    branchName: j.obj('branch').strOrNull('name'),
    session: j.objOrNull('session') == null ? null : CashSession.fromJson(j.obj('session')),
    suggestedUsd: j.obj('suggested_opening').dbl('usd'),
    suggestedSyp: j.obj('suggested_opening').dbl('syp'),
  );

  final int branchId;
  final String? branchName;
  final CashSession? session;
  final double suggestedUsd, suggestedSyp;

  bool get isOpen => session != null;

  CashBox withSession(CashSession s) => CashBox(
    branchId: branchId,
    branchName: branchName,
    session: s,
    suggestedUsd: suggestedUsd,
    suggestedSyp: suggestedSyp,
  );

  @override
  List<Object?> get props => [branchId, branchName, session, suggestedUsd, suggestedSyp];
}

/// مفاتيح فلاتر "الورديات السابقة" (كما بالخادم).
abstract final class CashSessionFilters {
  static const status = 'status', from = 'from', to = 'to', branchId = 'branch_id', withDifference = 'with_difference';
}

abstract final class CashSessionLabels {
  /// "مفتوحة" / "مغلقة" (الوردية مؤنثة)، والنغمة من `Labels.cashSession`.
  static LabelSpec status(String status) {
    final l = Labels.cashSession(status);
    return (text: status == 'open' ? 'مفتوحة' : 'مغلقة', tone: l.tone, icon: l.icon);
  }

  /// فرق الجرد بكلمة: "مطابق" / "عجز" / "زيادة".
  static String difference(num? v) => v == null || v == 0 ? 'مطابق' : (v < 0 ? 'عجز' : 'زيادة');
}
