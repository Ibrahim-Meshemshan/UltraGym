import '../../../../core/core.dart';
import '../../data/repo/station_repository.dart';
import '../../domain/models/check_in_models.dart';
import '../../domain/models/station_models.dart';

part 'station_event.dart';
part 'station_state.dart';

/// محطة الدخول: كل إدخال (QR بالكاميرا أو القارئ، معرّف، أو اختيار من البحث) ← تسجيل دخول بمفتاح منع تكرار
/// جديد، والنتيجة ببطاقة. البحث بالاسم أو الموبايل يعرض نتائج للاختيار. بعد أي تسجيل يتحدث حضور اليوم.
class StationBloc extends Bloc<StationEvent, StationState> {
  StationBloc(this._repo) : super(const StationState()) {
    on<StationBranchChanged>(_onBranch);
    on<StationTodayRequested>((e, emit) => _loadToday(emit));
    on<StationSubmitted>(_onSubmitted);
    on<StationPlayerPicked>((e, emit) => _checkIn({'player_id': e.player.id}, emit));
    on<StationRetried>(_onRetried);
    on<StationCleared>(
      (e, emit) => emit(
        state.copyWith(
          lookupQuery: () => null,
          lookup: const Slice(),
          outcome: const Slice(),
          attempt: state.attempt + 1,
        ),
      ),
    );
  }

  final StationRepository _repo;

  /// آخر طلب تسجيل لم ينجح بالشبكة: يُعاد بنفس المفتاح.
  ({Json body, String key})? _pending;

  Future<void> _onBranch(StationBranchChanged e, Emitter<StationState> emit) async {
    if (e.branchId == state.branchId) return;
    _pending = null;
    emit(StationState(branchId: e.branchId, attempt: state.attempt + 1));
    await _loadToday(emit);
  }

  Future<void> _loadToday(Emitter<StationState> emit) async {
    final branch = state.branchId;
    if (branch == null) return;
    emit(state.copyWith(today: state.today.toLoading()));
    final r = await _repo.today(branch);
    if (branch != state.branchId) return;
    emit(state.copyWith(today: state.today.fromResult(r)));
  }

  Future<void> _onSubmitted(StationSubmitted e, Emitter<StationState> emit) async {
    switch (StationInput.parse(e.raw)) {
      case null:
        return;
      case QrInput(:final token):
        await _checkIn({'qr_token': token}, emit);
      case CodeInput(:final code):
        await _checkIn({'member_code': code}, emit);
      case SearchInput(:final query):
        await _search(query, emit);
    }
  }

  Future<void> _search(String q, Emitter<StationState> emit) async {
    final branch = state.branchId;
    if (branch == null) return;
    emit(
      state.copyWith(
        lookupQuery: () => q,
        lookup: const Slice(status: LoadStatus.loading),
        outcome: const Slice(),
        attempt: state.attempt + 1,
      ),
    );
    final r = await _repo.lookup(q, branch);
    if (state.lookupQuery != q) return;
    emit(state.copyWith(lookup: state.lookup.fromResult(r)));
  }

  Future<void> _checkIn(Json input, Emitter<StationState> emit) async {
    final branch = state.branchId;
    if (branch == null || state.busy) return;
    final body = {...input, 'branch_id': branch};
    await _send((body: body, key: Idempotency.newKey()), emit);
  }

  Future<void> _onRetried(StationRetried e, Emitter<StationState> emit) async {
    final pending = _pending;
    if (pending == null || state.busy) return;
    await _send(pending, emit);
  }

  Future<void> _send(({Json body, String key}) request, Emitter<StationState> emit) async {
    _pending = request;
    emit(
      state.copyWith(
        lookupQuery: () => null,
        lookup: const Slice(),
        outcome: const Slice(status: LoadStatus.loading),
        attempt: state.attempt + 1,
      ),
    );
    final r = await _repo.checkIn(request.body, idempotencyKey: request.key);
    if (request.body['branch_id'] != state.branchId) return;
    // الشبكة: يبقى الطلب لإعادته بنفس المفتاح. غير ذلك انتهى (نجح أو رفضه الخادم نهائياً).
    if (r.failureOrNull?.isNetwork != true) _pending = null;
    emit(state.copyWith(outcome: const Slice<CheckInResult>().fromResult(r), attempt: state.attempt + 1));
    if (r.dataOrNull case final result? when result.kind != CheckInKind.duplicate) await _loadToday(emit);
  }
}
