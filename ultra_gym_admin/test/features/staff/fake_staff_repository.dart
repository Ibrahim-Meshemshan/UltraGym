import 'package:get_it/get_it.dart';
import 'package:ultra_gym_admin/core/core.dart';
import 'package:ultra_gym_admin/features/staff/data/repo/staff_repository.dart';
import 'package:ultra_gym_admin/features/staff/domain/models/staff_models.dart';
import 'package:ultra_gym_admin/features/staff/presentation/bloc/staff_cubits.dart';

/// حساب استقبال بشكل `MemberController::memberPayload` + `branches`.
Json receptionistJson({
  int id = 21,
  String name = 'رنا الخطيب',
  String status = 'active',
  bool mustChange = false,
  String? lastLogin = '2026-11-10T09:00:00Z',
  List<Json> branches = const [
    {'id': 1, 'name': 'الفرع الرئيسي'},
  ],
}) => {
  'id': id,
  'name': name,
  'phone': '+963933100002',
  'email': null,
  'role': 'receptionist',
  'roles': ['receptionist'],
  'status': status,
  'suspended_at': null,
  'suspension_reason': status == 'suspended' ? 'غياب' : null,
  'joined_at': '2026-10-01T09:00:00Z',
  'archived_at': null,
  'member_code': 'DMO-100002',
  'must_change_password': mustChange,
  'temporary_password_expires_at': null,
  'last_login_at': lastLogin,
  'branches': branches,
};

/// موظف بشكل `ClubPayloads::staffMember`.
Json staffJson({
  int id = 5,
  String name = 'كابتن سامر',
  String type = 'trainer',
  String commissionType = 'percent',
  num percent = 20,
  num fixed = 0,
  String status = 'active',
}) => {
  'id': id,
  'name': name,
  'phone': '+963944555666',
  'type': type,
  'job_title': type == 'trainer' ? 'مدرب حديد' : 'عامل نظافة',
  'branch': {'id': 1, 'name': 'الفرع الرئيسي'},
  'salary_currency': 'USD',
  'salary_amount': '300.00',
  'commission_type': commissionType,
  'commission_percent': percent,
  'commission_fixed_usd': fixed,
  'status': status,
  'hired_on': '2026-01-15',
  'notes': null,
  'open_advances_usd': 0,
  'created_at': '2026-01-15T09:00:00Z',
};

Json accountJson({
  int id = 21,
  String name = 'رنا الخطيب',
  String state = 'never_logged_in',
  String roleLabel = 'موظف استقبال',
  bool self = false,
  String? blocked,
  bool shared = false,
}) => {
  'id': id,
  'name': name,
  'phone': '+963933100002',
  'member_code': 'DMO-100002',
  'roles': ['receptionist'],
  'role_label': roleLabel,
  'is_owner': self,
  'is_self': self,
  'state': state,
  'state_label': switch (state) {
    'never_logged_in' => 'لم يدخل بعد',
    'expired' => 'كلمة مؤقتة منتهية',
    _ => 'فعّال',
  },
  'must_change_password': state == 'never_logged_in',
  'temporary_password_expires_at': null,
  'last_login_at': null,
  'blocked_reason': blocked,
  'shared_account': shared,
};

Json credentialJson({int id = 21, String name = 'رنا الخطيب'}) => {
  'user_id': id,
  'name': name,
  'role_label': 'موظف استقبال',
  'member_code': 'DMO-100002',
  'phone': '+963933100002',
  'temporary_password': 'Kx7-49QpL',
  'expires_at': '2026-11-18T09:00:00Z',
  'whatsapp_message': 'أهلاً $name',
};

Paged<T> paged<T>(List<T> items, {Json summary = const {}}) => Paged(
  items: items,
  pagination: Pagination(total: items.length, lastPage: 1, from: items.isEmpty ? 0 : 1, to: items.length),
  summary: summary,
);

class FakeStaffRepository implements StaffRepository {
  ApiResult<StaffUsage> usageResult = ApiSuccess(
    StaffUsage.fromJson({
      'usage': {
        'staff': {'used': 3, 'limit': 5},
      },
    }),
  );
  ApiResult<Paged<Receptionist>> receptionistsResult = ApiSuccess(
    paged([
      Receptionist.fromJson(receptionistJson()),
      Receptionist.fromJson(receptionistJson(id: 22, name: 'باسل حداد', status: 'suspended', lastLogin: null)),
    ]),
  );
  ApiResult<Paged<StaffMember>> staffResult = ApiSuccess(
    paged([
      StaffMember.fromJson(staffJson()),
      StaffMember.fromJson(staffJson(id: 6, name: 'أبو خالد', type: 'worker', percent: 0)),
    ]),
  );
  ApiResult<Paged<ClubAccount>> accountsResult = ApiSuccess(
    paged(
      [
        ClubAccount.fromJson(accountJson()),
        ClubAccount.fromJson(
          accountJson(id: 1, name: 'سامر الحلبي', state: 'active', roleLabel: 'مالك النادي', self: true, blocked: 'هذا حسابك'),
        ),
        ClubAccount.fromJson(accountJson(id: 40, name: 'عضو مشترك', state: 'active', roleLabel: 'لاعب', shared: true)),
      ],
      summary: {'total': 3, 'never_logged_in': 1, 'pending_change': 0, 'expired': 0, 'active': 2, 'suspended': 0},
    ),
  );
  ApiResult<ReceptionistCreated>? addResult;
  ApiResult<StaffMember>? saveStaffResult;
  ApiResult<void> actionResult = const ApiSuccess(null, message: 'تم.');
  ApiResult<ResetResult>? resetResult;

