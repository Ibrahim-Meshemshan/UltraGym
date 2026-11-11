import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/core.dart';
import '../../data/repo/station_repository.dart';
import '../../domain/models/station_models.dart';

/// فرع هذه المحطة: فروع الموظف من الخادم، والمختار محفوظ بالمتصفح (جهاز الاستقبال يبقى على فرعه).
class ActiveBranchState extends Equatable {
  const ActiveBranchState({this.branches = const Slice(), this.selectedId});

  final Slice<List<StationBranch>> branches;
  final int? selectedId;

  StationBranch? get branch => branches.data?.where((b) => b.id == selectedId).firstOrNull;

  @override
  List<Object?> get props => [branches, selectedId];
}

/// يعيش طوال الجلسة (الشريط العلوي والمحطة يقرآنه). المحفوظ غير الموجود بالقائمة ← الرئيسي ← الأول.
class ActiveBranchCubit extends Cubit<ActiveBranchState> {
  ActiveBranchCubit(this._repo, this._prefs) : super(const ActiveBranchState());

  final StationRepository _repo;
  final SharedPreferences _prefs;

  static const storageKey = 'reception.branch_id';

  Future<void> load() async {
    emit(ActiveBranchState(branches: state.branches.toLoading(), selectedId: state.selectedId));
    final r = await _repo.branches();
    if (isClosed) return;
    final slice = state.branches.fromResult(r);
    final list = slice.data ?? const <StationBranch>[];
    final stored = _prefs.getInt(storageKey);
    final pick =
        list.where((b) => b.id == stored).firstOrNull ?? list.where((b) => b.isMain).firstOrNull ?? list.firstOrNull;
    emit(ActiveBranchState(branches: slice, selectedId: pick?.id ?? state.selectedId));
  }

  Future<void> select(int id) async {
    emit(ActiveBranchState(branches: state.branches, selectedId: id));
    await _prefs.setInt(storageKey, id);
  }
}
