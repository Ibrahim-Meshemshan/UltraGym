import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ultra_gym_reception/core/error/failure.dart';
import 'package:ultra_gym_reception/core/networking/api_result.dart';
import 'package:ultra_gym_reception/core/utils/formatters.dart';
import 'package:ultra_gym_reception/features/station/data/datasources/station_remote_datasource.dart';
import 'package:ultra_gym_reception/features/station/domain/models/check_in_models.dart';
import 'package:ultra_gym_reception/features/station/domain/models/station_models.dart';
import 'package:ultra_gym_reception/features/station/presentation/bloc/active_branch_cubit.dart';
import 'package:ultra_gym_reception/features/station/presentation/bloc/station_bloc.dart';

import 'fake_station_repository.dart';

void main() {
  setUpAll(() => Formatters.init('Asia/Damascus'));

  group('StationInput', () {
    test('an app QR is a token kept as is; a member code is upper-cased; anything else searches', () {
      const token = 'UG1.khielcztct3p.1794400000.aB-c_9';
      expect((StationInput.parse('  $token\n') as QrInput).token, token);
      expect((StationInput.parse('dmo-098969') as CodeInput).code, 'DMO-098969');
      expect((StationInput.parse('أحمد') as SearchInput).query, 'أحمد');
      expect((StationInput.parse('0944100001') as SearchInput).query, '0944100001');
      expect(StationInput.parse('   '), isNull);
    });
  });

  group('models', () {
    test('check-in result: accepted, duplicate, and a 409 with its record is a rejection', () {
      final ok = accepted.data;
      expect((ok.kind, ok.name, ok.memberCode, ok.code), (CheckInKind.accepted, 'أحمد الخطيب', 'DMO-098969', null));
      expect(ok.membership!.remaining, (label: 'المتبقي', value: Formatters.days(13)));

      final dup = CheckInResult.fromJson(checkInJson(duplicate: true), message: 'مسجّل منذ 19 ثانية');
      expect(dup.kind, CheckInKind.duplicate);

      final rej = (rejected as ApiSuccess<CheckInResult>).data;
      expect((rej.kind, rej.code, rej.message), (CheckInKind.rejected, 'BRANCH_NOT_ALLOWED', 'اشتراك اللاعب لا يشمل هذا الفرع'));
    });

    test('QR, not found and network stay failures', () {
      expect(StationRemoteDataSource.checkInResultOf(ApiFailure(qrExpired.failure)).failureOrNull?.code, 'QR_EXPIRED');
      const notFound = Failure(type: FailureType.notFound, statusCode: 404, message: 'اللاعب غير موجود بهذا النادي');
      expect(StationRemoteDataSource.checkInResultOf(const ApiFailure(notFound)).failureOrNull, notFound);
    });

    test('remaining follows the server status without computing days', () {
      MemberMembership m(String status, {String type = 'duration'}) =>
          MemberMembership.fromJson(membershipJson(status: status, type: type));
      expect(m('expired').remaining.label, 'انتهى');
      expect(m('upcoming').remaining.label, 'يبدأ');
      expect(m('active', type: 'sessions').remaining, (label: 'الجلسات المتبقية', value: '4'));
    });

    test('section now from the branch schedule (club time); mixed branches say so', () {
      final b = StationBranch.fromJson(branchJson());
      expect(b.sectionAt(DateTime(2026, 11, 11, 17, 31)), 'ذكور', reason: 'Wednesday 17:31, to 00:00 = end of day');
      expect(b.sectionAt(DateTime(2026, 11, 11, 23, 59)), 'ذكور');
      expect(b.sectionAt(DateTime(2026, 11, 11, 12)), 'إناث');
      expect(b.sectionAt(DateTime(2026, 11, 11, 17, 10)), isNull, reason: 'between sections');
      expect(b.sectionAt(DateTime(2026, 11, 13, 18)), isNull, reason: 'Friday is not in the schedule');
      expect(StationBranch.fromJson(branchJson(split: false)).sectionAt(DateTime(2026, 11, 13)), 'مختلط');
    });

    test('feed entry method labels', () {
      expect(AttendanceEntry.fromJson(recordJson()).methodLabel, 'QR');
      expect(AttendanceEntry.fromJson(recordJson(method: 'manual')).methodLabel, 'بحث يدوي');
    });
  });

  group('ActiveBranchCubit', () {
    test('stored branch wins, else the main one; a choice is remembered', () async {
      final repo = FakeStationRepository()
        ..branchesResult = ApiSuccess([
          StationBranch.fromJson(branchJson(id: 2, name: 'المالكي', main: false)),
          StationBranch.fromJson(branchJson()),
        ]);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final cubit = ActiveBranchCubit(repo, prefs);
      await cubit.load();
      expect(cubit.state.selectedId, 1);
      await cubit.select(2);
      expect(prefs.getInt(ActiveBranchCubit.storageKey), 2);
      final again = ActiveBranchCubit(repo, prefs);
      await again.load();
      expect(again.state.branch?.name, 'المالكي');
    });
  });

  group('StationBloc', () {
    late FakeStationRepository repo;
    late StationBloc bloc;

    setUp(() {
      repo = FakeStationRepository();
      bloc = StationBloc(repo);
    });
    tearDown(() => bloc.close());

    Future<void> settle() => Future<void>.delayed(Duration.zero);

    test('a scanned QR checks in with qr_token and the branch; each scan gets a new key; today refreshes', () async {
      bloc.add(const StationBranchChanged(1));
      await settle();
      expect(repo.todayCalls, [1]);

      bloc.add(const StationSubmitted('UG1.k.1.Sig'));
      await settle();
      expect(repo.checkIns.single.body, {'qr_token': 'UG1.k.1.Sig', 'branch_id': 1});
      expect(bloc.state.outcome.data?.kind, CheckInKind.accepted);
      expect(repo.todayCalls, [1, 1]);

      repo.checkInResults.add(ApiSuccess(CheckInResult.fromJson(checkInJson(duplicate: true), message: 'مسجّل')));
      bloc.add(const StationSubmitted('UG1.k.2.Sig'));
      await settle();
      expect(repo.checkIns[1].key, isNot(repo.checkIns[0].key));
      expect(repo.todayCalls, hasLength(2), reason: 'a duplicate records nothing new');
    });

    test('network failure is retried with the same key; a member code goes upper-cased', () async {
      bloc.add(const StationBranchChanged(1));
      await settle();
      repo.checkInResults.add(networkDown);
      bloc.add(const StationSubmitted('dmo-098969'));
      await settle();
      expect(bloc.state.outcome.failure?.isNetwork, isTrue);
      bloc.add(const StationRetried());
      await settle();
      expect(repo.checkIns.map((c) => c.body['member_code']), ['DMO-098969', 'DMO-098969']);
      expect(repo.checkIns[1].key, repo.checkIns[0].key);
      expect(bloc.state.outcome.data?.kind, CheckInKind.accepted);
    });

    test('a name searches; picking a result checks in by player_id; clear resets', () async {
      bloc.add(const StationBranchChanged(1));
      await settle();
      bloc.add(const StationSubmitted('أحمد'));
      await settle();
      expect(repo.lookups.single, (q: 'أحمد', branch: 1));
      expect(bloc.state.lookup.data, hasLength(2));

      bloc.add(StationPlayerPicked(bloc.state.lookup.data!.first));
      await settle();
      expect(repo.checkIns.single.body, {'player_id': 3, 'branch_id': 1});
      expect(bloc.state.lookupQuery, isNull);

      bloc.add(const StationCleared());
      await settle();
      expect(bloc.state.outcome.isInitial, isTrue);
    });
  });
}
