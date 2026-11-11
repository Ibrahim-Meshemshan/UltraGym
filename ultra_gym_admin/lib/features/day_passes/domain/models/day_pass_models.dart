import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../members/domain/models/member_history_models.dart';

/// دخول يومي: زيارة مدفوعة ليوم عمل واحد بفرع، لزائر بلا حساب أو لعضو بلا اشتراك صالح.
class DayPass extends Equatable {
  const DayPass({
    required this.id,
    required this.kind,
    required this.name,
    this.phone,
    this.gender,
    this.playerId,
    this.branchName,
    this.businessDate,
    this.checkedInAt,
    this.priceUsd = 0,
    this.paidUsd = 0,
    this.isFree = false,
    this.status = 'active',
    this.cancelledAt,
    this.cancellationReason,
    this.isOffline = false,
    this.notes,
    this.createdBy,
    this.transactions = const [],
  });

  factory DayPass.fromJson(Json j) => DayPass(
    id: j.intv('id'),
    kind: j.str('kind', 'visitor'),
    name: j.str('name', '—'),
    phone: j.strOrNull('phone'),
    gender: j.strOrNull('gender'),
    playerId: j.objOrNull('player')?.intOrNull('id'),
    branchName: j.obj('branch').strOrNull('name'),
    businessDate: j.day('business_date'),
    checkedInAt: j.date('checked_in_at'),
    priceUsd: j.dbl('price_usd'),
    paidUsd: j.dbl('paid_usd'),
    isFree: j.flag('is_free'),
    status: j.str('status', 'active'),
    cancelledAt: j.date('cancelled_at'),
    cancellationReason: j.strOrNull('cancellation_reason'),
    isOffline: j.flag('is_offline'),
    notes: j.strOrNull('notes'),
    createdBy: j.objOrNull('created_by')?.strOrNull('name'),
    transactions: asList(j['transactions'], PaymentEntry.fromJson),
  );

  final int id;

  /// `visitor` أو `player`.
  final String kind, name;
  final String? phone, gender;
  final int? playerId;
  final String? branchName;
  final DateTime? businessDate, checkedInAt;
  final double priceUsd, paidUsd;
  final bool isFree;

  /// `active` أو `cancelled`.
  final String status;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final bool isOffline;
  final String? notes, createdBy;
  final List<PaymentEntry> transactions;

  bool get isVisitor => kind != 'player';
  bool get isCancelled => status == 'cancelled';

  @override
  List<Object?> get props => [
    id,
    kind,
    name,
    phone,
    gender,
    playerId,
    branchName,
    businessDate,
    checkedInAt,
    priceUsd,
    paidUsd,
    isFree,
    status,
    cancelledAt,
    cancellationReason,
    isOffline,
    notes,
    createdBy,
    transactions,
  ];
}

/// سعر الدخول اليومي بفرع (`GET day-passes/price?branch_id=`).
class DayPassPrice extends Equatable {
  const DayPassPrice({
    this.enabled = true,
    this.branchId,
    this.branchName,
    this.priceUsd,
    this.priceSyp,
    this.source,
    this.canChangePrice = false,
    this.genderRequired = false,
  });

  factory DayPassPrice.fromJson(Json j) => DayPassPrice(
    enabled: j.flag('enabled', true),
    branchId: j.obj('branch').intOrNull('id'),
    branchName: j.obj('branch').strOrNull('name'),
    priceUsd: j.dblOrNull('price_usd'),
    priceSyp: j.intOrNull('price_syp'),
    source: j.strOrNull('source'),
    canChangePrice: j.flag('can_change_price'),
    genderRequired: j.flag('gender_required'),
  );

  final bool enabled;
  final int? branchId;
  final String? branchName;

  /// null = لا سعر محدد بالفرع ولا بالنادي (`DAY_PASS_PRICE_MISSING`)، والمالك يكتبه بالبيع.
  final double? priceUsd;
  final int? priceSyp;

  /// `branch` · `club` · null.
  final String? source;
  final bool canChangePrice, genderRequired;

  bool get hasPrice => priceUsd != null;

  /// البيع ممكن: مفعّل، وبسعر أو يستطيع المستخدم كتابته.
  bool get canSell => enabled && (hasPrice || canChangePrice);

  @override
  List<Object?> get props => [
    enabled,
    branchId,
    branchName,
    priceUsd,
    priceSyp,
    source,
    canChangePrice,
    genderRequired,
  ];
}

/// مجاميع السجل للفلتر الحالي (`meta.summary`).
class DayPassSummary extends Equatable {
  const DayPassSummary({this.count = 0, this.visitors = 0, this.players = 0, this.revenueUsd = 0});

  factory DayPassSummary.fromJson(Json j) => DayPassSummary(
    count: j.intv('count'),
    visitors: j.intv('visitors'),
    players: j.intv('players'),
    revenueUsd: j.dbl('revenue_usd'),
  );

  final int count, visitors, players;
  final double revenueUsd;

  @override
  List<Object?> get props => [count, visitors, players, revenueUsd];
}

/// فلاتر السجل كما يقبلها الخادم.
abstract final class DayPassFilters {
  static const kind = 'kind', status = 'status', from = 'from', to = 'to', branchId = 'branch_id';

  static const kinds = <FormOption<String>>[(value: 'visitor', label: 'زوار'), (value: 'player', label: 'أعضاء')];
  static const statuses = <FormOption<String>>[
    (value: 'active', label: 'الفعّال'),
    (value: 'cancelled', label: 'الملغى'),
  ];
}

/// شارة الحالة والنوع.
abstract final class DayPassLabels {
  static LabelSpec status(String status) => status == 'cancelled'
      ? (text: 'ملغى', tone: UTone.neutral, icon: Icons.block_rounded)
      : (text: 'فعّال', tone: UTone.success, icon: Icons.confirmation_number_rounded);

  static String kind(String kind) => kind == 'player' ? 'عضو' : 'زائر';
}
