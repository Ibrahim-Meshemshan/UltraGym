import 'package:flutter/widgets.dart';
import 'package:ultra_gym_reception/core/error/failure.dart';
import 'package:ultra_gym_reception/core/networking/api_result.dart';
import 'package:ultra_gym_reception/core/utils/json_x.dart';
import 'package:ultra_gym_reception/features/station/data/datasources/station_remote_datasource.dart';
import 'package:ultra_gym_reception/features/station/data/repo/station_repository.dart';
import 'package:ultra_gym_reception/features/station/domain/models/check_in_models.dart';
import 'package:ultra_gym_reception/features/station/domain/models/station_models.dart';
import 'package:ultra_gym_reception/features/station/presentation/widgets/qr_scan_dialog.dart';

/// أشكال الردود كما التُقطت من الخادم الحي (2026-11-11، النادي التجريبي).
Json branchJson({int id = 1, String name = 'ماستر', bool main = true, bool split = true}) => {
  'id': id,
  'name': name,
  'is_main': main,
  'status': 'active',
  'gender_policy': split ? 'time_split' : 'mixed',
  'gender_schedule': split
      ? [
          {
            'days': ['saturday', 'sunday', 'monday', 'tuesday', 'wednesday', 'thursday'],
            'from': '12:00',
            'to': '17:00',
            'gender': 'female',
            'gender_label': 'إناث',
          },
          {
            'days': ['saturday', 'sunday', 'monday', 'tuesday', 'wednesday', 'thursday'],
            'from': '17:30',
            'to': '00:00',
            'gender': 'male',
            'gender_label': 'ذكور',
          },
        ]
      : [],
};

Json membershipJson({String status = 'active', String label = 'فعّال', double due = 0, String type = 'duration'}) => {
  'id': 3,
  'plan': {'id': 4, 'name': 'تدريب خاص شهري'},
  'type': type,
  'starts_on': '2026-10-25',
  'ends_on': '2026-11-23',
  'days_remaining': 13,
  'sessions_remaining': type == 'sessions' ? 4 : null,
  'status': status,
  'status_label': label,
  'frozen_until': null,
  'due_usd': due,
};

Json recordJson({int id = 44, String status = 'accepted', String method = 'qr', String? reason, String? message}) => {
  'id': id,
  'player': status == 'rejected' ? {'id': 7, 'name': 'رامي العمر'} : {'id': 3, 'name': 'أحمد الخطيب'},
  'branch': {'id': 1, 'name': 'ماستر'},
  'membership_id': 3,
  'checked_in_at': '2026-11-11T14:31:59Z',
  'business_date': '2026-11-11',
  'method': method,
  'status': status,
  'rejection_reason': reason,
  'rejection_message': message,
  'in_grace': false,
  'is_offline': false,
};

Json checkInJson({bool duplicate = false, Json? record, Json? membership}) => {
  'record': record ?? recordJson(),
  'player': {
    'id': 3,
    'name': 'أحمد الخطيب',
    'phone': '+963944100001',
    'member_code': 'DMO-098969',
    'membership': membership ?? membershipJson(),
  },
  'duplicate': duplicate,
  'session_consumption': null,
};

Json lookupJson({int id = 3, String name = 'أحمد الخطيب', bool canEnter = true, String? message}) => {
  'id': id,
  'name': name,
  'phone': '+963944100001',
  'member_code': 'DMO-098969',
  'membership': membershipJson(),
  'can_enter': canEnter,
  'rejection_reason': canEnter ? null : 'BRANCH_NOT_ALLOWED',
  'rejection_message': message,
};

final accepted = ApiSuccess(CheckInResult.fromJson(checkInJson(), message: 'تم تسجيل الدخول'));

/// الرفض كما يحوّله المصدر الحقيقي (409 + السجل ← نتيجة).
final rejected = StationRemoteDataSource.checkInResultOf(
  ApiFailure(
    Failure(
      type: FailureType.conflict,
      statusCode: 409,
      code: 'BRANCH_NOT_ALLOWED',
      message: 'اشتراك اللاعب لا يشمل هذا الفرع',
      data: checkInJson(
        record: recordJson(id: 45, status: 'rejected', method: 'code', reason: 'BRANCH_NOT_ALLOWED', message: 'اشتراك اللاعب لا يشمل هذا الفرع'),
      ),
    ),
  ),
);

const qrExpired = ApiFailure<CheckInResult>(
  Failure(type: FailureType.validation, statusCode: 422, code: 'QR_EXPIRED', message: 'رمز QR منتهي الصلاحية، اطلب من اللاعب تحديثه'),
);

const networkDown = ApiFailure<CheckInResult>(Failure(type: FailureType.network, message: 'لا يوجد اتصال بالإنترنت.'));

TodaySummary todayOf(List<Json> latest, {int accepted = 1, int rejected = 1}) =>
    TodaySummary.fromJson({'accepted': accepted, 'rejected': rejected, 'in_grace': 0, 'latest': latest});

class FakeStationRepository implements StationRepository {
  ApiResult<List<StationBranch>> branchesResult = ApiSuccess([StationBranch.fromJson(branchJson())]);
  ApiResult<TodaySummary> todayResult = ApiSuccess(
    todayOf([
      recordJson(id: 45, status: 'rejected', method: 'code', reason: 'BRANCH_NOT_ALLOWED', message: 'اشتراك اللاعب لا يشمل هذا الفرع'),
      recordJson(),
    ]),
  );
  ApiResult<List<LookupPlayer>> lookupResult = ApiSuccess([
    LookupPlayer.fromJson(lookupJson()),
    LookupPlayer.fromJson(lookupJson(id: 7, name: 'رامي العمر', canEnter: false, message: 'اشتراك اللاعب لا يشمل هذا الفرع')),
  ]);
  final checkInResults = <ApiResult<CheckInResult>>[];

  final todayCalls = <int>[];
  final lookups = <({String q, int branch})>[];
  final checkIns = <({Json body, String key})>[];

  @override
  Future<ApiResult<List<StationBranch>>> branches() async => branchesResult;

  @override
  Future<ApiResult<TodaySummary>> today(int branchId) async {
    todayCalls.add(branchId);
    return todayResult;
  }

  @override
  Future<ApiResult<List<LookupPlayer>>> lookup(String q, int branchId) async {
    lookups.add((q: q, branch: branchId));
    return lookupResult;
  }

  @override
  Future<ApiResult<CheckInResult>> checkIn(Json body, {required String idempotencyKey}) async {
    checkIns.add((body: body, key: idempotencyKey));
    return checkInResults.isEmpty ? accepted : checkInResults.removeAt(0);
  }
}

/// الكاميرا بالاختبار: ترجع ما يحدده الاختبار مباشرة.
class FakeQrScanner implements QrScanner {
  String? next;
  var opened = 0;

  @override
  Future<String?> scan(BuildContext context) async {
    opened++;
    return next;
  }
}
