import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_gym_admin/core/bloc/slice.dart';
import 'package:ultra_gym_admin/core/networking/list_query.dart';
import 'package:ultra_gym_admin/features/members/domain/models/member_profile_models.dart';
import 'package:ultra_gym_admin/features/members/presentation/bloc/member_profile_cubit.dart';
import 'package:ultra_gym_admin/features/members/presentation/widgets/member_cells.dart';

import 'fake_member_profile_repository.dart';

void main() {
  group('MemberProfile.fromJson (real response)', () {
    test('reads account, profile, membership, stats and measurement', () {
      final p = ahmadProfile;
      expect(p.name, 'أحمد الخطيب');
      expect(p.memberCode, 'DMO-098969');
      expect(p.branchId, 1);
      expect(p.branchName, 'الفرع الرئيسي - المزة');
      expect(p.gender, 'male');
      expect(p.birthDate, DateTime(1996, 4, 12));
      expect(p.emergencyPhone, '+963933001245');
      expect(p.joinedAt, DateTime.utc(2026, 9, 27, 9));
      expect(p.dueUsd, 20);
      expect(p.hasDebt, isTrue);
      expect(p.isSuspended, isFalse);
      expect(p.isArchived, isFalse);
      expect(p.stats.visitsTotal, 8);
      expect(p.stats.visitsThisMonth, 5);
      expect(p.stats.paidTotalUsd, 40);
      expect(p.measurement?.weightKg, 86);
      expect(p.measurement?.bodyFat, 18.9);

      final m = p.membership!;
      expect(m.trainerName, 'كابتن مازن');
      expect((m.netUsd, m.paidUsd, m.dueUsd), (60, 40, 20));
      expect(membershipDetail(m), 'حتى 23 تشرين الثاني · باقي 15 يوماً');
    });

    test('suspended and archived flags come from the server fields', () {
      final s = MemberProfile.fromJson(profileJson(status: 'suspended', reason: 'تأخر بالدفع'));
      expect(s.isSuspended, isTrue);
      expect(s.suspensionReason, 'تأخر بالدفع');
      expect(s.suspendedAt, DateTime.utc(2026, 11, 5, 9));
      expect(MemberProfile.fromJson(profileJson(archivedAt: '2026-11-01T10:00:00Z')).isArchived, isTrue);
    });

    test('missing profile and stats do not throw', () {
      final p = MemberProfile.fromJson(const {'id': 9, 'name': 'س', 'phone': '+963944000000'});
      expect(p.branchName, isNull);
      expect(p.membership, isNull);
      expect(p.stats.visitsTotal, 0);
      expect(p.measurement, isNull);
    });

    test('form values use the server keys', () {
      final v = ahmadProfile.formValues;
      expect(v['branch_id'], 1);
      expect(v['birth_date'], DateTime(1996, 4, 12));
      expect(v['emergency_contact_name'], 'نزار الخطيب');
      expect(v.containsKey('address'), isTrue);
    });
  });

  test('history rows: attendance method and rejection, payment currency', () {
    final a = AttendanceEntry.fromJson(attendanceJson);
    expect(a.methodLabel, 'يدوي');
    expect(a.checkedInAt, DateTime.utc(2026, 11, 8, 11, 58, 43));
    expect(rejected.methodLabel, 'QR');
    expect(rejected.rejectionMessage, 'ليس وقت قسمك');

    final p = PaymentEntry.fromJson(paymentJson);
    expect((p.currency, p.amount, p.isOut, p.isReversed), ('SYP', 130000, false, false));
    expect(p.businessDate, DateTime(2026, 10, 25));
  });

  test('history cubit pages by 10 and reloads from page 1', () async {
    final repo = FakeMemberProfileRepository();
    final cubit = MemberHistoryCubit((q) => repo.attendance(3, q));
    expect(cubit.state.query.perPage, MemberHistoryCubit.perPage);
    await cubit.goTo(2);
    await cubit.load();
    expect(repo.historyCalls, ['attendance:2', 'attendance:1']);
    expect(cubit.state.slice.status, LoadStatus.success);
    expect(cubit.state.query, const ListQuery(perPage: 10));
    await cubit.close();
  });

  test('profile cubit forwards actions with its id', () async {
    final repo = FakeMemberProfileRepository();
    final cubit = MemberProfileCubit(repo, 3);
    await cubit.load();
    expect(cubit.state.data, ahmadProfile);
    await cubit.suspend('سبب');
    await cubit.activate();
    expect(repo.suspended, ['سبب']);
    expect(repo.activated, 1);
    expect(repo.profileCalls, [3]);
    await cubit.close();
  });
}
