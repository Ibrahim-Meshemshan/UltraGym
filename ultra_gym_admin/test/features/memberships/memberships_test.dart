import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_gym_admin/core/networking/list_query.dart';
import 'package:ultra_gym_admin/features/members/presentation/widgets/member_cells.dart';
import 'package:ultra_gym_admin/features/memberships/domain/models/memberships_models.dart';
import 'package:ultra_gym_admin/features/memberships/presentation/bloc/memberships_cubit.dart';

import 'fake_memberships_repository.dart';

void main() {
  group('MembershipRow.fromJson', () {
    test('reads the owner, plan, money and server status', () {
      expect(ahmadDebt.id, 3);
      expect(ahmadDebt.playerId, 3);
      expect(ahmadDebt.playerName, 'أحمد الخطيب');
      expect(ahmadDebt.planName, 'تدريب خاص شهري');
      expect(ahmadDebt.branchName, 'الفرع الرئيسي - المزة');
      expect(ahmadDebt.netUsd, 60);
      expect(ahmadDebt.paidUsd, 40);
      expect(ahmadDebt.dueUsd, 20);
      expect(ahmadDebt.statusLabel, 'فعّال');
      expect(ahmadDebt.endsOn, DateTime(2026, 11, 23));
    });

    test('upcoming sessions plan says when it starts', () {
      expect(nour.isSessions, isTrue);
      expect(nour.sessionsTotal, 12);
      expect(membershipDetail(nour), 'يبدأ 9 كانون الأول');
    });

    test('missing player falls back without throwing', () {
      final m = MembershipRow.fromJson({'id': 1, 'status': 'expired'});
      expect(m.playerName, '—');
      expect(m.playerId, 0);
      expect(m.statusLabel, 'منتهٍ');
    });
  });

  group('membershipsArgsFrom', () {
    test('dashboard links open their tabs', () {
      expect(membershipsArgsFrom({'has_debt': '1'}).tab, MembershipsTab.debts);
      expect(membershipsArgsFrom({'has_debt': 'true'}).tab, MembershipsTab.debts);
      expect(membershipsArgsFrom({'expiring_within_days': '7'}).tab, MembershipsTab.expiring);
      expect(membershipsArgsFrom({}).tab, MembershipsTab.all);
      expect(membershipsArgsFrom({'has_debt': '0'}).tab, MembershipsTab.all);
    });

    test('keeps accepted filters and drops unknown values', () {
      final q = membershipsArgsFrom({'status': 'frozen', 'plan_id': '3', 'branch_id': 'x', 'search': '  أحمد '}).query;
      expect(q.filter('status'), 'frozen');
      expect(q.filter('plan_id'), 3);
      expect(q.filter('branch_id'), isNull);
      expect(q.search, 'أحمد');
      expect(membershipsArgsFrom({'status': 'none'}).query, const ListQuery());
    });
  });

  group('cubits', () {
    test('list cubit asks its tab with the top-bar branch', () async {
      final repo = FakeMembershipsRepository();
      final c = MembershipsListCubit(repo, (tab: MembershipsTab.debts, branchId: 2, query: const ListQuery()));
      await c.load();
      expect(repo.calls.single.tab, MembershipsTab.debts);
      expect(repo.calls.single.branchId, 2);
      expect(c.state.slice.data!.items, [ahmadDebt]);
      await c.close();
    });

    test('stats cubit loads per branch', () async {
      final repo = FakeMembershipsRepository();
      final c = MembershipStatsCubit(repo, branchId: 1);
      await c.load();
      expect(repo.statsCalls, [1]);
      expect(c.state.data, demoStats);
      await c.close();
    });
  });
}
