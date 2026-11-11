import '../../../../core/core.dart';

/// `GET /club-admin/dashboard`: وضع النادي اليوم. كل الأرقام محسوبة بالخادم (لا حساب هنا).
/// `finance` ورصيد الصناديق للمالك فقط (`null` للاستقبال).
class DashboardData extends Equatable {
  const DashboardData({
    required this.businessDate,
    this.players = const DashboardPlayers(),
    this.memberships = const DashboardMemberships(),
    this.attendance = const DashboardAttendance(),
    this.debts = const DashboardDebts(),
    this.cashBoxes = const [],
    this.finance,
    this.alerts = const [],
  });

  factory DashboardData.fromJson(Json j) => DashboardData(
    businessDate: j.day('business_date'),
    players: DashboardPlayers.fromJson(j.obj('players')),
    memberships: DashboardMemberships.fromJson(j.obj('memberships')),
    attendance: DashboardAttendance.fromJson(j.obj('attendance')),
    debts: DashboardDebts.fromJson(j.obj('debts')),
    cashBoxes: j.list('cash_sessions', CashBox.fromJson),
    finance: switch (j.objOrNull('finance')) {
      final f? => DashboardFinance.fromJson(f),
      null => null,
    },
    alerts: j.list('alerts', DashboardAlert.fromJson),
  );

  /// يوم العمل الحالي للنادي (ينتهي 2 فجراً).
  final DateTime? businessDate;
  final DashboardPlayers players;
  final DashboardMemberships memberships;
  final DashboardAttendance attendance;
  final DashboardDebts debts;
  final List<CashBox> cashBoxes;
  final DashboardFinance? finance;
  final List<DashboardAlert> alerts;

  @override
  List<Object?> get props => [businessDate, players, memberships, attendance, debts, cashBoxes, finance, alerts];
}

class DashboardPlayers extends Equatable {
  const DashboardPlayers({this.total = 0, this.newThisMonth = 0});

  factory DashboardPlayers.fromJson(Json j) =>
      DashboardPlayers(total: j.intv('total'), newThisMonth: j.intv('new_this_month'));

  final int total, newThisMonth;

  @override
  List<Object?> get props => [total, newThisMonth];
}

class DashboardMemberships extends Equatable {
  const DashboardMemberships({
    this.active = 0,
    this.frozen = 0,
    this.expiring7Days = 0,
    this.inGrace = 0,
    this.soldToday = 0,
    this.soldThisMonth = 0,
  });

  factory DashboardMemberships.fromJson(Json j) => DashboardMemberships(
    active: j.intv('active'),
    frozen: j.intv('frozen'),
    expiring7Days: j.intv('expiring_7_days'),
    inGrace: j.intv('in_grace'),
    soldToday: j.intv('sold_today'),
    soldThisMonth: j.intv('sold_this_month'),
  );

  final int active, frozen, expiring7Days, inGrace, soldToday, soldThisMonth;

  @override
  List<Object?> get props => [active, frozen, expiring7Days, inGrace, soldToday, soldThisMonth];
}

class DashboardAttendance extends Equatable {
  const DashboardAttendance({this.today = 0, this.rejectedToday = 0, this.thisMonth = 0, this.visitorsToday = 0});

  factory DashboardAttendance.fromJson(Json j) => DashboardAttendance(
    today: j.intv('today'),
    rejectedToday: j.intv('rejected_today'),
    thisMonth: j.intv('this_month'),
    visitorsToday: j.intv('visitors_today'),
  );

  /// `today` دخول الأعضاء المقبول (يشمل العضو بدخول يومي)، و `visitorsToday` زوار الدخول اليومي بلا حساب.
  final int today, rejectedToday, thisMonth, visitorsToday;

  @override
  List<Object?> get props => [today, rejectedToday, thisMonth, visitorsToday];
}

class DashboardDebts extends Equatable {
  const DashboardDebts({this.totalDueUsd = 0, this.players = 0, this.totalDueSyp});

  factory DashboardDebts.fromJson(Json j) => DashboardDebts(
    totalDueUsd: j.dbl('total_due_usd'),
    players: j.intv('players'),
    totalDueSyp: j.dblOrNull('total_due_syp'),
  );

