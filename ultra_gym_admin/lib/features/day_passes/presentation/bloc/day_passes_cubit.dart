import '../../../../core/core.dart';
import '../../../quick_search/domain/models/quick_search_models.dart';
import '../../data/repo/day_passes_repository.dart';
import '../../domain/models/day_pass_models.dart';

/// معاملات السجل: فرع الشريط العلوي + فلتر أولي من الرابط.
typedef DayPassesArgs = ({int? branchId, ListQuery query});

/// سجل الدخول اليومي بفرع الشريط العلوي (المجاميع بـ `meta.summary`). تغيير الفرع ينشئ واحداً جديداً.
class DayPassesListCubit extends ListCubit<DayPass> {
  DayPassesListCubit(DayPassesRepository repo, DayPassesArgs args)
    : super((q) => repo.list(q, branchId: args.branchId), query: args.query);
}

/// سعر الدخول اليومي بفرع (رأس الشاشة): فرع الشريط أو الرئيسي.
class DayPassPriceCubit extends LoadCubit<DayPassPrice> {
  DayPassPriceCubit(DayPassesRepository repo, {int? branchId}) : super(() => repo.price(branchId: branchId));
}

/// تفاصيل دخول يومي مع دفعاته (نافذة التفاصيل).
class DayPassDetailCubit extends LoadCubit<DayPass> {
  DayPassDetailCubit(DayPassesRepository repo, int id) : super(() => repo.detail(id));
}

/// الفلتر الأولي من الرابط: `/day-passes?kind=visitor&status=cancelled&from=…&to=…&branch_id=2&search=…`.
ListQuery dayPassesQueryFrom(Map<String, String> params) {
  var q = const ListQuery();
  for (final (key, options) in const [
    (DayPassFilters.kind, DayPassFilters.kinds),
    (DayPassFilters.status, DayPassFilters.statuses),
  ]) {
    final v = params[key];
    if (options.any((o) => o.value == v)) q = q.withFilter(key, v);
  }
  for (final key in const [DayPassFilters.from, DayPassFilters.to]) {
    if (DateTime.tryParse(params[key] ?? '') case final d?) q = q.withFilter(key, DateTime(d.year, d.month, d.day));
  }
  if (int.tryParse(params[DayPassFilters.branchId] ?? '') case final id?) {
    q = q.withFilter(DayPassFilters.branchId, id);
  }
  if (params['search'] case final s? when s.trim().isNotEmpty) q = q.withSearch(s.trim());
  return q;
}

/// لمن يُباع الدخول: زائر بلا حساب أو عضو مسجّل بلا اشتراك صالح.
enum DayPassBuyer { visitor, member }

class DayPassSaleState extends Equatable {
  const DayPassSaleState({
    this.price = const Slice(),
    this.buyer = DayPassBuyer.visitor,
    this.player,
    this.result,
    this.sold = false,
  });

  /// سعر فرع البيع (يُعاد طلبه مع تغيير الفرع).
  final Slice<DayPassPrice> price;
  final DayPassBuyer buyer;
  final LookupPlayer? player;

  /// آخر بيع ناجح (يُعرض بالنافذة مع إيصالاته).
  final DayPass? result;

  /// بيع شيء خلال النافذة: السجل يتحدث بعد إغلاقها.
  final bool sold;

  DayPassSaleState copyWith({
    Slice<DayPassPrice>? price,
    DayPassBuyer? buyer,
    LookupPlayer? Function()? player,
    DayPass? Function()? result,
    bool? sold,
  }) => DayPassSaleState(
    price: price ?? this.price,
    buyer: buyer ?? this.buyer,
    player: player == null ? this.player : player(),
    result: result == null ? this.result : result(),
    sold: sold ?? this.sold,
  );

  @override
  List<Object?> get props => [price, buyer, player, result, sold];
}

/// نافذة بيع الدخول اليومي: السعر بالفرع، نوع المشتري، العضو المختار، ومفتاح منع التكرار.
class DayPassSaleCubit extends Cubit<DayPassSaleState> {
  DayPassSaleCubit(this._repo) : super(const DayPassSaleState());

  final DayPassesRepository _repo;
  IdempotencyKeeper _keeper = IdempotencyKeeper();
  int _priceRequest = 0;
  int? _branchId;

  String keyFor(Json body) => _keeper.keyFor(body);

  /// سعر الفرع؛ رد قديم (فرع تغيّر قبل وصوله) يُتجاهل.
  Future<void> loadPrice(int? branchId) async {
    _branchId = branchId;
    final request = ++_priceRequest;
    emit(state.copyWith(price: state.price.toLoading()));
    final r = await _repo.price(branchId: branchId);
    if (isClosed || request != _priceRequest) return;
    emit(state.copyWith(price: state.price.fromResult(r)));
  }

  Future<void> retryPrice() => loadPrice(_branchId);

  void setBuyer(DayPassBuyer buyer) => emit(state.copyWith(buyer: buyer));

  void pick(LookupPlayer player) => emit(state.copyWith(player: () => player, buyer: DayPassBuyer.member));

  void clearPlayer() => emit(state.copyWith(player: () => null));

  void done(DayPass pass) => emit(state.copyWith(result: () => pass, sold: true));

  /// بيع آخر: نموذج جديد بمفتاح جديد، والسعر يبقى.
  void again() {
    _keeper = IdempotencyKeeper();
    emit(DayPassSaleState(price: state.price, buyer: state.buyer, sold: state.sold));
  }
}
