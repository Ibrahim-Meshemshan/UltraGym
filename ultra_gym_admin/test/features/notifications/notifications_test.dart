import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_gym_admin/core/error/failure.dart';
import 'package:ultra_gym_admin/core/networking/api_result.dart';
import 'package:ultra_gym_admin/core/router/routes.dart';
import 'package:ultra_gym_admin/core/utils/json_x.dart';
import 'package:ultra_gym_admin/features/notifications/domain/models/notification_models.dart';
import 'package:ultra_gym_admin/features/notifications/presentation/bloc/notifications_list_cubit.dart';
import 'package:ultra_gym_admin/features/notifications/presentation/bloc/unread_count_cubit.dart';
import 'package:ultra_gym_admin/features/notifications/presentation/notification_links.dart';

import 'fake_notifications_repository.dart';

AppNotification note(String screen, [Json data = const {}]) =>
    AppNotification(id: 1, type: 't', screen: screen, title: 'ع', data: data);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('parses a notification (ids in data may arrive as text)', () {
    final n = AppNotification.fromJson(
      asJson({
        'id': 812,
        'type': 'club_reversal',
        'screen': 'transaction',
        'title': 'عكس حركة مالية',
        'body': 'عكس سامر الحلبي الإيصال B1-2026-011201.',
        'data': {'transaction_id': '77', 'tenant_id': '1'},
        'is_read': false,
        'read_at': null,
        'created_at': '2026-11-04T09:12:00Z',
      }),
    );
    expect(n.ref('transaction_id'), 77);
    expect(n.createdAt, DateTime.utc(2026, 11, 4, 9, 12));
    expect(n.isRead, isFalse);
    expect(n.asRead().isRead, isTrue);
    expect(NotificationLinks.look(n).$2.name, 'danger');
  });

  test('each screen opens its section, with the id when the server sends one', () {
    expect(NotificationLinks.route(note('membership', {'membership_id': 14})), Routes.child(Routes.memberships, 14));
    expect(NotificationLinks.route(note('membership')), Routes.memberships);
    expect(NotificationLinks.route(note('player', {'player_id': 5})), Routes.child(Routes.members, 5));
    expect(NotificationLinks.route(note('transaction', {'transaction_id': 77})), Routes.transactions);
    expect(
      NotificationLinks.route(note('cash_session', {'cash_session_id': '47'})),
      Routes.child(Routes.cashSessions, 47),
    );
    expect(NotificationLinks.route(note('reception_sync')), Routes.receptionDevices);
    expect(NotificationLinks.route(note('billing_invoice')), Routes.billing);
    expect(NotificationLinks.route(note('billing_invoice', {'invoice_id': '7'})), Routes.billingInvoice(7));
    expect(NotificationLinks.route(note('billing')), Routes.billing);
    expect(NotificationLinks.route(note('support_ticket', {'ticket_id': 3})), Routes.supportTicket(3));
    expect(NotificationLinks.route(note('support_ticket')), Routes.billingSupport);
    expect(NotificationLinks.route(note('reception_devices')), Routes.receptionDevices);
    expect(NotificationLinks.route(note('none')), isNull);
    expect(NotificationLinks.route(note('workout_plan')), isNull);
  });

  test('unread count: refresh, decrement, clear; a failed request keeps the last number', () async {
    final repo = FakeNotificationsRepository(count: 3);
    final cubit = UnreadCountCubit(repo)..start();
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state, 3);
    cubit.decrement();
    expect(cubit.state, 2);

    repo.countResult = const ApiFailure(Failure(type: FailureType.network, message: 'تعذّر الاتصال.'));
    await cubit.refresh();
    expect(cubit.state, 2);
    cubit
      ..clear()
      ..decrement();
    expect(cubit.state, 0);
    await cubit.close();
  });

  test('list: mark one read, then all read, locally after the server agrees', () async {
    final repo = FakeNotificationsRepository();
    final cubit = NotificationsListCubit(repo);
    await cubit.load();
    expect(await cubit.markRead(cashLeftOpen), isTrue);
    expect(repo.read, [cashLeftOpen.id]);
    expect(cubit.state.slice.data!.items.first.isRead, isTrue);

    expect(await cubit.markRead(dailySummary), isTrue);
    expect(repo.read, [cashLeftOpen.id], reason: 'already read: no request');

    expect(await cubit.markAllRead(), isA<ApiSuccess<void>>());
    expect(repo.readAll, 1);
    await cubit.close();
  });
}
