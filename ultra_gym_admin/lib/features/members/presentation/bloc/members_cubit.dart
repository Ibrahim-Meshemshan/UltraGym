import '../../../../core/core.dart';
import '../../data/repo/members_repository.dart';
import '../../domain/models/member_models.dart';

/// معاملات إنشاء قائمة تبويب: التبويب + فرع الشريط العلوي + فلتر أولي (من رابط الصفحة).
typedef MembersArgs = ({MembersTab tab, int? branchId, ListQuery query});

/// قائمة تبويب واحد (الأعضاء أو الأرشيف) بفرع الشريط العلوي. تغيير التبويب أو الفرع ينشئ واحدة جديدة.
/// العمليات ترجع النتيجة للنافذة (`FormDialog`)، والشاشة تحدّث بعدها بصمت.
class MembersListCubit extends ListCubit<MemberRow> {
  MembersListCubit(this._repo, MembersArgs args)
    : tab = args.tab,
      super(
        (q) => _repo.list(q, tab: args.tab, branchId: args.branchId),
        query: args.query,
      );

  final MembersRepository _repo;
  final MembersTab tab;

  Future<ApiResult<NewMember>> create(Json body, {required String idempotencyKey}) =>
      _repo.create(body, idempotencyKey: idempotencyKey);

  Future<ApiResult<void>> archive(int id) => _repo.archive(id);

  Future<ApiResult<void>> restore(int id) => _repo.restore(id);
}

/// عدّادا التبويبين. فشلهما لا يوقف الجدول: التبويب يظهر بلا عدد.
class MemberCountsCubit extends LoadCubit<MemberCounts> {
  MemberCountsCubit(MembersRepository repo, {int? branchId}) : super(() => repo.counts(branchId: branchId));
}

/// الفلتر الأولي من رابط الصفحة (البحث الشامل، التنبيهات، روابط الرئيسية):
/// `/members?membership_status=expired&has_debt=1&gender=female&search=أحمد`.
ListQuery membersQueryFrom(Map<String, String> params) {
  var q = const ListQuery();
  final status = params[MemberFilters.membershipStatus];
  if (MemberFilters.statuses.any((o) => o.value == status)) q = q.withFilter(MemberFilters.membershipStatus, status);
  final gender = params[MemberFilters.gender];
  if (MemberFilters.genders.any((o) => o.value == gender)) q = q.withFilter(MemberFilters.gender, gender);
  if (params[MemberFilters.hasDebt] case '1' || 'true') q = q.withFilter(MemberFilters.hasDebt, true);
  if (int.tryParse(params[MemberFilters.branchId] ?? '') case final id?) q = q.withFilter(MemberFilters.branchId, id);
  if (params['search'] case final s? when s.trim().isNotEmpty) q = q.withSearch(s.trim());
  return q;
}
