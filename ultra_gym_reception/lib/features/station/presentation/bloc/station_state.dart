part of 'station_bloc.dart';

class StationState extends Equatable {
  const StationState({
    this.branchId,
    this.today = const Slice(),
    this.lookupQuery,
    this.lookup = const Slice(),
    this.outcome = const Slice(),
    this.attempt = 0,
  });

  final int? branchId;
  final Slice<TodaySummary> today;

  /// نص البحث المعروضة نتائجه (null = لا بحث ظاهر).
  final String? lookupQuery;
  final Slice<List<LookupPlayer>> lookup;

  /// آخر تسجيل: تحميل، نتيجة (مقبول/مكرر/مرفوض)، أو فشل (QR، غير موجود، شبكة).
  final Slice<CheckInResult> outcome;

  /// يزيد مع كل إدخال: الحقل يُمسح ويعود له التركيز.
  final int attempt;

  bool get busy => outcome.isLoading;

  StationState copyWith({
    int? branchId,
    Slice<TodaySummary>? today,
    String? Function()? lookupQuery,
    Slice<List<LookupPlayer>>? lookup,
    Slice<CheckInResult>? outcome,
    int? attempt,
  }) => StationState(
    branchId: branchId ?? this.branchId,
    today: today ?? this.today,
    lookupQuery: lookupQuery == null ? this.lookupQuery : lookupQuery(),
    lookup: lookup ?? this.lookup,
    outcome: outcome ?? this.outcome,
    attempt: attempt ?? this.attempt,
  );

  @override
  List<Object?> get props => [branchId, today, lookupQuery, lookup, outcome, attempt];
}
