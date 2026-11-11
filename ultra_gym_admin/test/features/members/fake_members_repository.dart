import 'package:ultra_gym_admin/core/networking/api_result.dart';
import 'package:ultra_gym_admin/core/networking/list_query.dart';
import 'package:ultra_gym_admin/core/networking/paged.dart';
import 'package:ultra_gym_admin/core/utils/json_x.dart';
import 'package:ultra_gym_admin/features/members/data/repo/members_repository.dart';
import 'package:ultra_gym_admin/features/members/domain/models/member_models.dart';

/// صف حقيقي من `GET club-admin/players` (الخادم التجريبي، 2026-11-09).
final Json ahmadJson = {
  'id': 3,
  'name': 'أحمد الخطيب',
  'phone': '+963944100001',
  'member_code': 'DMO-098969',
  'status': 'active',
  'branch': {'id': 1, 'name': 'الفرع الرئيسي - المزة'},
  'gender': 'male',
  'photo_url': null,
  'current_membership': {
    'id': 3,
    'plan': {'id': 4, 'name': 'تدريب خاص شهري'},
    'type': 'duration',
    'starts_on': '2026-10-25',
    'ends_on': '2026-11-23',
    'days_remaining': 15,
    'sessions_remaining': null,
    'status': 'active',
    'status_label': 'فعّال',
    'frozen_until': null,
  },
  'due_usd': 20,
};

final ahmad = MemberRow.fromJson(ahmadJson);

const omar = MemberRow(
  id: 5,
  name: 'عمر الحسن',
  phone: '+963944100003',
  memberCode: 'DMO-555001',
  status: 'suspended',
  branchName: 'فرع المالكي',
  membership: CurrentMembership(id: 5, planName: '3 أشهر', status: 'frozen', statusLabel: 'مجمّد', frozenUntil: null),
);

const hiba = MemberRow(id: 11, name: 'هبة سليمان', phone: '+963944100011', memberCode: 'DMO-111111');

Paged<MemberRow> page(List<MemberRow> items, {int total = 3, int current = 1, int last = 1}) => Paged(
  items: items,
  pagination: Pagination(
    currentPage: current,
    perPage: 15,
    total: total,
    lastPage: last,
    from: items.isEmpty ? null : (current - 1) * 15 + 1,
    to: items.isEmpty ? null : (current - 1) * 15 + items.length,
  ),
);

final firstPage = page([ahmad, omar, hiba]);

final _expires = DateTime.utc(2026, 11, 16, 10);

final newMember = NewMember(
  id: 20,
  name: 'سامي حداد',
  phone: '+963944200200',
  memberCode: 'DMO-200200',
  temporaryPassword: '482913',
  // 10:00 UTC = نفس اليوم بتوقيت النادي (2026-11-16)
  passwordExpiresAt: _expires,
  whatsappMessage: 'أهلاً سامي، كلمة السر المؤقتة: 482913',
);

typedef ListCall = ({MembersTab tab, int? branchId, Json params});

class FakeMembersRepository implements MembersRepository {
  FakeMembersRepository({ApiResult<Paged<MemberRow>>? list, ApiResult<Paged<MemberRow>>? archive})
    : listResult = list ?? ApiSuccess(firstPage),
      archiveResult = archive ?? ApiSuccess(page(const [], total: 0));

  ApiResult<Paged<MemberRow>> listResult, archiveResult;
  ApiResult<MemberCounts> countsResult = const ApiSuccess(MemberCounts(members: 12, archived: 2));
  ApiResult<NewMember> createResult = ApiSuccess(newMember, message: 'تمت إضافة اللاعب بنجاح');
  ApiResult<void> archiveActionResult = const ApiSuccess(null, message: 'تمت أرشفة اللاعب');

  final listCalls = <ListCall>[];
  final countCalls = <int?>[];
  final created = <({Json body, String key})>[];
  final archived = <int>[];
  final restored = <int>[];

  @override
  Future<ApiResult<Paged<MemberRow>>> list(ListQuery query, {required MembersTab tab, int? branchId}) async {
    listCalls.add((tab: tab, branchId: branchId, params: query.toParams()));
    return tab == MembersTab.archive ? archiveResult : listResult;
  }

  @override
  Future<ApiResult<MemberCounts>> counts({int? branchId}) async {
    countCalls.add(branchId);
    return countsResult;
  }

  @override
  Future<ApiResult<NewMember>> create(Json body, {required String idempotencyKey}) async {
    created.add((body: body, key: idempotencyKey));
    return createResult;
  }

  @override
  Future<ApiResult<void>> archive(int id) async {
    archived.add(id);
    return archiveActionResult;
  }

  @override
  Future<ApiResult<void>> restore(int id) async {
    restored.add(id);
    return const ApiSuccess(null, message: 'تم استرجاع اللاعب');
  }
}
