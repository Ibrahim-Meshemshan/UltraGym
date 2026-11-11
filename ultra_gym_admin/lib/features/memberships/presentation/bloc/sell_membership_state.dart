part of 'sell_membership_cubit.dart';

/// حالة شاشة البيع: العضو، الخطط، المدربون (لخطة تدريب خاص)، الاختيارات المطبّقة، والتسعير.
/// الحقول النصية (الكوبون، المبالغ، الملاحظات...) بـ `AppFormCubit` الصفحة، وهنا ما يغيّر التسعير فقط.
class SellState extends Equatable {
  const SellState({
    this.member = const Slice(),
    this.plans = const Slice(),
    this.trainers = const Slice(),
    this.planId,
    this.startsOn,
    this.mode = DiscountMode.coupon,
    this.coupon,
    this.discount,
    this.discountError,
    this.quote = const Slice(),
    this.result,
  });

  /// العضو المختار (`initial` بلا بيانات = لم يُختر بعد؛ تحميل = عضو من الرابط).
  final Slice<SaleMember> member;
  final Slice<List<SalePlan>> plans;
  final Slice<List<SaleTrainer>> trainers;
  final int? planId;

  /// null = يختار الخادم (اليوم).
  final DateTime? startsOn;
  final DiscountMode mode;

  /// الكوبون والخصم اليدوي **المطبّقان** (قبلهما الخادم بالتسعير).
  final String? coupon;
  final double? discount;

  /// رفض الكوبون أو الخصم (`COUPON_INVALID`...) بنص الخادم.
  final String? discountError;
  final Slice<MembershipQuote> quote;

  /// بعد البيع: الإيصالات ورابط الاشتراك (الشاشة تعرض النجاح بدل النموذج).
  final SaleResult? result;

  SalePlan? get plan => plans.data?.where((p) => p.id == planId).firstOrNull;

  bool get needsTrainer => plan?.isPersonal ?? false;

  SellState copyWith({
    Slice<SaleMember>? member,
    Slice<List<SalePlan>>? plans,
    Slice<List<SaleTrainer>>? trainers,
    ValueGetter<int?>? planId,
    ValueGetter<DateTime?>? startsOn,
    DiscountMode? mode,
    ValueGetter<String?>? coupon,
    ValueGetter<double?>? discount,
    ValueGetter<String?>? discountError,
    Slice<MembershipQuote>? quote,
    ValueGetter<SaleResult?>? result,
  }) => SellState(
    member: member ?? this.member,
    plans: plans ?? this.plans,
    trainers: trainers ?? this.trainers,
    planId: planId == null ? this.planId : planId(),
    startsOn: startsOn == null ? this.startsOn : startsOn(),
    mode: mode ?? this.mode,
    coupon: coupon == null ? this.coupon : coupon(),
    discount: discount == null ? this.discount : discount(),
    discountError: discountError == null ? this.discountError : discountError(),
    quote: quote ?? this.quote,
    result: result == null ? this.result : result(),
  );

  @override
  List<Object?> get props => [
    member,
    plans,
    trainers,
    planId,
    startsOn,
    mode,
    coupon,
    discount,
    discountError,
    quote,
    result,
  ];
}
