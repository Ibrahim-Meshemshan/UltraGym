import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_gym_admin/core/utils/json_x.dart';
import 'package:ultra_gym_admin/features/quick_search/domain/models/quick_search_models.dart';
import 'package:ultra_gym_admin/features/quick_search/presentation/bloc/quick_search_cubit.dart';

import 'fake_quick_search_repository.dart';

void main() {
  test('parses the lookup response from the real server shape', () {
    final p = LookupPlayer.fromJson(
      asJson({
        'id': 3,
        'name': 'أحمد الخطيب',
        'phone': '+963944100001',
        'member_code': 'DMO-098969',
        'membership': {
          'id': 3,
          'plan': {'id': 4, 'name': 'تدريب خاص شهري'},
          'ends_on': '2026-11-23',
          'days_remaining': 16,
          'sessions_remaining': null,
          'status': 'active',
          'status_label': 'فعّال',
          'due_usd': 20,
        },
        'can_enter': true,
        'rejection_reason': null,
        'rejection_message': null,
      }),
    );
    expect(p.memberCode, 'DMO-098969');
    expect(p.membership?.planName, 'تدريب خاص شهري');
    expect(p.membership?.endsOn, DateTime(2026, 11, 23));
    expect(p.membership?.hasDebt, isTrue);
    expect(p.canEnter, isTrue);

    final none = LookupPlayer.fromJson(asJson({'id': 9, 'name': 'زائر', 'membership': null, 'can_enter': false}));
    expect(none.membership, isNull);
  });

  group('QuickSearchCubit', () {
    late FakeQuickSearchRepository repo;
    late QuickSearchCubit cubit;

    setUp(() {
      repo = FakeQuickSearchRepository();
      cubit = QuickSearchCubit(repo, branchId: 1, delay: Duration.zero);
    });
    tearDown(() => cubit.close());

    Future<void> settle() => Future<void>.delayed(Duration.zero);

    test('under two characters sends nothing', () async {
      cubit.changed(' أ ');
      await settle();
      expect(repo.calls, isEmpty);
      expect(cubit.state.tooShort, isTrue);
    });

    test('searches with the branch and keeps old results while the next query loads', () async {
      cubit.changed('أحمد');
      await settle();
      await settle();
      expect(repo.calls, [('أحمد', 1)]);
      expect(cubit.state.results.data, [ahmad]);

      repo.hold = Completer<void>();
      cubit.changed('أحمد الخ');
      expect(cubit.state.results.isRefreshing, isTrue);
      repo.hold!.complete();
    });

    test('a late answer for an old query is ignored', () async {
      repo.hold = Completer<void>();
      cubit.changed('0944');
      await settle();
      cubit.changed('سامي');
      final first = repo.hold!;
      repo.hold = null;
      await settle();
      await settle();
      expect(cubit.state.results.data, [sami]);

      first.complete();
      await settle();
      expect(cubit.state.query, 'سامي');
      expect(cubit.state.results.data, [sami]);
    });
  });
}
