import '../../../../core/core.dart';
import '../../../branches/domain/models/branch_models.dart';

/// فترة قسم بالمحرر: الوقتان نصّان كما كُتبا (`8:00` يُقبل ويُرسل `08:00`).
class SlotDraft extends Equatable {
  const SlotDraft({
    required this.uid,
    this.days = const [],
    this.from = '08:00',
    this.to = '14:00',
    this.gender = 'mixed',
  });

  factory SlotDraft.of(GenderSlot s) =>
      SlotDraft(uid: DraftIds.next(), days: s.days, from: s.from, to: s.to, gender: s.gender);

  /// فترة جديدة: السبت حتى الخميس، صباحاً، مختلط.
  factory SlotDraft.blank() =>
      SlotDraft(uid: DraftIds.next(), days: const ['saturday', 'sunday', 'monday', 'tuesday', 'wednesday', 'thursday']);

  final int uid;
  final List<String> days;
  final String from, to, gender;

  /// تنتهي صباح اليوم التالي (`to` قبل `from`).
  bool get overnight {
    final f = BranchDraft.time(from), t = BranchDraft.time(to);
    return f != null && t != null && t.compareTo(f) < 0;
  }

  SlotDraft copyWith({List<String>? days, String? from, String? to, String? gender}) => SlotDraft(
    uid: uid,
    days: days ?? this.days,
    from: from ?? this.from,
    to: to ?? this.to,
    gender: gender ?? this.gender,
  );

  /// الأيام بترتيب الأسبوع (السبت أولاً) كما يحفظها الخادم.
  Json body() => {
    'days': [
      for (final d in SettingsDays.keys)
        if (days.contains(d)) d,
    ],
    'from': BranchDraft.time(from),
    'to': BranchDraft.time(to),
    'gender': gender,
  };

  @override
  List<Object?> get props => [uid, days, from, to, gender];
}

abstract final class SettingsDays {
  static const keys = ['saturday', 'sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday'];
}

/// الفرع بالمحرر (إضافة أو تعديل): بياناته ونظام الدخول وفتراته.
class BranchDraft extends Equatable {
  const BranchDraft({
    this.id,
    this.name = '',
    this.phone = '',
    this.city = '',
    this.address = '',
    this.price = '',
    this.policy = 'mixed',
    this.slots = const [],
  });

  factory BranchDraft.of(Branch b) => BranchDraft(
    id: b.id,
    name: b.name,
    phone: b.phone ?? '',
    city: b.city ?? '',
    address: b.address ?? '',
    price: b.dayPassPriceUsd == null ? '' : Formatters.number(b.dayPassPriceUsd).replaceAll(',', ''),
    policy: b.genderPolicy,
    slots: [for (final s in b.schedule) SlotDraft.of(s)],
  );

  static const maxSlots = 21;
  static final _time = RegExp(r'^(\d{1,2}):(\d{2})$');

  /// `8:00` ← `08:00`، و null لصيغة أو قيمة غير صالحة.
  static String? time(String v) {
    final m = _time.firstMatch(v.trim());
    if (m == null) return null;
    final h = int.parse(m.group(1)!), min = int.parse(m.group(2)!);
    if (h > 23 || min > 59) return null;
    return '${h.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
  }

  final int? id;
  final String name, phone, city, address, price, policy;
  final List<SlotDraft> slots;

  bool get isNew => id == null;
  bool get timeSplit => policy == 'time_split';

  BranchDraft copyWith({
    String? name,
    String? phone,
    String? city,
    String? address,
    String? price,
    String? policy,
    List<SlotDraft>? slots,
  }) => BranchDraft(
    id: id,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    city: city ?? this.city,
    address: address ?? this.address,
    price: price ?? this.price,
    policy: policy ?? this.policy,
    slots: slots ?? this.slots,
  );

  static String? _text(String v) => v.trim().isEmpty ? null : v.trim();
  static num? _price(String v) => num.tryParse(v.replaceAll(',', '').trim());

  /// جسم واحد للإضافة والتعديل. المختلط لا يرسل الجدول فيبقى المحفوظ للعودة إليه.
  Json body() => {
    'name': name.trim(),
    'phone': _text(phone),
    'city': _text(city),
    'address': _text(address),
    'day_pass_price_usd': _price(price),
    'gender_policy': policy,
    if (timeSplit) 'gender_schedule': [for (final s in slots) s.body()],
  };

  /// تحقق محلي بمفاتيح الخادم نفسها (`gender_schedule.0.days`) فيظهر الخطأ و 422 تحت الحقل نفسه.
  Map<String, String> validate() {
    final e = <String, String>{};
    if (name.trim().isEmpty) e['name'] = 'اكتب اسم الفرع.';
    if (name.trim().length > 100) e['name'] = 'أقصى طول 100 حرف.';
    if (phone.trim().length > 20) e['phone'] = 'أقصى طول 20 رقماً.';
    if (price.trim().isNotEmpty) {
      final p = _price(price);
      if (p == null || p < 0) e['day_pass_price_usd'] = 'اكتب السعر بالأرقام، أو اتركه فارغاً لسعر النادي.';
    }
    if (!timeSplit) return e;
    if (slots.isEmpty) e['gender_schedule'] = 'أضف فترة واحدة على الأقل، أو اختر "مختلط".';
    for (final (i, s) in slots.indexed) {
      if (s.days.isEmpty) e['gender_schedule.$i.days'] = 'اختر يوماً واحداً على الأقل.';
      final f = time(s.from), t = time(s.to);
      if (f == null) e['gender_schedule.$i.from'] = 'الوقت بصيغة 08:00.';
      if (t == null) e['gender_schedule.$i.to'] = 'الوقت بصيغة 14:00.';
      if (f != null && f == t) e['gender_schedule.$i.to'] = 'النهاية غير البداية.';
    }
    return e;
  }

  @override
  List<Object?> get props => [id, name, phone, city, address, price, policy, slots];
}
