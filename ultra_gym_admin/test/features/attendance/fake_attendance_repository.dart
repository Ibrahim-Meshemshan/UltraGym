import 'package:ultra_gym_admin/core/error/failure.dart';
import 'package:ultra_gym_admin/core/networking/api_result.dart';
import 'package:ultra_gym_admin/core/networking/list_query.dart';
import 'package:ultra_gym_admin/core/networking/paged.dart';
import 'package:ultra_gym_admin/core/utils/json_x.dart';
import 'package:ultra_gym_admin/features/attendance/data/datasources/attendance_remote_datasource.dart';
import 'package:ultra_gym_admin/features/attendance/data/repo/attendance_repository.dart';
import 'package:ultra_gym_admin/features/attendance/domain/models/attendance_models.dart';
import 'package:ultra_gym_admin/features/attendance/presentation/widgets/qr_scan_dialog.dart';
import 'package:flutter/widgets.dart';

/// ردود حقيقية من الخادم التجريبي (2026-11-09): `GET attendance?per_page=3`.
final attendanceJson = <Json>[
  {
    'id': 39,
    'player': {'id': 3, 'name': 'أحمد الخطيب'},
    'branch': {'id': 1, 'name': 'الفرع الرئيسي - المزة'},
    'membership_id': 3,
    'checked_in_at': '2026-11-08T11:58:43Z',
    'business_date': '2026-11-08',
    'method': 'manual',
    'status': 'accepted',
    'rejection_reason': null,
    'rejection_message': null,
    'in_grace': false,
    'is_offline': false,
    'recorded_by': {'id': 1, 'name': 'سامر الحلبي'},
  },
  {
    'id': 37,
    'player': {'id': 12, 'name': 'يزن الأحمد'},
    'branch': {'id': 1, 'name': 'الفرع الرئيسي - المزة'},
    'membership_id': 10,
    'checked_in_at': '2026-11-07T16:10:00Z',
    'business_date': '2026-11-07',
    'method': 'qr',
    'status': 'accepted',
    'rejection_reason': null,
    'rejection_message': null,
    'in_grace': true,
    'is_offline': true,
    'recorded_by': null,
  },
  {
    'id': 38,
    'player': {'id': 7, 'name': 'رامي العمر'},
    'branch': {'id': 1, 'name': 'الفرع الرئيسي - المزة'},
    'membership_id': 1,
    'checked_in_at': '2026-11-07T16:00:00Z',
    'business_date': '2026-11-07',
    'method': 'manual',
    'status': 'rejected',
    'rejection_reason': 'EXPIRED',
    'rejection_message': 'اشتراك اللاعب منتهٍ',
    'in_grace': false,
    'is_offline': false,
    'recorded_by': {'id': 1, 'name': 'سامر الحلبي'},
  },
];

/// `GET attendance/today?branch_id=1` (الأرقام من العقد؛ الخادم التجريبي بلا دخول اليوم).
final todayJson = <String, Object?>{
  'branch': {'id': 1, 'name': 'الفرع الرئيسي - المزة'},
  'business_date': '2026-11-09',
  'accepted': 12,
  'rejected': 2,
  'in_grace': 1,
  'day_passes': 0,
  'visitors': 0,
  'sessions_consumed': 3,
  'by_hour': [
    {'hour': 9, 'count': 2},
    {'hour': 18, 'count': 7},
    {'hour': 0, 'count': 3},
  ],
  'latest': <Json>[],
};

Json membershipCardJson({String status = 'active', double due = 0}) => {
  'id': 14,
  'plan': {'id': 1, 'name': 'شهري - كل الفروع'},
  'type': 'duration',
  'starts_on': '2026-11-09',
  'ends_on': '2026-12-08',
  'days_remaining': 30,
  'sessions_remaining': null,
  'status': status,
  'status_label': status == 'expired' ? 'منتهٍ' : 'فعّال',
  'due_usd': due,
};

/// جسم `check-in` (مقبول، مكرر، أو مرفوض) بشكل العقد لعضو الاختبار 15.
Json checkInJson({String status = 'accepted', bool duplicate = false, String? reason, Json? membership}) => {
  'record': {
    'id': 40,
    'player': {'id': 15, 'name': 'عضو تجريبي'},
    'branch': {'id': 1, 'name': 'الفرع الرئيسي - المزة'},
    'membership_id': membership?['id'],
    'checked_in_at': '2026-11-09T18:30:00Z',
    'business_date': '2026-11-09',
    'method': 'code',
    'status': status,
    'rejection_reason': reason,
    'rejection_message': reason == null ? null : 'لا يوجد اشتراك للاعب',
    'in_grace': false,
    'is_offline': false,
    'recorded_by': {'id': 1, 'name': 'سامر الحلبي'},
  },
  'player': {
    'id': 15,
    'name': 'عضو تجريبي',
    'phone': '+963944999001',
    'member_code': 'DMO-873152',
    'membership': membership,
  },
  'duplicate': duplicate,
  'session_consumption': null,
};

final accepted = ApiSuccess(
  CheckInResult.fromJson(checkInJson(membership: membershipCardJson(due: 17.5)), message: 'تم تسجيل الدخول'),
  message: 'تم تسجيل الدخول',
);

final rejectedNoMembership = AttendanceRemoteDataSource.checkInResultOf(
  ApiFailure(
    Failure(
      type: FailureType.conflict,
      statusCode: 409,
      code: 'NO_MEMBERSHIP',
      message: 'لا يوجد اشتراك للاعب',
      data: checkInJson(status: 'rejected', reason: 'NO_MEMBERSHIP'),
    ),
  ),
);

class FakeAttendanceRepository implements AttendanceRepository {
  ApiResult<Paged<AttendanceRow>> listResult = ApiSuccess(
    Paged(
      items: [for (final j in attendanceJson) AttendanceRow.fromJson(j)],
      pagination: const Pagination(total: 3, lastPage: 1, perPage: 15, currentPage: 1),
      meta: const {
        'period': {'from': '2026-10-10', 'to': null, 'is_default': true},
      },
    ),
  );
  ApiResult<AttendanceToday> todayResult = ApiSuccess(AttendanceToday.fromJson(todayJson));
  ApiResult<CheckInResult> checkInResult = accepted;

  final queries = <({ListQuery query, int? branchId})>[];
  final todayCalls = <int?>[];
  final checkIns = <({Json body, String key})>[];

  @override
  Future<ApiResult<Paged<AttendanceRow>>> list(ListQuery query, {int? branchId}) async {
    queries.add((query: query, branchId: branchId));
    return listResult;
  }

  @override
  Future<ApiResult<AttendanceToday>> today({int? branchId}) async {
    todayCalls.add(branchId);
    return todayResult;
  }

  @override
  Future<ApiResult<CheckInResult>> checkIn(Json body, {required String idempotencyKey}) async {
    checkIns.add((body: body, key: idempotencyKey));
    return checkInResult;
  }
}

/// بديل الكاميرا: يرجع `next` (null = ألغى الموظف) ويعدّ مرات الفتح.
class FakeQrScanner implements QrScanner {
  String? next;
  int scans = 0;

  @override
  Future<String?> scan(BuildContext context) async {
    scans++;
    return next;
  }
}
