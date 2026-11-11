import '../../../../core/core.dart';
import '../../../quick_search/domain/models/quick_search_models.dart';
import '../../data/repo/attendance_repository.dart';
import '../../domain/models/attendance_models.dart';

/// معاملات السجل: فرع الشريط العلوي + فلتر أولي من الرابط.
typedef AttendanceArgs = ({int? branchId, ListQuery query});

/// سجل الحضور بفرع الشريط العلوي. تغيير الفرع ينشئ واحداً جديداً.
class AttendanceListCubit extends ListCubit<AttendanceRow> {
  AttendanceListCubit(AttendanceRepository repo, AttendanceArgs args)
    : super((q) => repo.list(q, branchId: args.branchId), query: args.query);
}

/// أرقام اليوم والدخول حسب الساعة لفرع واحد (الخادم يحتاج فرعاً). فشلها لا يوقف السجل.
class AttendanceTodayCubit extends LoadCubit<AttendanceToday> {
  AttendanceTodayCubit(AttendanceRepository repo, {int? branchId}) : super(() => repo.today(branchId: branchId));
}

/// الفلتر الأولي من الرابط: `/attendance?status=rejected&method=qr&from=2026-11-01&to=2026-11-09&branch_id=2&search=…`.
ListQuery attendanceQueryFrom(Map<String, String> params) {
  var q = const ListQuery();
  for (final (key, options) in const [
    (AttendanceFilters.status, AttendanceFilters.statuses),
    (AttendanceFilters.method, AttendanceFilters.methods),
  ]) {
    final v = params[key];
    if (options.any((o) => o.value == v)) q = q.withFilter(key, v);
  }
  for (final key in const [AttendanceFilters.from, AttendanceFilters.to]) {
    if (DateTime.tryParse(params[key] ?? '') case final d?) q = q.withFilter(key, DateTime(d.year, d.month, d.day));
  }
  if (int.tryParse(params[AttendanceFilters.branchId] ?? '') case final id?) {
    q = q.withFilter(AttendanceFilters.branchId, id);
  }
  if (params['search'] case final s? when s.trim().isNotEmpty) q = q.withSearch(s.trim());
  return q;
}

/// حالة نافذة تسجيل الدخول: العضو المختار من البحث (وإلا يُكتب معرّفه)، والنتيجة الأخيرة.
class CheckInState extends Equatable {
  const CheckInState({this.player, this.result, this.recorded = false});

  final LookupPlayer? player;
  final CheckInResult? result;

  /// سُجّل شيء (مقبول أو مرفوض) خلال النافذة: الشاشة تحدّث السجل والأرقام بعد إغلاقها.
  final bool recorded;

  @override
  List<Object?> get props => [player, result, recorded];
}

/// تسجيل دخول يدوي: كل محاولة بمفتاح منع تكرار، و "تسجيل آخر" يبدأ من جديد بمفتاح جديد.
class CheckInCubit extends Cubit<CheckInState> {
  CheckInCubit({LookupPlayer? player}) : super(CheckInState(player: player));

  IdempotencyKeeper _keeper = IdempotencyKeeper();

  String keyFor(Json body) => _keeper.keyFor(body);

  void pick(LookupPlayer player) => emit(CheckInState(player: player, recorded: state.recorded));

  void clearPlayer() => emit(CheckInState(recorded: state.recorded));

  void show(CheckInResult result) => emit(
    CheckInState(
      player: state.player,
      result: result,
      recorded: state.recorded || result.kind != CheckInKind.duplicate,
    ),
  );

  void again() {
    _keeper = IdempotencyKeeper();
    emit(CheckInState(recorded: state.recorded));
  }
}