  final queries = <String, List<ListQuery>>{'reception': [], 'staff': [], 'accounts': []};
  final added = <({Json body, String? key})>[];
  final savedStaff = <({Json body, int? id, String? key})>[];
  final resets = <Json>[];
  final cards = <List<IssuedCredential>>[];

  /// كل فعل مفرد باسم المسار ومعرّفه ("suspend 21: غياب").
  final actions = <String>[];

  @override
  Future<ApiResult<StaffUsage>> usage() async => usageResult;

  @override
  Future<ApiResult<Paged<Receptionist>>> receptionists(ListQuery query) async {
    queries['reception']!.add(query);
    return receptionistsResult;
  }

  @override
  Future<ApiResult<ReceptionistCreated>> addReceptionist(Json body, {String? idempotencyKey}) async {
    added.add((body: body, key: idempotencyKey));
    return addResult ??
        ApiSuccess(
          ReceptionistCreated.fromJson({
            ...receptionistJson(id: 30, name: body['name'] as String),
            'is_existing_account': false,
            'temporary_password': 'Tmp-55aa',
            'temporary_password_expires_at': '2026-11-18T09:00:00Z',
            'whatsapp_message': 'مرحباً',
          }),
        );
  }

  @override
  Future<ApiResult<Receptionist>> updateReceptionist(int id, Json body) async {
    actions.add('update $id: ${body['name']} ${body['email']}');
    return ApiSuccess(Receptionist.fromJson({...receptionistJson(id: id), ...body}));
  }

  @override
  Future<ApiResult<void>> setReceptionistBranches(int id, List<int> branchIds) async {
    actions.add('branches $id: $branchIds');
    return actionResult;
  }

  @override
  Future<ApiResult<void>> suspendReceptionist(int id, String reason) async {
    actions.add('suspend $id: $reason');
    return actionResult;
  }

  @override
  Future<ApiResult<void>> activateReceptionist(int id) async => _act('activate $id');

  @override
  Future<ApiResult<void>> archiveReceptionist(int id) async => _act('archive $id');

  @override
  Future<ApiResult<void>> restoreReceptionist(int id) async => _act('restore $id');

  @override
  Future<ApiResult<Paged<StaffMember>>> staffMembers(ListQuery query) async {
    queries['staff']!.add(query);
    return staffResult;
  }

  @override
  Future<ApiResult<StaffMember>> saveStaffMember(Json body, {int? id, String? idempotencyKey}) async {
    savedStaff.add((body: body, id: id, key: idempotencyKey));
    return saveStaffResult ?? ApiSuccess(StaffMember.fromJson({...staffJson(id: id ?? 50), ...body}));
  }

  @override
  Future<ApiResult<void>> archiveStaffMember(int id) async => _act('archive staff $id');

  @override
  Future<ApiResult<void>> restoreStaffMember(int id) async => _act('restore staff $id');

  @override
  Future<ApiResult<Paged<ClubAccount>>> accounts(ListQuery query) async {
    queries['accounts']!.add(query);
    return accountsResult;
  }

  @override
  Future<ApiResult<ResetResult>> resetPasswords(Json body) async {
    resets.add(body);
    return resetResult ??
        ApiSuccess(
          ResetResult.fromJson({
            'credentials': [credentialJson()],
            'skipped': [
              {'user_id': 1, 'name': 'سامر الحلبي', 'reason': 'حساب المالك تديره المنصة'},
            ],
          }).withMessage('تمت إعادة تعيين كلمة السر لـ 1 حساب'),
          message: 'تمت إعادة تعيين كلمة السر لـ 1 حساب',
        );
  }

  @override
  Future<ApiResult<FileBlob>> cardsPdf(List<IssuedCredential> credentials) async {
    cards.add(credentials);
    return const ApiFailure(_noPrint);
  }

  @override
  Future<ApiResult<void>> regenerateCode(int userId) async => _act('code $userId');

  @override
  Future<ApiResult<void>> endSessions(int userId) async => _act('sessions $userId');

  ApiResult<void> _act(String what) {
    actions.add(what);
    return actionResult;
  }
}

/// الطباعة تفتح نافذة متصفح غير متاحة بالاختبار: الفشل يكفي لإثبات أن الطلب أُرسل.
const _noPrint = Failure(type: FailureType.server, message: 'لا طباعة بالاختبار');

/// تسجيلات قسم الموظفين بـ GetIt (الهارنس).
void registerStaffFakes(FakeStaffRepository repo) {
  GetIt.instance
    ..registerSingleton<StaffRepository>(repo)
    ..registerFactory(() => StaffUsageCubit(repo))
    ..registerFactory(() => ReceptionistsCubit(repo))
    ..registerFactory(() => StaffMembersCubit(repo))
    ..registerFactory(() => AccountsCubit(repo));
}
