import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_gym_admin/core/networking/list_query.dart';
import 'package:ultra_gym_admin/core/networking/parse.dart';
import 'package:ultra_gym_admin/core/utils/json_x.dart';
import 'package:ultra_gym_admin/core/widgets/table/pagination_bar.dart';
import 'package:ultra_gym_admin/features/members/domain/models/member_models.dart';
import 'package:ultra_gym_admin/features/members/presentation/bloc/members_cubit.dart';
import 'package:ultra_gym_admin/features/members/presentation/widgets/member_cells.dart';

import 'fake_members_repository.dart';

void main() {
  group('MemberRow.fromJson', () {
    test('reads the real list item: branch, current membership and debt', () {
      expect(ahmad.name, 'أحمد الخطيب');
      expect(ahmad.memberCode, 'DMO-098969');
      expect(ahmad.branchName, 'الفرع الرئيسي - المزة');
      expect(ahmad.dueUsd, 20);
      expect(ahmad.hasDebt, isTrue);
      expect(ahmad.isSuspended, isFalse);
      final m = ahmad.membership!;
      expect(m.planName, 'تدريب خاص شهري');
      expect(m.statusLabel, 'فعّال');
      expect(m.endsOn, DateTime(2026, 11, 23));
      expect(m.daysRemaining, 15);
    });

    test('no membership and a suspended account', () {
      final r = MemberRow.fromJson(asJson({'id': 9, 'name': 'هبة', 'phone': '+963', 'status': 'suspended'}));
      expect(r.membership, isNull);
      expect(r.isSuspended, isTrue);
      expect(r.dueUsd, 0);
    });

    test('new member: one-time password and the ready WhatsApp message', () {
      final n = NewMember.fromJson(
        asJson({
          'id': 20,
          'name': 'سامي',
          'phone': '+963944200200',
          'member_code': 'DMO-200200',
          'is_existing_account': false,
          'temporary_password': '482913',
          'temporary_password_expires_at': '2026-11-16T10:00:00Z',
          'whatsapp_message': 'أهلاً',
        }),
      );
      expect(n.temporaryPassword, '482913');
      expect(n.passwordExpiresAt, DateTime.utc(2026, 11, 16, 10));
      expect(n.whatsappMessage, 'أهلاً');
      expect(NewMember.fromJson(asJson({'id': 1, 'is_existing_account': true})).temporaryPassword, isNull);
    });
  });

  group('membershipDetail', () {
    CurrentMembership m(String status, {int? days, int? sessions, String type = 'duration'}) => CurrentMembership(
      id: 1,
      planName: 'شهري',
      status: status,
      statusLabel: status,
      type: type,
      startsOn: DateTime(2026, 11, 15),
      endsOn: DateTime(2026, 11, 30),
      frozenUntil: DateTime(2026, 11, 14),
      daysRemaining: days,
      sessionsRemaining: sessions,
    );

    test('uses the server fields as they are', () {
      expect(membershipDetail(null), 'لم يشترك بعد');
      expect(membershipDetail(m('active', days: 21)), 'حتى 30 تشرين الثاني · باقي 21 يوماً');
      expect(membershipDetail(m('active', days: 0)), 'ينتهي اليوم');
      expect(membershipDetail(m('active', sessions: 4, type: 'sessions')), 'بقيت 4 جلسات');
      expect(membershipDetail(m('frozen')), 'مجمّد حتى 14 تشرين الثاني');
      expect(membershipDetail(m('upcoming')), 'يبدأ 15 تشرين الثاني');
      expect(membershipDetail(m('expired')), 'انتهى 30 تشرين الثاني');
    });

    test('initials take the first letter of two words', () {
      expect(initials('أحمد الخطيب'), 'أ ا');
      expect(initials('  هبة  '), 'ه');
    });
  });

  test('membersQueryFrom keeps only values the server accepts', () {
    final q = membersQueryFrom({
      'membership_status': 'expired',
      'has_debt': '1',
      'gender': 'female',
      'branch_id': '2',
      'search': ' أحمد ',
    });
    expect(q.toParams(), {
      'page': 1,
      'per_page': 15,
      'search': 'أحمد',
      'membership_status': 'expired',
      'gender': 'female',
      'has_debt': 1,
      'branch_id': 2,
    });
    expect(membersQueryFrom({'membership_status': 'upcoming', 'gender': 'x'}).hasFilters, isFalse);
  });

  test('pageWindow shows the edges and the pages around the current one', () {
    expect(pageWindow(1, 5), [1, 2, 3, 4, 5]);
    expect(pageWindow(1, 10), [1, 2, 3, 4, 5, null, 10]);
    expect(pageWindow(5, 10), [1, null, 4, 5, 6, null, 10]);
    expect(pageWindow(10, 10), [1, null, 6, 7, 8, 9, 10]);
  });

  test('IdempotencyKeeper: same body keeps the key, a changed body gets a new one', () {
    final keys = IdempotencyKeeper();
    final a = keys.keyFor({'name': 'سامي', 'phone': '0944'});
    expect(keys.keyFor({'name': 'سامي', 'phone': '0944'}), a);
    expect(keys.keyFor({'name': 'سامي', 'phone': '0945'}), isNot(a));
  });

  group('MembersListCubit', () {
    MembersListCubit cubit(FakeMembersRepository repo, {MembersTab tab = MembersTab.current, int? branchId}) =>
        MembersListCubit(repo, (tab: tab, branchId: branchId, query: const ListQuery()));

    test('sends the tab and the top-bar branch with every request', () async {
      final repo = FakeMembersRepository();
      final c = cubit(repo, tab: MembersTab.archive, branchId: 2);
      await c.load();
      expect(repo.listCalls.single.tab, MembersTab.archive);
      expect(repo.listCalls.single.branchId, 2);
      await c.close();
    });

    test('filters reset to page 1, goTo jumps, refresh keeps the page', () async {
      final repo = FakeMembersRepository();
      final c = cubit(repo);
      await c.load();
      await c.goTo(3);
      expect(repo.listCalls.last.params['page'], 3);
      await c.refresh(keepPage: true);
      expect(repo.listCalls.last.params['page'], 3);
      await c.filter(MemberFilters.hasDebt, true);
      expect(repo.listCalls.last.params, containsPair('page', 1));
      expect(repo.listCalls.last.params, containsPair('has_debt', 1));
      await c.search('أحمد');
      await c.clearFilters();
      expect(repo.listCalls.last.params.keys, ['page', 'per_page']);
      await c.close();
    });
  });
}
