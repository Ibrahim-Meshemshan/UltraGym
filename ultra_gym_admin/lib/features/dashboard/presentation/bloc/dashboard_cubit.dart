import '../../../../core/core.dart';
import '../../data/repo/dashboard_repository.dart';
import '../../domain/models/dashboard_models.dart';

/// الرئيسية: الأرقام (`summary`) وقائمة "تنتهي خلال 7 أيام" (`expiring`) بطلبين متوازيين،
/// ولكل منهما حالته: فشل القائمة لا يُسقط الصفحة.
class DashboardState extends Equatable {
  const DashboardState({this.summary = const Slice(), this.expiring = const Slice()});

  final Slice<DashboardData> summary;
  final Slice<List<ExpiringMembership>> expiring;

  DashboardState copyWith({Slice<DashboardData>? summary, Slice<List<ExpiringMembership>>? expiring}) =>
      DashboardState(summary: summary ?? this.summary, expiring: expiring ?? this.expiring);

  @override
  List<Object?> get props => [summary, expiring];
}

/// يُنشأ لكل فرع مختار (`branchId` = null ← كل الفروع المسموحة): تغيير الفرع ينشئ Cubit جديداً.
class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit(this._repo, {this.branchId}) : super(const DashboardState());

  final DashboardRepository _repo;
  final int? branchId;

  /// تحميل بهياكل للجزأين.
  Future<void> load() async {
    emit(DashboardState(summary: state.summary.toLoading(), expiring: state.expiring.toLoading()));
    await Future.wait([_summary(), _expiring()]);
  }

  /// تحديث صامت (بعد عملية): الخطأ مع وجود بيانات لا يمحوها.
  Future<void> refresh() => Future.wait([_summary(silent: true), _expiring(silent: true)]);

  /// إعادة قائمة المنتهية وحدها (زر إعادة المحاولة ببطاقتها).
  Future<void> retryExpiring() async {
    emit(state.copyWith(expiring: state.expiring.toLoading()));
    await _expiring();
  }

  Future<void> _summary({bool silent = false}) async {
    final r = await _repo.summary(branchId: branchId);
    if (isClosed) return;
    emit(state.copyWith(summary: _settle(state.summary, r, silent)));
  }

  Future<void> _expiring({bool silent = false}) async {
    final r = await _repo.expiring(branchId: branchId);
    if (isClosed) return;
    emit(state.copyWith(expiring: _settle(state.expiring, r, silent)));
  }

  static Slice<T> _settle<T>(Slice<T> current, ApiResult<T> r, bool silent) =>
      silent && r is ApiFailure<T> && current.hasData ? current : current.fromResult(r);
}
