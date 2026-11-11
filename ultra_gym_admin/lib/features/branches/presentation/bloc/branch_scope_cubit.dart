import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/core.dart';
import '../../data/repo/branches_repository.dart';
import '../../domain/models/branch_models.dart';

/// الفرع الحالي للوحة: يعيش بعمر الهيكل (من الدخول للخروج) ويقرؤه كل قسم تحته بـ
/// `context.read<BranchScopeCubit>().state.branchId` ليرسله مع طلباته.
/// فرع واحد ← مختار تلقائياً. أكثر ← آخر اختيار محفوظ للمستخدم بهذا النادي، وإلا "كل الفروع" (null).
class BranchScopeCubit extends Cubit<BranchScope> {
  BranchScopeCubit(this._repo, this._prefs, {required this.storageKey}) : super(const BranchScope());

  final BranchesRepository _repo;
  final SharedPreferences _prefs;

  /// مفتاح الحفظ لكل مستخدم ونادٍ: `branch.<tenant>.<user>`.
  final String storageKey;

  static String keyFor({required int? tenantId, required int userId}) => 'branch.${tenantId ?? 0}.$userId';

  Future<void> load() async {
    emit(state.copyWith(branches: state.branches.toLoading()));
    final r = await _repo.list();
    if (isClosed) return;
    emit(_settle(state.branches.fromResult(r)));
  }

  /// تحديث صامت (بعد فتح أو إغلاق وردية مثلاً): الخطأ لا يمحو البيانات.
  Future<void> refresh() async {
    final r = await _repo.list();
    if (isClosed) return;
    if (r is ApiFailure<List<Branch>> && state.branches.hasData) return;
    emit(_settle(state.branches.fromResult(r)));
  }

  /// null = كل الفروع.
  Future<void> select(int? id) async {
    if (id == state.selectedId) return;
    emit(state.copyWith(selectedId: () => id));
    id == null ? await _prefs.remove(storageKey) : await _prefs.setInt(storageKey, id);
  }

  BranchScope _settle(Slice<List<Branch>> branches) {
    final next = state.copyWith(branches: branches);
    final active = next.active;
    if (active.length == 1) return next.copyWith(selectedId: () => active.first.id);
    final wanted = state.selectedId ?? _prefs.getInt(storageKey);
    final valid = active.any((b) => b.id == wanted);
    return next.copyWith(selectedId: () => valid ? wanted : null);
  }
}

class BranchScope extends Equatable {
  const BranchScope({this.branches = const Slice(), this.selectedId});

  final Slice<List<Branch>> branches;

  /// الفرع المختار، أو null = كل الفروع.
  final int? selectedId;

  /// الفروع الفعّالة (الموقوفة لا تقبل عمليات: `BRANCH_INACTIVE`).
  List<Branch> get active => [
    for (final b in branches.data ?? const <Branch>[])
      if (b.isActive) b,
  ];

  bool get isSingle => active.length == 1;

  /// الاختيار متاح فقط بأكثر من فرع.
  bool get canChoose => active.length > 1;

  Branch? get selected {
    for (final b in active) {
      if (b.id == selectedId) return b;
    }
    return null;
  }

  /// `branch_id` للطلبات: المختار (أو الوحيد). null = كل الفروع (القوائم بلا فلتر، والعمليات تسأل عن الفرع).
  int? get branchId => selected?.id;

  /// عدد الفروع التي فيها وردية مفتوحة الآن.
  int get openCashCount => active.where((b) => b.cashSessionOpen).length;

  /// الفرع الرئيسي من الفعّالة (أو أولها): لما يحتاج فرعاً واحداً والشريط على "كل الفروع" (أرقام اليوم، السعر).
  int? get mainId => (active.where((b) => b.isMain).firstOrNull ?? active.firstOrNull)?.id;

  BranchScope copyWith({Slice<List<Branch>>? branches, int? Function()? selectedId}) =>
      BranchScope(branches: branches ?? this.branches, selectedId: selectedId == null ? this.selectedId : selectedId());

  @override
  List<Object?> get props => [branches, selectedId];
}
