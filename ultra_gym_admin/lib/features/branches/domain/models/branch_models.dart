import '../../../../core/core.dart';

/// فرع النادي كما يرجعه `GET club-admin/branches` (المالك يرى كل الفروع غير المؤرشفة، والاستقبال فروعه فقط).
/// الحقول كما بـ `ClubPayloads::branch` + `cash_session_open` بالقائمة.
class Branch extends Equatable {
  const Branch({
    required this.id,
    required this.name,
    this.city,
    this.phone,
    this.address,
    this.isMain = false,
    this.status = 'active',
    this.genderPolicy = 'mixed',
    this.schedule = const [],
    this.dayPassPriceUsd,
    this.cashSessionOpen = false,
  });

  factory Branch.fromJson(Json j) => Branch(
    id: j.intv('id'),
    name: j.str('name'),
    city: j.strOrNull('city'),
    phone: j.strOrNull('phone'),
    address: j.strOrNull('address'),
    isMain: j.flag('is_main'),
    status: j.str('status', 'active'),
    genderPolicy: j.str('gender_policy', 'mixed'),
    schedule: j.list('gender_schedule', GenderSlot.fromJson),
    dayPassPriceUsd: j.dblOrNull('day_pass_price_usd'),
    cashSessionOpen: j.flag('cash_session_open'),
  );

  final int id;
  final String name, status, genderPolicy;
  final String? city, phone, address;
  final bool isMain;

  /// فترات أقسام الذكور والإناث (لنظام `time_split` فقط)، بتوقيت النادي.
  final List<GenderSlot> schedule;

  /// سعر الدخول اليومي للفرع (null = سعر النادي).
  final double? dayPassPriceUsd;

  /// وردية صندوق مفتوحة الآن بهذا الفرع (من الخادم، لا تُحسب محلياً).
  final bool cashSessionOpen;

  bool get isActive => status == 'active';
  bool get timeSplit => genderPolicy == 'time_split';

  Branch copyWith({bool? cashSessionOpen}) => Branch(
    id: id,
    name: name,
    city: city,
    phone: phone,
    address: address,
    isMain: isMain,
    status: status,
    genderPolicy: genderPolicy,
    schedule: schedule,
    dayPassPriceUsd: dayPassPriceUsd,
    cashSessionOpen: cashSessionOpen ?? this.cashSessionOpen,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    city,
    phone,
    address,
    isMain,
    status,
    genderPolicy,
    schedule,
    dayPassPriceUsd,
    cashSessionOpen,
  ];
}

/// فترة قسم: أيام (`saturday`...)، من وإلى (`HH:mm`؛ إلى قبل من = تمتد بعد منتصف الليل)، والقسم.
class GenderSlot extends Equatable {
  const GenderSlot({required this.days, required this.from, required this.to, required this.gender, this.daysLabel});

  factory GenderSlot.fromJson(Json j) => GenderSlot(
    days: j.strList('days'),
    from: j.str('from'),
    to: j.str('to'),
    gender: j.str('gender', 'mixed'),
    daysLabel: j.strOrNull('days_label'),
  );

  final List<String> days;
  final String from, to, gender;
  final String? daysLabel;

  /// تنتهي صباح اليوم التالي.
  bool get overnight => to.compareTo(from) < 0;

  @override
  List<Object?> get props => [days, from, to, gender, daysLabel];
}
