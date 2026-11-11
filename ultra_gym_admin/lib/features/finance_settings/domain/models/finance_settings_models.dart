import '../../../../core/core.dart';

/// سطر بسجل سعر الصرف (`GET club-admin/finance/exchange-rate`، الأحدث أولاً).
class ExchangeRateEntry extends Equatable {
  const ExchangeRateEntry({required this.id, required this.sypPerUsd, this.note, this.createdBy, this.createdAt});

  factory ExchangeRateEntry.fromJson(Json j) => ExchangeRateEntry(
    id: j.intv('id'),
    sypPerUsd: j.dbl('syp_per_usd'),
    note: j.strOrNull('note'),
    createdBy: j.objOrNull('created_by')?.strOrNull('name'),
    createdAt: j.date('created_at'),
  );

  final int id;
  final double sypPerUsd;
  final String? note, createdBy;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [id, sypPerUsd, note, createdBy, createdAt];
}

/// السعر المعتمد الآن (`meta.current`). `sypPerUsd` null = لم يُحدَّد بعد (البيع بالليرة يُرفض بـ
/// `EXCHANGE_RATE_MISSING`).
class CurrentRate extends Equatable {
  const CurrentRate({this.sypPerUsd, this.updatedAt});

  factory CurrentRate.fromJson(Json j) => CurrentRate(sypPerUsd: j.dblOrNull('syp_per_usd'), updatedAt: j.date('updated_at'));

  final double? sypPerUsd;
  final DateTime? updatedAt;

  bool get isSet => sypPerUsd != null && sypPerUsd! > 0;

  @override
  List<Object?> get props => [sypPerUsd, updatedAt];
}

/// السعر الحالي من صفحة السجل (`meta.current`).
CurrentRate currentRateOf(Paged<ExchangeRateEntry>? page) => CurrentRate.fromJson(asJson(page?.meta['current']));

/// الفرق عن السعر الأقدم التالي بنفس الصفحة (للعرض فقط؛ آخر سطر بالصفحة بلا مقارنة).
double? rateChange(List<ExchangeRateEntry> rows, int index) =>
    index + 1 < rows.length ? rows[index].sypPerUsd - rows[index + 1].sypPerUsd : null;
