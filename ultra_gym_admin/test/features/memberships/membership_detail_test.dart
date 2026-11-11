import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_gym_admin/core/bloc/app_form_cubit.dart';
import 'package:ultra_gym_admin/features/memberships/domain/models/membership_detail_models.dart';
import 'package:ultra_gym_admin/features/memberships/presentation/bloc/membership_detail_cubit.dart';
import 'package:ultra_gym_admin/features/memberships/presentation/widgets/cash_fields.dart';

import 'fake_membership_detail_repository.dart';

void main() {
  group('MembershipDetail.fromJson', () {
    test('reads the account, trainer, freezes and payments as sent', () {
      final d = MembershipDetail.fromJson(ahmadDetailJson());
      expect(d.id, 3);
      expect(d.planId, 4);
      expect(d.branchId, 1);
      expect(d.trainerId, 1);
      expect(d.membership.trainerName, 'كابتن مازن');
      expect(d.priceUsd, 60);
      expect(d.membership.paidUsd, 40);
      expect(d.membership.dueUsd, 20);
      expect(d.dueSyp, 260000);
      expect(d.commissionUsd, 12);
      expect(d.freezes.maxFreezes, 2);
      expect(d.freezes.maxDays, 30);
      expect(d.createdAt, DateTime.utc(2026, 10, 25, 16, 30));
      expect(d.transactions, hasLength(2));
      expect(d.transactions.first.receiptNumber, 'B1-2026-000003');
      expect(d.transactions.first.createdBy, 'ريم العلي');
      expect(d.transactions.last.amountUsd, 10);
      expect(d.hasDebt, isTrue);
      expect(d.canFreeze, isTrue);
      expect(d.isFrozen, isFalse);
    });

    test('frozen: history and no second freeze', () {
      final d = MembershipDetail.fromJson(ahmadDetailJson(status: 'frozen', label: 'مجمّد'));
      expect(d.isFrozen, isTrue);
      expect(d.canFreeze, isFalse);
      expect(d.freezes.used, 1);
      expect(d.freezes.history.single.days, 10);
      expect(d.freezes.history.single.reason, 'سفر');
      expect(d.freezes.history.single.endsOn, DateTime(2026, 11, 12));
    });

    test('cancelled is never a debt', () {
      final d = MembershipDetail.fromJson(ahmadDetailJson(status: 'cancelled', label: 'ملغى'));
      expect(d.hasDebt, isFalse);
      expect(d.cancellationReason, 'انتقل لمدينة أخرى');
    });

    test('sessions membership can consume a session while active', () {
      final d = MembershipDetail.fromJson(ahmadDetailJson(type: 'sessions'));
      expect(d.canConsumeSession, isTrue);
      expect(d.sessionsUsed, 4);
    });

    test('empty response does not throw', () {
      final d = MembershipDetail.fromJson(const {});
      expect(d.transactions, isEmpty);
      expect(d.freezes.history, isEmpty);
    });

    test('quote reads the new period and partial payment flag', () {
      final q = MembershipQuote.fromJson(quoteJson);
      expect(q.startsOn, DateTime(2026, 11, 24));
      expect(q.endsOn, DateTime(2026, 12, 23));
      expect(q.netSyp, 780000);
      expect(q.allowPartial, isTrue);
    });
  });

  test('payment lines skip empty and zero amounts, strip commas', () async {
    final form = AppFormCubit(initial: {PaymentFields.usd: '10', PaymentFields.syp: '65,000'});
    expect(PaymentFields.linesOf(form), [
      {'currency': 'USD', 'amount': 10},
      {'currency': 'SYP', 'amount': 65000},
    ]);
    form.set(PaymentFields.usd, '0');
    form.set(PaymentFields.syp, '');
    expect(PaymentFields.linesOf(form), isEmpty);
    await form.close();
  });

  test('detail cubit loads by id', () async {
    final repo = FakeMembershipDetailRepository();
    final c = MembershipDetailCubit(repo, 3);
    await c.load();
    expect(repo.detailCalls, [3]);
    expect(c.state.data!.membership.planName, 'تدريب خاص شهري');
    await c.close();
  });

  test('attendance cubit asks the member visits within the period', () async {
    final repo = FakeMembershipDetailRepository();
    final c = MembershipAttendanceCubit(repo, (playerId: 3, from: DateTime(2026, 10, 25), to: DateTime(2026, 11, 23)));
    await c.load();
    expect(repo.attendanceCalls.single, (playerId: 3, from: DateTime(2026, 10, 25), to: DateTime(2026, 11, 23)));
    await c.close();
  });
}
