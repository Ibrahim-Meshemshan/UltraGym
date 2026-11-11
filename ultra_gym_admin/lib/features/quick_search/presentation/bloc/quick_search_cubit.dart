import '../../../../core/core.dart';
import '../../data/repo/quick_search_repository.dart';
import '../../domain/models/quick_search_models.dart';

/// حالة البحث السريع: النص الحالي + النتائج.
class QuickSearchState extends Equatable {
  const QuickSearchState({this.query = '', this.results = const Slice()});

  final String query;
  final Slice<List<LookupPlayer>> results;

  /// أقل من حرفين: لا طلب (الخادم يشترط حرفين).
  bool get tooShort => query.length < QuickSearchCubit.minLength;

  QuickSearchState copyWith({String? query, Slice<List<LookupPlayer>>? results}) =>
      QuickSearchState(query: query ?? this.query, results: results ?? this.results);

  @override
  List<Object?> get props => [query, results];
}

/// البحث السريع (نافذة Ctrl K): ينتظر توقف الكتابة ثم يطلب، ويتجاهل رداً وصل لنص قديم.
/// `branchId` = الفرع المحدد بالشريط (لتقييم إمكانية الدخول).
class QuickSearchCubit extends Cubit<QuickSearchState> {
  QuickSearchCubit(this._repo, {this.branchId, Duration delay = AppConfig.searchDebounce})
    : _debouncer = Debouncer(delay),
      super(const QuickSearchState());

  static const minLength = 2;

  final QuickSearchRepository _repo;
  final int? branchId;
  final Debouncer _debouncer;

  void changed(String text) {
    final q = text.trim();
    if (q == state.query) return;
    if (q.length < minLength) {
      _debouncer.cancel();
      emit(QuickSearchState(query: q));
      return;
    }
    emit(state.copyWith(query: q, results: state.results.toLoading()));
    _debouncer.run(() => _fetch(q));
  }

  Future<void> retry() async {
    if (state.tooShort) return;
    emit(state.copyWith(results: state.results.toLoading()));
    await _fetch(state.query);
  }

  Future<void> _fetch(String q) async {
    final r = await _repo.lookup(q, branchId: branchId);
    if (isClosed || q != state.query) return;
    emit(state.copyWith(results: state.results.fromResult(r)));
  }

  @override
  Future<void> close() {
    _debouncer.dispose();
    return super.close();
  }
}
