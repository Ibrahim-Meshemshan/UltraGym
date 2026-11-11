import '../../../../core/core.dart';
import '../../data/repo/memberships_repository.dart';
import '../../domain/models/memberships_models.dart';

/// معاملات قائمة تبويب: التبويب + فرع الشريط العلوي + فلتر أولي.
typedef MembershipsArgs = ({MembershipsTab tab, int? branchId, ListQuery query});

/// قائمة تبويب واحد بفرع الشريط العلوي. تغيير التبويب أو الفرع ينشئ واحدة جديدة.
class MembershipsListCubit extends ListCubit<MembershipRow> {
  MembershipsListCubit(MembershipsRepository repo, MembershipsArgs args)
    : tab = args.tab,
      super(
        (q) => repo.list(q, tab: args.tab, branchId: args.branchId),
        query: args.query,
      );

  final MembershipsTab tab;
}

/// أرقام الرأس. فشلها لا يوقف الجدول: البطاقات تختفي وعدّادا التبويبين بلا أرقام.
class MembershipStatsCubit extends LoadCubit<MembershipStats> {
  MembershipStatsCubit(MembershipsRepository repo, {int? branchId}) : super(() => repo.stats(branchId: branchId));
}

/// خطط الاشتراك لفلتر "الخطة". فشلها يخفي الفلتر فقط.
class PlanOptionsCubit extends LoadCubit<List<PlanOption>> {
  PlanOptionsCubit(MembershipsRepository repo) : super(repo.plans);
}

/// التبويب والفلتر الأولي من رابط الصفحة. روابط الرئيسية: `?has_debt=1` ← الديون،
/// و `?expiring_within_days=7` ← القريبة. والباقي: `status`، `plan_id`، `branch_id`، `search`.
({MembershipsTab tab, ListQuery query}) membershipsArgsFrom(Map<String, String> params) {
  final tab = switch (params) {
    {'has_debt': '1' || 'true'} => MembershipsTab.debts,
    {'expiring_within_days': _} => MembershipsTab.expiring,
    _ => MembershipsTab.all,
  };
  var q = const ListQuery();
  final status = params[MembershipFilters.status];
  if (MembershipFilters.statuses.any((o) => o.value == status)) q = q.withFilter(MembershipFilters.status, status);
  for (final key in [MembershipFilters.planId, MembershipFilters.branchId]) {
    if (int.tryParse(params[key] ?? '') case final id?) q = q.withFilter(key, id);
  }
  if (params['search'] case final s? when s.trim().isNotEmpty) q = q.withSearch(s.trim());
  return (tab: tab, query: q);
}
