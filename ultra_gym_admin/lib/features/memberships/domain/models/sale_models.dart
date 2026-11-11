import '../../../../core/core.dart';
import '../../../members/domain/models/member_profile_models.dart';
import '../../../quick_search/domain/models/quick_search_models.dart';

/// تسعير اشتراك `POST memberships/quote` للبيع والتجديد: الفترة والسعر والخصم والصافي بالعملتين من الخادم.
class MembershipQuote extends Equatable {
  const MembershipQuote({
    required this.netUsd,
    this.priceUsd = 0,
    this.discountUsd = 0,
    this.netSyp = 0,
    this.exchangeRate,
    this.startsOn,
    this.endsOn,
    this.couponCode,
    this.allowPartial = false,
  });

  factory MembershipQuote.fromJson(Json j) => MembershipQuote(
    netUsd: j.dbl('net_usd'),
    priceUsd: j.dbl('price_usd'),
    discountUsd: j.dbl('discount_usd'),
    netSyp: j.dbl('net_syp'),
    exchangeRate: j.dblOrNull('exchange_rate'),
    startsOn: j.day('starts_on'),
    endsOn: j.day('ends_on'),
    couponCode: j.objOrNull('coupon')?.strOrNull('code'),
    allowPartial: j.flag('allow_partial_payment'),
  );

  final double netUsd, priceUsd, discountUsd, netSyp;

  /// ليرة لكل دولار اليوم (null = لم يحدده المالك بعد).
  final double? exchangeRate;
  final DateTime? startsOn, endsOn;
  final String? couponCode;
  final bool allowPartial;

  /// تقدير المقبوض بالدولار للعرض فقط (الخادم يحسبه نهائياً بسعر صرف الحركة).
  double paidUsd({num usd = 0, num syp = 0}) {
    final rate = exchangeRate ?? 0;
    return usd + (rate > 0 ? syp / rate : 0);
  }

  @override
  List<Object?> get props => [
    netUsd,
    priceUsd,
    discountUsd,
    netSyp,
    exchangeRate,
    startsOn,
    endsOn,
    couponCode,
    allowPartial,
  ];
}

/// خطة قابلة للبيع `GET membership-plans?status=active` (بطاقة بشاشة البيع).
class SalePlan extends Equatable {
  const SalePlan({
    required this.id,
    required this.name,
    this.type = 'duration',
    this.durationDays = 0,
    this.sessionsCount,
    this.priceUsd = 0,
    this.priceSyp = 0,
    this.allBranches = true,
    this.branchNames = const [],
    this.isPersonal = false,
  });

  factory SalePlan.fromJson(Json j) => SalePlan(
    id: j.intv('id'),
    name: j.str('name'),
    type: j.str('type', 'duration'),
    durationDays: j.intv('duration_days'),
    sessionsCount: j.intOrNull('sessions_count'),
    priceUsd: j.dbl('price_usd'),
    priceSyp: j.dbl('price_syp'),
    allBranches: j.str('branch_scope', 'all') == 'all',
    branchNames: j.list('branches', (b) => b.str('name')),
    isPersonal: j.flag('is_personal_training'),
  );

  final int id;
  final String name, type;
  final int durationDays;
  final int? sessionsCount;
  final double priceUsd, priceSyp;
  final bool allBranches, isPersonal;
  final List<String> branchNames;

  bool get isSessions => type == 'sessions';

  @override
  List<Object?> get props => [
    id,
    name,
    type,
    durationDays,
    sessionsCount,
    priceUsd,
    priceSyp,
    allBranches,
    branchNames,
    isPersonal,
  ];
}

/// مدرب لخطة التدريب الخاص `GET staff-members?type=trainer&status=active` (القائمة متاحة للاستقبال).
class SaleTrainer extends Equatable {
  const SaleTrainer({required this.id, required this.name, this.branchName});

  factory SaleTrainer.fromJson(Json j) =>
      SaleTrainer(id: j.intv('id'), name: j.str('name'), branchName: j.objOrNull('branch')?.strOrNull('name'));

  final int id;
  final String name;
  final String? branchName;

  @override
  List<Object?> get props => [id, name, branchName];
}

/// العضو المختار للبيع: من البحث السريع أو من ملفه (رابط `?player_id=`).
class SaleMember extends Equatable {
  const SaleMember({
    required this.id,
    required this.name,
    this.memberCode,
    this.phone,
    this.membershipStatus,
    this.membershipLabel,
    this.dueUsd = 0,
  });

  factory SaleMember.fromLookup(LookupPlayer p) => SaleMember(
    id: p.id,
    name: p.name,
    memberCode: p.memberCode,
    phone: p.phone,
    membershipStatus: p.membership?.status,
    membershipLabel: p.membership?.statusLabel,
    dueUsd: p.membership?.dueUsd ?? 0,
  );

  factory SaleMember.fromProfile(MemberProfile p) => SaleMember(
    id: p.id,
    name: p.name,
    memberCode: p.memberCode,
    phone: p.phone,
    membershipStatus: p.membership?.status,
    membershipLabel: p.membership?.statusLabel,
    dueUsd: p.dueUsd,
  );

  final int id;
  final String name;
  final String? memberCode, phone;

  /// حالة الاشتراك الحالي (null = بلا اشتراك).
  final String? membershipStatus, membershipLabel;

  /// ديون العضو الحالية (تنبيه فقط، البيع مسموح).
  final double dueUsd;

  @override
  List<Object?> get props => [id, name, memberCode, phone, membershipStatus, membershipLabel, dueUsd];
}

/// نتيجة البيع `POST memberships`: الاشتراك الجديد ودينه وإيصال لكل دفعة.
class SaleResult extends Equatable {
  const SaleResult({required this.membershipId, this.dueUsd = 0, this.receipts = const [], this.message});

  factory SaleResult.fromJson(Json j) {
    final m = j.obj('membership');
    return SaleResult(
      membershipId: m.intv('id'),
      dueUsd: m.dbl('due_usd'),
      receipts: j.list('transactions', SaleReceipt.fromJson),
    );
  }

  final int membershipId;
  final double dueUsd;
  final List<SaleReceipt> receipts;

  /// رسالة الخادم ("تم تسجيل الاشتراك، والمتبقي $4.75 دين على اللاعب").
  final String? message;

  SaleResult withMessage(String? m) =>
      SaleResult(membershipId: membershipId, dueUsd: dueUsd, receipts: receipts, message: m);

  @override
  List<Object?> get props => [membershipId, dueUsd, receipts, message];
}

/// حركة قبض من البيع: رقم الإيصال والمبلغ بعملته.
class SaleReceipt extends Equatable {
  const SaleReceipt({required this.id, this.number, this.currency = 'USD', this.amount = 0});

  factory SaleReceipt.fromJson(Json j) => SaleReceipt(
    id: j.intv('id'),
    number: j.strOrNull('receipt_number'),
    currency: j.str('currency', 'USD'),
    amount: j.dbl('amount'),
  );

  final int id;
  final String? number;
  final String currency;
  final double amount;

  @override
  List<Object?> get props => [id, number, currency, amount];
}

/// نوع الخصم بالبيع: كوبون (للجميع) أو خصم يدوي بالدولار (للمالك).
enum DiscountMode { coupon, manual }
