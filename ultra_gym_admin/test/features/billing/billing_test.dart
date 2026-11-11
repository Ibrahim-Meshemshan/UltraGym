import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_gym_admin/core/core.dart';
import 'package:ultra_gym_admin/features/billing/domain/models/activity_models.dart';
import 'package:ultra_gym_admin/features/billing/domain/models/billing_models.dart';
import 'package:ultra_gym_admin/features/billing/domain/models/billing_texts.dart';
import 'package:ultra_gym_admin/features/billing/domain/models/support_models.dart';
import 'package:ultra_gym_admin/features/billing/presentation/bloc/billing_cubits.dart';

import 'fake_billing_repository.dart';

void main() {
  setUpAll(() => Formatters.init('Asia/Damascus'));

  group('billing models', () {
    test('overview: current, history and balance; dates stay days', () {
      final o = BillingOverview.fromJson(
        overviewJson(current: platformSubJson(status: 'grace'), history: [platformSubJson(id: 3)], outstanding: 49, overdue: 1),
      );
      expect(o.current?.status, 'grace');
      expect(o.current?.planName, 'Pro');
      expect(o.current?.cycle, 'monthly');
      expect(o.current?.startsOn, DateTime(2026, 11, 1));
      expect(o.current?.graceEndsOn, DateTime(2026, 12, 7));
      expect(o.history.single.id, 3);
      expect(o.outstanding, 49);
      expect(o.overdueInvoices, 1);
    });

    test('live demo shape: no subscription, nothing owed', () {
      final o = BillingOverview.fromJson(overviewJson());
      expect(o.current, isNull);
      expect(o.history, isEmpty);
      expect(o.outstanding, 0);
    });

    test('usage lines: ratio for the bar only, null limit = unlimited', () {
      final u = PlanUsage.fromJson(usageJson(playersUsed: 200));
      expect(u.players.reached, isTrue);
      expect(u.players.ratio, 1);
      expect(u.staff.limit, isNull);
      expect(u.staff.ratio, isNull);
      expect(u.staff.reached, isFalse);
      expect(u.daysRemaining, 19);
      expect(BillingTexts.usage(u.branches), '2 / 10');
      expect(BillingTexts.usage(u.staff), '2 / ∞');
    });

    test('invoice with payments; overdue wins the badge', () {
      final i = PlatformInvoice.fromJson(
        invoiceJson(
          overdue: true,
          paid: 20,
          payments: [
            {'id': 1, 'amount': 20, 'method': 'cash', 'reference_number': null, 'paid_at': '2026-11-03'},
          ],
        ),
      );
      expect(i.remaining, 29);
      expect(i.dueOn, DateTime(2026, 11, 8));
      expect(i.payments.single.method, 'cash');
      expect(i.label.text, 'متأخرة');
      expect(PlatformInvoice.fromJson(invoiceJson(status: 'paid')).label.tone, UTone.success);
      expect(PlatformInvoice.fromJson(invoiceJson(status: 'paid')).paidAt, DateTime.utc(2026, 11, 2, 10));
    });

    test('texts: title, notes, cycles, methods, storage, features', () {
      final s = PlatformSubscription.fromJson(platformSubJson());
      expect(BillingTexts.title(s), 'Pro · شهري');
      expect(BillingTexts.title(const PlatformSubscription(id: 1, status: 'active')), 'باقة النادي');
      expect(BillingTexts.note(s, 19), 'ينتهي بعد 19 يوماً');
      expect(BillingTexts.note(s, 0), 'ينتهي اليوم');
      expect(BillingTexts.note(s, null), isNull);
      expect(
        BillingTexts.note(PlatformSubscription.fromJson(platformSubJson(status: 'grace')), 3),
        'السماح حتى ${Formatters.ltr('2026-12-07')}',
      );
      expect(BillingTexts.note(PlatformSubscription.fromJson(platformSubJson(status: 'expired')), 3), contains('للقراءة'));
      expect(BillingTexts.cycle('semiannual'), 'نصف سنوي');
      expect(BillingTexts.method('bank_transfer'), 'حوالة بنكية');
      expect(BillingTexts.storage(1024), '1 GB');
      expect(BillingTexts.storage(1536), '1.5 GB');
      expect(BillingTexts.storage(500), '500 MB');
      expect(BillingTexts.storage(null), isNull);
      expect(BillingTexts.included({'qr_attendance': true, 'custom_branding': false, 'new_thing': true}), [
        'دخول QR',
        'new_thing',
      ]);
    });
  });

  group('support models', () {
    test('ticket and thread from the contract shape', () {
      final thread = FakeSupportRepository().threadOf(ticketJson(), replies: [
        replyJson(files: [
          {'id': 4, 'name': 'shot.png', 'url': 'https://x/signed', 'mime_type': 'image/png', 'size_kb': 2048},
        ]),
        replyJson(id: 2, support: true),
      ]);
      expect(thread.ticket.number, 'TCK-000003');
      expect(thread.ticket.awaitingReply, isTrue);
      expect(thread.replies.first.fromSupport, isFalse);
      expect(thread.replies.first.attachments.single.url, 'https://x/signed');
      expect(thread.replies.last.fromSupport, isTrue);
      expect(SupportTexts.size(2048), '2.0 MB');
      expect(SupportTexts.size(300), '300 KB');
    });

    test('status: awaiting your reply wins, otherwise the server status', () {
      SupportTicket t(String status, {bool awaiting = false}) =>
          SupportTicket.fromJson(ticketJson(status: status, awaiting: awaiting));
      expect(SupportTexts.status(t('in_progress', awaiting: true)), (label: 'بانتظار ردك', tone: UTone.info));
      expect(SupportTexts.status(t('open')), (label: 'مفتوحة', tone: UTone.warning));
      expect(SupportTexts.status(t('resolved')).tone, UTone.success);
      expect(SupportTexts.status(t('closed')), (label: 'مغلقة', tone: UTone.neutral));
      expect(t('closed').isClosed, isTrue);
      expect(SupportTexts.category('feature_request'), 'طلب ميزة');
      expect(SupportTexts.priority('urgent'), 'عاجلة');
    });
  });

  group('activity models', () {
    test('entry from a real line; detail lists changed keys only', () {
      final e = ActivityEntry.fromJson(activityJson(detail: true));
      expect(e.moduleLabel, 'النادي والإعدادات');
      expect(e.actor, 'سامر الحلبي');
      expect(e.subject, 'نادي القمة التجريبي');
      expect(e.ip, '127.0.0.1');
      expect(e.changes.map((c) => c.key), ['grace_days']);
      expect(ActivityEntry.fromJson(activityJson()).changes, isEmpty);
    });

    test('system actor, created entries and value display', () {
      final e = ActivityEntry.fromJson({
        ...activityJson(),
        'actor': null,
        'subject': null,
        'new_values': {'name': 'فرع', 'days': ['sat', 'sun'], 'active': true},
      });
      expect(e.actor, 'النظام');
      expect(e.subject, isNull);
      expect(e.changes, hasLength(3));
      expect(ActivityEntry.show(['sat', 'sun']), 'sat، sun');
      expect(ActivityEntry.show(true), 'نعم');
      expect(ActivityEntry.show(null), '—');
      expect(ActivityEntry.show(const <Object?>[]), '—');
    });
  });

  group('cubits', () {
    test('invoices filter and activity log 50 per page', () async {
      final billing = FakeBillingRepository();
      final log = FakeActivityLogRepository();
      final invoices = InvoicesCubit(billing);
      final activity = ActivityLogCubit(log);
      await invoices.load();
      await invoices.filter('overdue', 1);
      await activity.load();
      expect(billing.queries.last.filter('overdue'), 1);
      expect(log.queries.single.perPage, 50);
      expect(activity.state.slice.data?.meta['modules'], isNotEmpty);
      await invoices.close();
      await activity.close();
    });

    test('detail cubits ask for their id', () async {
      final support = FakeSupportRepository();
      final thread = TicketThreadCubit(support, 3);
      await thread.load();
      expect(support.threadCalls, [3]);
      expect(thread.state.data?.replies, hasLength(2));
      await thread.close();
    });
  });
}
