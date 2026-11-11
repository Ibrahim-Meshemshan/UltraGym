import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_gym_admin/core/error/failure.dart';
import 'package:ultra_gym_admin/core/networking/api_result.dart';
import 'package:ultra_gym_admin/features/memberships/domain/models/sale_models.dart';
import 'package:ultra_gym_admin/features/memberships/presentation/bloc/sell_membership_cubit.dart';

import '../members/fake_member_profile_repository.dart';
import '../quick_search/fake_quick_search_repository.dart';
import 'fake_sell_membership_repository.dart';

void main() {
  group('sale models', () {
    test('plans read type, sessions, prices, scope and personal training', () {
      final plans = [for (final p in plansJson) SalePlan.fromJson(p)];
      expect(plans.map((p) => p.id), [1, 3, 4, 5]);
      expect(plans[1].isSessions, isTrue);
      expect(plans[1].sessionsCount, 12);
      expect(plans[1].durationDays, 45);
      expect(plans[2].isPersonal, isTrue);
      expect(plans[2].priceSyp, 780000);
      expect(plans[3].allBranches, isFalse);
      expect(plans[3].branchNames, ['فرع المالكي']);
    });

    test('quote reads rate and coupon; paid estimate converts SYP at the rate', () {
      final q = MembershipQuote.fromJson(saleQuoteJson(coupon: 'WELCOME10'));
      expect(q.netUsd, 22.5);
      expect(q.couponCode, 'WELCOME10');
      expect(q.exchangeRate, 13000);
      expect(q.endsOn, DateTime(2026, 12, 11));
      expect(q.paidUsd(usd: 15, syp: 65000), 20);
      expect(const MembershipQuote(netUsd: 10).paidUsd(usd: 2, syp: 65000), 2);
    });

    test('sale result: new membership, debt and one receipt per payment', () {
      final r = SaleResult.fromJson(saleJson).withMessage('تم');
      expect(r.membershipId, 21);
      expect(r.dueUsd, 5);
      expect(r.receipts.map((t) => t.number), ['B1-2026-000031', 'B1-2026-000032']);
      expect(r.receipts.last.currency, 'SYP');
      expect(r.message, 'تم');
    });

    test('member from lookup and from profile', () {
      final a = SaleMember.fromLookup(ahmad);
      expect((a.id, a.membershipStatus, a.dueUsd), (3, 'active', 20));
      final p = SaleMember.fromProfile(ahmadProfile);
      expect(p.id, ahmadProfile.id);
      expect(p.name, ahmadProfile.name);
    });

    test('empty json does not throw', () {
      expect(SalePlan.fromJson(const {}).branchNames, isEmpty);
      expect(SaleResult.fromJson(const {}).receipts, isEmpty);
      expect(MembershipQuote.fromJson(const {}).couponCode, isNull);
    });
  });

  group('SellMembershipCubit', () {
    late FakeSellMembershipRepository repo;
    late SellMembershipCubit cubit;

    setUp(() => repo = FakeSellMembershipRepository());
    tearDown(() => cubit.close());

    SellMembershipCubit make({int? playerId, int? branchId}) =>
        cubit = SellMembershipCubit(repo, (playerId: playerId, branchId: branchId));

    test('loads plans for the branch and the member from the link', () async {
      await make(playerId: 15, branchId: 1).load();
      expect(repo.planCalls, [1]);
      expect(repo.memberCalls, [15]);
      expect(cubit.state.plans.data, hasLength(4));
      expect(cubit.state.member.data?.name, 'عضو تجريبي');
    });

    test('no link: no member request and nothing chosen', () async {
      await make().load();
      expect(repo.memberCalls, isEmpty);
      expect(cubit.state.member.data, isNull);
    });

    test('choosing a plan quotes it; a start date re-quotes with it', () async {
      await make().load();
      await cubit.selectPlan(1);
      expect(repo.quotes.last, {'plan_id': 1});
      expect(cubit.state.quote.data?.netUsd, 25);
      await cubit.setStart(DateTime(2026, 11, 12));
      expect(repo.quotes.last, {'plan_id': 1, 'starts_on': '2026-11-12'});
      await cubit.selectPlan(1);
      expect(repo.quotes, hasLength(2), reason: 'same plan again: no request');
    });

    test('personal training loads trainers once', () async {
      await make().load();
      await cubit.selectPlan(4);
      await cubit.selectPlan(1);
      await cubit.selectPlan(4);
      await pumpEventQueue();
      expect(cubit.state.needsTrainer, isTrue);
      expect(repo.trainerCalls, 1);
      expect(cubit.state.trainers.data?.map((t) => t.name), ['كابتن لينا', 'كابتن مازن']);
    });

    test('valid coupon applies; invalid keeps the previous price and shows why', () async {
      await make().load();
      await cubit.selectPlan(1);
      await cubit.applyCoupon(' welcome10 ');
      expect(repo.quotes.last, {'plan_id': 1, 'coupon_code': 'WELCOME10'});
      expect(cubit.state.coupon, 'WELCOME10');
      expect(cubit.state.quote.data?.netUsd, 22.5);

      await cubit.applyCoupon('NOPE');
      expect(cubit.state.coupon, 'WELCOME10');
      expect(cubit.state.discountError, 'الكوبون غير موجود');
      expect(cubit.state.quote.data?.netUsd, 22.5);
      expect(cubit.state.quote.isSuccess, isTrue);

      await cubit.applyCoupon('');
      expect(cubit.state.coupon, isNull);
      expect(cubit.state.discountError, isNull);
      expect(cubit.state.quote.data?.netUsd, 25);
    });

    test('coupon before a plan is kept and sent with the first quote', () async {
      await make().load();
      await cubit.applyCoupon('WELCOME10');
      expect(repo.quotes, isEmpty);
      await cubit.selectPlan(1);
      expect(repo.quotes.last['coupon_code'], 'WELCOME10');
    });

    test('switching to a manual discount drops the coupon and re-quotes', () async {
      await make().load();
      await cubit.selectPlan(1);
      await cubit.applyCoupon('WELCOME10');
      await cubit.setMode(DiscountMode.manual);
      expect(cubit.state.coupon, isNull);
      expect(repo.quotes.last, {'plan_id': 1});
      await cubit.applyDiscount(5);
      expect(repo.quotes.last, {'plan_id': 1, 'discount_usd': 5.0});
      expect(cubit.state.quote.data?.netUsd, 20);
      await cubit.applyDiscount(0);
      expect(cubit.state.discount, isNull);
    });

    test('a forbidden manual discount shows the server message', () async {
      await make().load();
      await cubit.selectPlan(1);
      repo.quoteResult = const ApiFailure(
        Failure(type: FailureType.forbidden, code: 'FORBIDDEN', message: 'الخصم اليدوي للمالك فقط. استخدم كوبون خصم.'),
      );
      await cubit.applyDiscount(5);
      expect(cubit.state.discount, isNull);
      expect(cubit.state.discountError, 'الخصم اليدوي للمالك فقط. استخدم كوبون خصم.');
    });

    test('an older quote that arrives late is ignored', () async {
      await make().load();
      repo.holdQuote = Completer();
      final first = cubit.selectPlan(1);
      final gate = repo.holdQuote!;
      repo.holdQuote = null;
      await cubit.selectPlan(3);
      expect(cubit.state.planId, 3);
      gate.complete();
      await first;
      expect(cubit.state.quote.isSuccess, isTrue);
      expect(repo.quotes.map((q) => q['plan_id']), [1, 3]);
    });

    test('quote failure is kept for retry', () async {
      await make().load();
      repo.quoteResult = const ApiFailure(Failure(type: FailureType.network, message: 'تعذّر الاتصال.'));
      await cubit.selectPlan(1);
      expect(cubit.state.quote.isFailure, isTrue);
      repo.quoteResult = null;
      await cubit.retryQuote();
      expect(cubit.state.quote.data?.netUsd, 25);
    });

    test('same body keeps its key; another sale gets a new one', () async {
      await make().load();
      final body = {'player_id': 15, 'plan_id': 1};
      final key = cubit.keyFor(body);
      expect(cubit.keyFor({...body}), key);
      cubit
        ..done(SaleResult.fromJson(saleJson))
        ..startOver();
      expect(cubit.keyFor(body), isNot(key));
      expect(cubit.state.result, isNull);
      expect(cubit.state.plans.data, hasLength(4));
      expect(cubit.state.planId, isNull);
    });
  });
}
