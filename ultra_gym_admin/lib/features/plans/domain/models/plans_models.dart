import '../../../../core/core.dart';

/// خطة اشتراك كما بـ `GET club-admin/membership-plans` (`ClubPayloads::plan` + `memberships_sold`).
/// حدود التجميد تأتي محسوبة (افتراضي النادي حين `uses_default_freeze_limits`).
class Plan extends Equatable {
  const Plan({
    required this.id,
    required this.name,
    this.description,
    this.type = 'duration',
    this.durationDays = 0,
    this.sessionsCount,
    this.priceUsd = 0,
    this.priceSyp = 0,
    this.allBranches = true,
    this.branches = const [],
    this.maxFreezes = 0,
    this.maxFreezeDays = 0,
    this.defaultFreeze = true,
    this.isPersonal = false,
    this.active = true,
    this.sold,
  });

  factory Plan.fromJson(Json j) => Plan(
    id: j.intv('id'),
    name: j.str('name', '—'),
    description: j.strOrNull('description'),
    type: j.str('type', 'duration'),
    durationDays: j.intv('duration_days'),
    sessionsCount: j.intOrNull('sessions_count'),
    priceUsd: j.dbl('price_usd'),
    priceSyp: j.dbl('price_syp'),
    allBranches: j.str('branch_scope', 'all') != 'selected',
    branches: j.list('branches', (b) => (id: b.intv('id'), name: b.str('name'))),
    maxFreezes: j.intv('max_freezes'),
    maxFreezeDays: j.intv('max_freeze_days'),
    defaultFreeze: j.flag('uses_default_freeze_limits', true),
    isPersonal: j.flag('is_personal_training'),
    active: j.str('status', 'active') == 'active',
    sold: j.intOrNull('memberships_sold'),
  );

  final int id;
  final String name, type;
  final String? description;
  final int durationDays;
  final int? sessionsCount;
  final double priceUsd, priceSyp;
  final bool allBranches;
  final List<({int id, String name})> branches;
  final int maxFreezes, maxFreezeDays;

  /// حدود التجميد من إعداد النادي (لم تُحدَّد للخطة).
  final bool defaultFreeze;
  final bool isPersonal, active;

  /// عدد الاشتراكات المباعة منها (القائمة فقط).
  final int? sold;

  bool get isSessions => type == 'sessions';

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    type,
    durationDays,
    sessionsCount,
    priceUsd,
    priceSyp,
    allBranches,
    branches,
    maxFreezes,
    maxFreezeDays,
    defaultFreeze,
    isPersonal,
    active,
    sold,
  ];
}

/// كوبون خصم (`ClubPayloads::coupon`). الحالة من الخادم: `active` / `inactive` فقط.
class Coupon extends Equatable {
  const Coupon({
    required this.id,
    required this.code,
    this.percent = true,
    this.value = 0,
    this.maxUses,
    this.usedCount = 0,
    this.startsOn,
    this.endsOn,
    this.planIds = const [],
    this.active = true,
    this.note,
  });

  factory Coupon.fromJson(Json j) => Coupon(
    id: j.intv('id'),
    code: j.str('code', '—'),
    percent: j.str('discount_type', 'percent') == 'percent',
    value: j.dbl('discount_value'),
    maxUses: j.intOrNull('max_uses'),
    usedCount: j.intv('used_count'),
    startsOn: j.strOrNull('starts_on'),
    endsOn: j.strOrNull('ends_on'),
    planIds: j.intList('plan_ids'),
    active: j.str('status', 'active') == 'active',
    note: j.strOrNull('note'),
  );

  final int id;
  final String code;

  /// نسبة مئوية أو مبلغ ثابت بالدولار.
  final bool percent;
  final double value;

  /// null = بلا حد.
  final int? maxUses;
  final int usedCount;

  /// `YYYY-MM-DD` بتوقيت النادي (لا تُحوَّل).
  final String? startsOn, endsOn;

  /// فارغة = كل الخطط.
  final List<int> planIds;
  final bool active;
  final String? note;

  /// المستعمل لا يُحذف بل يُوقف (`409 CONFLICT`).
  bool get canDelete => usedCount == 0;

  /// نسبة الاستعمال للشريط (null بلا حد).
  double? get usage => maxUses == null || maxUses == 0 ? null : (usedCount / maxUses!).clamp(0, 1).toDouble();

  @override
  List<Object?> get props => [id, code, percent, value, maxUses, usedCount, startsOn, endsOn, planIds, active, note];
}

/// نصوص العرض (من حقول الخادم فقط).
abstract final class PlanTexts {
  static String kind(Plan p) => p.isSessions ? 'عدد حصص' : 'حسب المدة';

  static String duration(int days) => Formatters.count(days, 'يوم واحد', 'يومان', 'أيام', many: 'يوماً');

  static String sessions(int n) => Formatters.count(n, 'حصة واحدة', 'حصتان', 'حصص', many: 'حصة');

  static String branches(Plan p) =>
      p.allBranches || p.branches.isEmpty ? 'كل الفروع' : p.branches.map((b) => b.name).join('، ');

  static String freeze(Plan p) {
    if (p.maxFreezes == 0 || p.maxFreezeDays == 0) return 'بلا تجميد';
    final v =
        '${Formatters.count(p.maxFreezes, 'مرة واحدة', 'مرتان', 'مرات', many: 'مرة')} · ${duration(p.maxFreezeDays)}';
    return p.defaultFreeze ? '$v (افتراضي النادي)' : v;
  }

  static String discount(Coupon c) =>
      c.percent ? '${Formatters.number(c.value)}%' : Formatters.usd(c.value);

  static String uses(Coupon c) => '${c.usedCount} / ${c.maxUses ?? '∞'}';

  /// أسماء الخطط المشمولة (من قائمة الخطط المحمّلة؛ المعرّف غير المعروف يظهر "#id").
  static String couponPlans(Coupon c, List<Plan> plans) {
    if (c.planIds.isEmpty) return 'كل الخطط';
    final names = {for (final p in plans) p.id: p.name};
    return c.planIds.map((id) => names[id] ?? '#$id').join('، ');
  }
}
