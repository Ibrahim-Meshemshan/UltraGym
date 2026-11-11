import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_gym_admin/core/error/failure.dart';
import 'package:ultra_gym_admin/core/networking/api_result.dart';
import 'package:ultra_gym_admin/core/router/routes.dart';
import 'package:ultra_gym_admin/core/utils/json_x.dart';
import 'package:ultra_gym_admin/features/attendance/data/datasources/attendance_remote_datasource.dart';
import 'package:ultra_gym_admin/features/attendance/domain/models/attendance_models.dart';
import 'package:ultra_gym_admin/features/attendance/presentation/bloc/attendance_cubit.dart';
import 'package:ultra_gym_admin/features/attendance/presentation/widgets/check_in_result.dart';

import '../quick_search/fake_quick_search_repository.dart';
import 'fake_attendance_repository.dart';

void main() {
  group('attendance models', () {
    test('row from the real log: member, branch, method, result, offline, recorder', () {
      final rows = [for (final j in attendanceJson) AttendanceRow.fromJson(j)];
      expect(rows.first.playerId, 3);
      expect(rows.first.playerName, 'أحمد الخطيب');
      expect(rows.first.entry.methodLabel, 'يدوي');
      expect(rows.first.recordedBy, 'سامر الحلبي');
      expect(rows[1].isOffline, isTrue);
      expect(rows[1].entry.inGrace, isTrue);
      expect(rows[1].recordedBy, isNull);
      expect(rows[2].entry.rejectionReason, 'EXPIRED');
      expect(rows[2].entry.rejectionMessage, 'اشتراك اللاعب منتهٍ');
    });

    test('today: counts as sent, hours from 6 through 1 after midnight, peak hour', () {
      final t = AttendanceToday.fromJson(todayJson);
      expect((t.accepted, t.rejected, t.inGrace, t.sessionsConsumed), (12, 2, 1, 3));
      expect(t.branchName, 'الفرع الرئيسي - المزة');
      final hours = t.hours.map((h) => h.hour).toList();
      expect(hours.first, 6);
      expect(hours.sublist(hours.length - 2), [0, 1]);
      expect(t.hours.firstWhere((h) => h.hour == 0).count, 3);
      expect(t.peakHour, 18);
      expect(const AttendanceToday().peakHour, isNull);
    });

    test('an hour outside the day window is still shown, in day order', () {
      final t = AttendanceToday.fromJson({
        'by_hour': [
          {'hour': 3, 'count': 1},
        ],
      });
      expect(t.hours.last.hour, 3);
    });

    test('check-in: 201 accepted, 200 duplicate, 409 with record = rejected, other failures stay failures', () {
      final ok = accepted.data;
      expect(ok.kind, CheckInKind.accepted);
      expect(ok.memberCode, 'DMO-873152');
      expect(ok.membership?.dueUsd, 17.5);

      final dup = CheckInResult.fromJson(checkInJson(duplicate: true), message: 'مسجّل منذ دقيقة');
      expect(dup.kind, CheckInKind.duplicate);

      final rej = (rejectedNoMembership as ApiSuccess<CheckInResult>).data;
      expect(rej.kind, CheckInKind.rejected);
      expect(rej.code, 'NO_MEMBERSHIP');
      expect(rej.message, 'لا يوجد اشتراك للاعب');

      const notFound = Failure(type: FailureType.notFound, statusCode: 404, message: 'اللاعب غير موجود بهذا النادي');
      expect(AttendanceRemoteDataSource.checkInResultOf(const ApiFailure(notFound)).failureOrNull, notFound);
      const busy = Failure(
        type: FailureType.conflict,
        statusCode: 409,
        code: 'IDEMPOTENCY_IN_PROGRESS',
        message: 'انتظر',
      );
      expect(AttendanceRemoteDataSource.checkInResultOf(const ApiFailure(busy)), isA<ApiFailure<CheckInResult>>());
    });

    test('follow-up: sell for no or expired membership, open it for frozen, profile otherwise, pay a debt', () {
      CheckInResult rejected(String code, {Json? membership}) => CheckInResult.fromJson(
        checkInJson(status: 'rejected', reason: code, membership: membership),
        message: '',
        code: code,
      );
      expect(checkInFollowUp(rejected('NO_MEMBERSHIP'))?.route, Routes.sellTo(15));
      expect(
        checkInFollowUp(rejected('EXPIRED', membership: membershipCardJson(status: 'expired')))?.route,
        Routes.sellTo(15),
      );
      expect(
        checkInFollowUp(rejected('FROZEN', membership: membershipCardJson(status: 'frozen')))?.route,
        Routes.child(Routes.memberships, 14),
      );
      expect(checkInFollowUp(rejected('GENDER_UNKNOWN'))?.route, Routes.child(Routes.members, 15));
      expect(checkInFollowUp(accepted.data)?.label, 'سداد الدين');
      expect(
        checkInFollowUp(CheckInResult.fromJson(checkInJson(membership: membershipCardJson()), message: '')),
        isNull,
      );
    });
  });

  test('query from the link: known values only', () {
    final q = attendanceQueryFrom({
      'status': 'rejected',
      'method': 'fax',
      'from': '2026-11-01',
      'to': 'nope',
      'branch_id': '2',
      'search': ' أحمد ',
    });
    expect(q.filters, {'status': 'rejected', 'from': DateTime(2026, 11), 'branch_id': 2});
    expect(q.search, 'أحمد');
    expect(q.toParams()['from'], '2026-11-01');
  });

  group('CheckInCubit', () {
    test('a result marks the window as recorded unless it was a duplicate; another check-in gets a new key', () async {
      final cubit = CheckInCubit();
      addTearDown(cubit.close);
      final key = cubit.keyFor({'member_code': 'DMO-873152'});
      expect(cubit.keyFor({'member_code': 'DMO-873152'}), key);

      cubit.show(CheckInResult.fromJson(checkInJson(duplicate: true), message: ''));
      expect(cubit.state.recorded, isFalse);
      cubit.show(accepted.data);
      expect(cubit.state.recorded, isTrue);

      cubit.again();
      expect(cubit.state.result, isNull);
      expect(cubit.state.recorded, isTrue, reason: 'the screen still refreshes after closing');
      expect(cubit.keyFor({'member_code': 'DMO-873152'}), isNot(key));
    });

    test('picking a member and clearing it', () async {
      final cubit = CheckInCubit();
      addTearDown(cubit.close);
      cubit.pick(ahmad);
      expect(cubit.state.player, ahmad);
      cubit.clearPlayer();
      expect(cubit.state.player, isNull);
    });
  });

  test('list and today cubits ask with the branch', () async {
    final repo = FakeAttendanceRepository();
    final list = AttendanceListCubit(repo, (branchId: 2, query: attendanceQueryFrom({'status': 'rejected'})));
    final today = AttendanceTodayCubit(repo, branchId: 2);
    addTearDown(list.close);
    addTearDown(today.close);
    await Future.wait([list.load(), today.load()]);
    expect(repo.queries.single.branchId, 2);
    expect(repo.queries.single.query.filter('status'), 'rejected');
    expect(repo.todayCalls, [2]);
    expect(list.state.slice.data?.items, hasLength(3));
    expect(today.state.data?.accepted, 12);
  });
}