  final double totalDueUsd;
  final int players;
  final double? totalDueSyp;

  @override
  List<Object?> get props => [totalDueUsd, players, totalDueSyp];
}

/// صندوق فرع: مفتوح أم لا، ورصيده المتوقع (للمالك فقط).
class CashBox extends Equatable {
  const CashBox({
    required this.branchId,
    required this.branchName,
    this.isOpen = false,
    this.sessionId,
    this.openedAt,
    this.expectedUsd,
    this.expectedSyp,
  });

  factory CashBox.fromJson(Json j) {
    final branch = j.obj('branch');
    final balance = j.objOrNull('balance');
    return CashBox(
      branchId: branch.intv('id'),
      branchName: branch.str('name'),
      isOpen: j.flag('is_open'),
      sessionId: j.intOrNull('session_id'),
      openedAt: j.date('opened_at'),
      expectedUsd: balance?.dblOrNull('expected_usd'),
      expectedSyp: balance?.dblOrNull('expected_syp'),
    );
  }

  final int branchId;
  final String branchName;
  final bool isOpen;
  final int? sessionId;
  final DateTime? openedAt;
  final double? expectedUsd, expectedSyp;

  bool get hasBalance => expectedUsd != null || expectedSyp != null;

  @override
  List<Object?> get props => [branchId, branchName, isOpen, sessionId, openedAt, expectedUsd, expectedSyp];
}

/// المال (للمالك): اليوم والشهر، وإيراد آخر 14 يوماً (الأقدم أولاً، وآخرها اليوم).
class DashboardFinance extends Equatable {
  const DashboardFinance({
    this.revenueTodayUsd = 0,
    this.revenueMonthUsd = 0,
    this.expensesMonthUsd = 0,
    this.netMonthUsd = 0,
    this.daily = const [],
  });

  factory DashboardFinance.fromJson(Json j) => DashboardFinance(
    revenueTodayUsd: j.dbl('revenue_today_usd'),
    revenueMonthUsd: j.dbl('revenue_month_usd'),
    expensesMonthUsd: j.dbl('expenses_month_usd'),
    netMonthUsd: j.dbl('net_month_usd'),
    daily: [
      for (final d in j.list('revenue_last_14_days', (e) => e))
        if (d.day('date') case final date?) (date: date, usd: d.dbl('revenue_usd')),
    ],
  );

  final double revenueTodayUsd, revenueMonthUsd, expensesMonthUsd, netMonthUsd;
  final List<({DateTime date, double usd})> daily;

  @override
  List<Object?> get props => [revenueTodayUsd, revenueMonthUsd, expensesMonthUsd, netMonthUsd, daily];
}

/// تنبيه جاهز من الخادم: `type` يحدد الشكل والرابط، و `message` يُعرض كما هو.
class DashboardAlert extends Equatable {
  const DashboardAlert({required this.type, required this.message});

  factory DashboardAlert.fromJson(Json j) => DashboardAlert(type: j.str('type'), message: j.str('message'));

  final String type, message;

  @override
  List<Object?> get props => [type, message];
}

/// اشتراك ينتهي قريباً (`GET memberships?expiring_within_days=7`).
class ExpiringMembership extends Equatable {
  const ExpiringMembership({
    required this.id,
    required this.playerName,
    this.planName = '',
    this.branchName = '',
    this.endsOn,
    this.daysRemaining,
    this.status,
    this.statusLabel = '',
  });

  factory ExpiringMembership.fromJson(Json j) => ExpiringMembership(
    id: j.intv('id'),
    playerName: j.obj('player').str('name'),
    planName: j.obj('plan').str('name'),
    branchName: j.obj('branch').str('name'),
    endsOn: j.day('ends_on'),
    daysRemaining: j.intOrNull('days_remaining'),
    status: j.strOrNull('status'),
    statusLabel: j.str('status_label'),
  );

  final int id;
  final String playerName, planName, branchName;
  final DateTime? endsOn;
  final int? daysRemaining;
  final String? status;
  final String statusLabel;

  @override
  List<Object?> get props => [id, playerName, planName, branchName, endsOn, daysRemaining, status, statusLabel];
}
