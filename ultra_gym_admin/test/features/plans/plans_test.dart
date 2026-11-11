import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_gym_admin/core/bloc/app_form_cubit.dart';
import 'package:ultra_gym_admin/features/plans/domain/models/plans_models.dart';
import 'package:ultra_gym_admin/features/plans/presentation/bloc/plans_cubit.dart';
import 'package:ultra_gym_admin/features/plans/presentation/widgets/coupon_actions.dart';
import 'package:ultra_gym_admin/features/plans/presentation/widgets/plan_actions.dart';

import 'fake_plans_repository.dart';

void main() {
  final rows = [for (final j in planRows()) Plan.fromJson(j)];

  group('plan model', () {
    test('reads the server shape', () {
      final p = rows[1];
      expect(p.isSessions, isTrue);
      expect(p.sessionsCount, 12);
      expect(p.priceUsd, 30);
      expect(p.allBranches, isFalse);
      expect(p.branches.single.name, 'الفرع الرئيسي - المزة');
      expect(p.sold, 0);
      expect(rows[2].isPersonal, isTrue);
      expect(rows[3].active, isFalse);
    });

    test('texts come from server fields', () {
      expect(PlanTexts.kind(rows[0]), 'حسب المدة');
      expect(PlanTexts.kind(rows[1]), 'عدد حصص');
      expect(PlanTexts.duration(30), '30 يوماً');
      expect(PlanTexts.sessions(12), '12 حصة');
      expect(PlanTexts.branches(rows[0]), 'كل الفروع');
      expect(PlanTexts.branches(rows[1]), 'الفرع الرئيسي - المزة');
      expect(PlanTexts.freeze(rows[0]), 'مرتان · 30 يوماً (افتراضي النادي)');
      expect(PlanTexts.freeze(rows[2]), 'مرة واحدة · 7 أيام');
      expect(PlanTexts.freeze(rows[3]), 'بلا تجميد');
    });
  });

  group('coupon model', () {
    final coupons = [for (final j in couponRows()) Coupon.fromJson(j)];

    test('reads the server shape, usage and deletability', () {
      final c = coupons[0];
      expect(c.percent, isTrue);
      expect(c.value, 25);
      expect(c.planIds, [1, 2]);
      expect(c.usage, 0);
      expect(c.canDelete, isTrue);
      expect(coupons[1].usage, isNull, reason: 'no limit');
      expect(coupons[1].canDelete, isFalse);
      expect(coupons[2].active, isFalse);
    });

    test('texts: discount, uses, and plan names', () {
      expect(PlanTexts.discount(coupons[0]), '25%');
      expect(PlanTexts.discount(coupons[1]), r'$5.00');
      expect(PlanTexts.uses(coupons[1]), '64 / ∞');
      expect(PlanTexts.couponPlans(coupons[0], rows), 'شهري - حديد، 12 جلسة');
      expect(PlanTexts.couponPlans(coupons[1], rows), 'كل الخطط');
      expect(PlanTexts.couponPlans(coupons[2], const []), '#3');
    });
  });

  group('bodies', () {
    test('plan: sessions with selected branches, empty freeze limits are null (club default)', () {
      final f = AppFormCubit(
        initial: {
          'name': ' 12 جلسة ',
          'type': 'sessions',
          'duration_days': '45',
          'sessions_count': '12',
          'price_usd': '1,030',
          'branch_scope': 'selected',
          'branch_ids': [1],
          'is_personal_training': false,
          'active': true,
        },
      );
      addTearDown(f.close);
      expect(PlanActions.bodyOf(f, multiBranch: true), {
        'name': '12 جلسة',
        'description': null,
        'type': 'sessions',
        'duration_days': 45,
        'sessions_count': 12,
        'price_usd': 1030,
        'branch_scope': 'selected',
        'branch_ids': [1],
        'max_freezes': null,
        'max_freeze_days': null,
        'is_personal_training': false,
        'status': 'active',
      });
      expect(PlanActions.bodyOf(f, multiBranch: false)['branch_scope'], 'all');
    });

    test('coupon: uppercase code, dates as days, no limit is null', () {
      final f = AppFormCubit(
        initial: {
          'code': ' winter25 ',
          'discount_type': 'fixed',
          'discount_value': '5',
          'starts_on': DateTime(2026, 12, 1),
          'plan_ids': [1],
          'active': false,
        },
      );
      addTearDown(f.close);
      expect(CouponActions.bodyOf(f), {
        'code': 'WINTER25',
        'discount_type': 'fixed',
        'discount_value': 5,
        'max_uses': null,
        'starts_on': '2026-12-01',
        'ends_on': null,
        'plan_ids': [1],
        'note': null,
        'status': 'inactive',
      });
    });
  });

  group('cubits', () {
    test('plans load 50 per page, and the archive asks for archived only', () async {
      final repo = FakePlansRepository();
      final a = PlansListCubit(repo);
      final b = PlansListCubit(repo, archived: true);
      addTearDown(a.close);
      addTearDown(b.close);
      await a.load();
      await b.load();
      expect(repo.planQueries.first.perPage, 50);
      expect(repo.planQueries.first.filter('archived'), isNull);
      expect(repo.planQueries.last.filter('archived'), 'only');
      expect(b.state.slice.data!.items.single.name, 'عرض الصيف');
    });

    test('coupon plans load up to 100 plans', () async {
      final repo = FakePlansRepository();
      final c = CouponPlansCubit(repo);
      addTearDown(c.close);
      await c.load();
      expect(repo.planQueries.single.perPage, 100);
      expect(c.state.data, hasLength(4));
    });
  });
}
