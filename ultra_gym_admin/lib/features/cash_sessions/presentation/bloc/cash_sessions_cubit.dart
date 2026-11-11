import '../../../../core/core.dart';
import '../../data/repo/cash_sessions_repository.dart';
import '../../domain/models/cash_session_models.dart';

/// صندوق فرع الآن: `current` ثم، إن وُجدت وردية مفتوحة، تفاصيلها لأسطر "حسب النوع".
/// فشل التفاصيل لا يُسقط البطاقة: تبقى الأرصدة الحية بلا التفصيل.
class CashBoxCubit extends LoadCubit<CashBox> {
  CashBoxCubit(CashSessionsRepository repo, int branchId) : super(() => _fetch(repo, branchId));

  static Future<ApiResult<CashBox>> _fetch(CashSessionsRepository repo, int branchId) async {
    final r = await repo.current(branchId: branchId);
    if (r case ApiSuccess(data: final box) when box.session != null) {
      if (await repo.detail(box.session!.id) case ApiSuccess(:final data)) return ApiSuccess(box.withSession(data));
    }
    return r;
  }
}

/// معاملات "الورديات السابقة": فرع الشريط العلوي + فلتر أولي من الرابط.
typedef CashHistoryArgs = ({int? branchId, ListQuery query});

/// الورديات المغلقة (الأحدث أولاً من الخادم)، بفرع الشريط. تغيير الفرع ينشئ واحداً جديداً.
class CashHistoryCubit extends ListCubit<CashSession> {
  CashHistoryCubit(CashSessionsRepository repo, CashHistoryArgs args)
    : super(
        (q) => repo.list(q, branchId: args.branchId, status: 'closed'),
        query: args.query,
      );
}

/// تفاصيل وردية `/cash-sessions/{id}` (روابط الإشعارات وصفوف السجل).
class CashSessionDetailCubit extends LoadCubit<CashSession> {
  CashSessionDetailCubit(CashSessionsRepository repo, int id) : super(() => repo.detail(id));
}

/// الفلتر الأولي من الرابط: `/cash-sessions?from=…&to=…&branch_id=2&with_difference=1`.
ListQuery cashHistoryQueryFrom(Map<String, String> params) {
  var q = const ListQuery();
  for (final key in const [CashSessionFilters.from, CashSessionFilters.to]) {
    if (DateTime.tryParse(params[key] ?? '') case final d?) q = q.withFilter(key, DateTime(d.year, d.month, d.day));
  }
  if (int.tryParse(params[CashSessionFilters.branchId] ?? '') case final id?) {
    q = q.withFilter(CashSessionFilters.branchId, id);
  }
  if (const ['1', 'true'].contains(params[CashSessionFilters.withDifference])) {
    q = q.withFilter(CashSessionFilters.withDifference, true);
  }
  return q;
}
