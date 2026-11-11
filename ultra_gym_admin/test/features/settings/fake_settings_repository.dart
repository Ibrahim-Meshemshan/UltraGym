import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:ultra_gym_admin/core/networking/api_result.dart';
import 'package:ultra_gym_admin/core/utils/json_x.dart';
import 'package:ultra_gym_admin/features/branches/domain/models/branch_models.dart';
import 'package:ultra_gym_admin/features/settings/data/repo/settings_repository.dart';
import 'package:ultra_gym_admin/features/settings/domain/models/branch_draft.dart';
import 'package:ultra_gym_admin/features/settings/domain/models/settings_models.dart';
import 'package:ultra_gym_admin/features/settings/presentation/bloc/settings_cubits.dart';

/// ملف النادي بشكل رد `GET club-admin/club` (من رد حقيقي بالنادي التجريبي).
Json clubJson({String? logo, int used = 2, int? limit = 10, Json settings = const {}}) => {
  'id': 1,
  'name': 'نادي الأبطال',
  'slug': 'demo',
  'logo_url': logo,
  'contact_email': 'info@demo.test',
  'contact_phone': '+963112223344',
  'city': 'دمشق',
  'address': 'المزة، شارع الجلاء',
  'status': 'active',
  'settings': {
    'timezone': 'Asia/Damascus',
    'week_start_day': 'saturday',
    'weekend_days': ['friday'],
    'business_day_ends_at_hour': 2,
    'membership_grace_days': 3,
    'default_max_freezes': 2,
    'default_max_freeze_days': 30,
    'duplicate_check_in_minutes': 120,
    'allow_partial_payment': true,
    'receipt_footer': 'شكراً لثقتكم',
    'expiry_reminders_enabled': true,
    'disabled_notifications': <String>[],
    'day_pass_enabled': true,
    'day_pass_price_usd': 5,
    'player_workouts_enabled': false,
    ...settings,
  },
  'usage': {
    'branches': {'used': used, 'limit': limit},
  },
};

/// أنواع الإشعارات بشكل `GET club-admin/club/notification-types`.
Json catalogJson() => {
  'types': [
    {'type': 'cash_session_closed', 'label': 'إغلاق وردية', 'description': 'عند إغلاق صندوق فرع', 'audience': 'owners'},
    {'type': 'membership_expiring', 'label': 'اشتراكات تنتهي قريباً', 'description': '', 'audience': 'staff'},
    {'type': 'membership_expiry_reminder', 'label': 'تذكير بانتهاء الاشتراك', 'description': '', 'audience': 'player'},
  ],
  'audiences': {'owners': 'المالك', 'staff': 'المالك والاستقبال', 'player': 'العضو'},
  'platform_types': [
    {'type': 'billing_invoice', 'label': 'فواتير المنصة'},
  ],
};

Json branchJson({
  int id = 1,
  String name = 'الفرع الرئيسي - المزة',
  bool main = true,
  String status = 'active',
  String policy = 'mixed',
  List<Json> schedule = const [],
  num? price,
}) => {
  'id': id,
  'name': name,
  'phone': '+963112223344',
  'city': 'دمشق',
  'address': 'المزة',
  'is_main': main,
  'status': status,
  'gender_policy': policy,
  'gender_schedule': schedule,
  'day_pass_price_usd': price,
  'cash_session_open': main,
};

const femaleMorning = {
  'days': ['saturday', 'monday', 'wednesday'],
  'from': '08:00',
  'to': '14:00',
  'gender': 'female',
  'days_label': 'السبت، الإثنين، الأربعاء',
  'gender_label': 'إناث',
};
const maleNight = {
  'days': ['saturday', 'monday', 'wednesday'],
  'from': '20:00',
  'to': '01:00',
  'gender': 'male',
  'days_label': 'السبت، الإثنين، الأربعاء',
  'gender_label': 'ذكور',
};

List<Branch> settingsBranches() => [
  Branch.fromJson(branchJson()),
  Branch.fromJson(
    branchJson(id: 2, name: 'فرع المالكي', main: false, policy: 'time_split', schedule: [femaleMorning, maleNight]),
  ),
];

class FakeSettingsRepository implements SettingsRepository {
  ApiResult<ClubProfile> clubResult = ApiSuccess(ClubProfile.fromJson(clubJson()));
  ApiResult<NotificationCatalog> catalogResult = ApiSuccess(NotificationCatalog.fromJson(catalogJson()));
  ApiResult<List<Branch>> branchesResult = ApiSuccess(settingsBranches());
  ApiResult<ClubProfile>? updateClubResult;
  ApiResult<ClubSettings>? updateSettingsResult;
  ApiResult<Branch>? saveBranchResult;
  ApiResult<Branch>? statusResult;
  ApiResult<void> archiveResult = const ApiSuccess(null);
  ApiResult<void> logoResult = const ApiSuccess(null);

  int clubCalls = 0, branchCalls = 0;
  final clubBodies = <Json>[];
  final settingsBodies = <Json>[];
  final savedBranches = <({Json body, int? id, String? key})>[];
  final statuses = <(int, String)>[];
  final archived = <int>[];
  int logoDeletes = 0;

  @override
  Future<ApiResult<ClubProfile>> club() async {
    clubCalls++;
    return clubResult;
  }

  @override
  Future<ApiResult<ClubProfile>> updateClub(Json body) async {
    clubBodies.add(body);
    return updateClubResult ?? ApiSuccess(ClubProfile.fromJson({...clubJson(), ...body}));
  }

  @override
  Future<ApiResult<ClubSettings>> updateSettings(Json body) async {
    settingsBodies.add(body);
    return updateSettingsResult ?? ApiSuccess(ClubSettings.fromJson(body));
  }

  @override
  Future<ApiResult<NotificationCatalog>> notificationTypes() async => catalogResult;

  @override
  Future<ApiResult<void>> uploadLogo(FormData form) async => logoResult;

  @override
  Future<ApiResult<void>> deleteLogo() async {
    logoDeletes++;
    return logoResult;
  }

  @override
  Future<ApiResult<List<Branch>>> branches() async {
    branchCalls++;
    return branchesResult;
  }

  @override
  Future<ApiResult<Branch>> saveBranch(Json body, {int? id, String? idempotencyKey}) async {
    savedBranches.add((body: body, id: id, key: idempotencyKey));
    return saveBranchResult ??
        ApiSuccess(
          Branch.fromJson({
            ...branchJson(id: id ?? 9, main: id == 1),
            ...body,
            'gender_schedule': body['gender_schedule'] ?? const [],
          }),
        );
  }

  @override
  Future<ApiResult<Branch>> setBranchStatus(int id, String status) async {
    statuses.add((id, status));
    return statusResult ?? ApiSuccess(Branch.fromJson(branchJson(id: id, main: false, status: status)));
  }

  @override
  Future<ApiResult<void>> archiveBranch(int id) async {
    archived.add(id);
    return archiveResult;
  }
}

/// تسجيلات قسم الإعدادات بـ GetIt (الهارنس).
void registerSettingsFakes(FakeSettingsRepository repo) {
  GetIt.instance
    ..registerSingleton<SettingsRepository>(repo)
    ..registerFactory(() => ClubCubit(repo))
    ..registerFactory(() => NotificationCatalogCubit(repo))
    ..registerFactory(() => SettingsBranchesCubit(repo))
    ..registerFactoryParam<BranchEditorCubit, BranchDraft, void>((d, _) => BranchEditorCubit(repo, d));
}
