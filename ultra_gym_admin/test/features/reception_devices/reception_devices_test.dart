import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_gym_admin/core/core.dart';
import 'package:ultra_gym_admin/features/reception_devices/domain/models/reception_device_models.dart';
import 'package:ultra_gym_admin/features/reception_devices/presentation/bloc/reception_devices_cubit.dart';

import '../../core/layout/shell_harness.dart';
import '../../helpers/app_fonts.dart';
import 'fake_reception_devices_repository.dart';

void main() {
  setUpAll(() async {
    await loadAppFonts();
    Formatters.init('Asia/Damascus');
  });

  group('models', () {
    final now = DateTime.utc(2026, 11, 11, 10);

    test('device from a real payload', () {
      final d = ReceptionDevice.fromJson(deviceJson());
      expect(d.id, 1);
      expect(d.name, 'كاونتر الاستقبال الرئيسي');
      expect(d.branchId, 1);
      expect(d.branchName, 'الفرع الرئيسي');
      expect(d.isActive, isTrue);
      expect(d.shortUuid, 'e83c…a35b');
      expect(d.lastSyncAt, DateTime.utc(2026, 11, 11, 9, 58));
      expect(d.revoked().isActive, isFalse);
      expect(d.revoked().name, d.name);
    });

    test('texts: status tones, never synced, relative and old dates', () {
      final active = ReceptionDevice.fromJson(deviceJson());
      final fresh = ReceptionDevice.fromJson(deviceJson(lastSync: null, lastPack: null));
      final old = ReceptionDevice.fromJson(deviceJson(lastSync: '2026-09-01T10:00:00Z', status: 'revoked'));
      expect(DeviceTexts.status(active), (label: 'فعّال', tone: UTone.success));
      expect(DeviceTexts.status(old), (label: 'موقوف', tone: UTone.neutral));
      expect(DeviceTexts.sync(active, now), 'قبل دقيقتين');
      expect(DeviceTexts.pack(active, now), 'قبل 3 دقائق');
      expect(DeviceTexts.sync(fresh, now), 'لم يزامن بعد');
      expect(DeviceTexts.pack(fresh, now), 'لم يحمّل بعد');
      expect(DeviceTexts.sync(old, now), Formatters.ltr('2026-09-01'));
    });

    test('cubit sends the branch and the status filter', () async {
      final repo = FakeReceptionDevicesRepository();
      final cubit = ReceptionDevicesCubit(repo, branchId: 2);
      await cubit.load();
      await cubit.filter('status', 'revoked');
      expect(repo.queries.map((q) => q.branchId), [2, 2]);
      expect(repo.queries.last.query.filter('status'), 'revoked');
      expect(cubit.state.slice.data?.items, hasLength(3));
      await cubit.close();
    });
  });

  group('screen', () {
    final h = ShellHarness();
    setUp(() async {
      await h.setUp();
      sl<ServerClock>().sync(DateTime.utc(2026, 11, 11, 10));
    });
    tearDown(h.tearDown);

    Future<void> open(WidgetTester tester, {double width = 1280}) =>
        h.pump(tester, width, at: Routes.receptionDevices);

    Future<void> tap(WidgetTester tester, Finder f) async {
      await tester.ensureVisible(f);
      await tester.tap(f);
      await tester.pumpAndSettle();
    }

    testWidgets('setup steps, rows with times and badges, revoke only on active devices', (tester) async {
      await open(tester);
      expect(find.text('تجهيز جهاز جديد'), findsOneWidget);
      expect(find.text('الأجهزة المسجلة'), findsOneWidget);
      expect(find.text('كاونتر الاستقبال الرئيسي'), findsOneWidget);
      expect(find.text('e83c…a35b'), findsNWidgets(3));
      expect(find.text('قبل دقيقتين'), findsNWidgets(2));
      expect(find.text('لم يزامن بعد'), findsOneWidget);
      expect(find.text('لم يحمّل بعد'), findsOneWidget);
      expect(find.text('موقوف'), findsWidgets);
      expect(find.widgetWithText(TextButton, 'إيقاف'), findsNWidgets(2), reason: 'not on the revoked one');
      expect(h.admin.devices.queries.single.branchId, isNull);
    });

    testWidgets('revoke: danger confirm with last sync, then the list refreshes', (tester) async {
      await open(tester);
      await tap(tester, find.widgetWithText(TextButton, 'إيقاف').first);
      expect(find.text('إيقاف «كاونتر الاستقبال الرئيسي»؟'), findsOneWidget);
      expect(find.text('آخر مزامنة لهذا الجهاز قبل دقيقتين.'), findsOneWidget);
      await tap(tester, find.text('إيقاف الجهاز'));
      expect(h.admin.devices.revoked, [1]);
      expect(find.byType(Dialog), findsNothing);
      expect(h.admin.devices.queries, hasLength(2));

      await tap(tester, find.widgetWithText(TextButton, 'إيقاف').last);
      expect(find.text('لم يزامن هذا الجهاز أي عملية بعد.'), findsOneWidget);
      await tap(tester, find.text('إلغاء'));
      expect(h.admin.devices.revoked, [1]);
    });

    testWidgets('revoke rejected by the server keeps the dialog with its message', (tester) async {
      h.admin.devices.revokeResult = const ApiFailure(
        Failure(type: FailureType.conflict, code: 'CONFLICT', message: 'الجهاز موقوف مسبقاً'),
      );
      await open(tester);
      await tap(tester, find.widgetWithText(TextButton, 'إيقاف').first);
      await tap(tester, find.text('إيقاف الجهاز'));
      expect(find.text('الجهاز موقوف مسبقاً'), findsOneWidget);
      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('branch filter only on all branches; the top-bar branch is sent instead', (tester) async {
      await open(tester);
      await tap(tester, find.text('الفرع: الكل'));
      await tap(tester, find.widgetWithText(MenuItemButton, 'فرع المالكي'));
      expect(h.admin.devices.queries.last.query.filter('branch_id'), 2);

      await tap(tester, find.text('كل الفروع'));
      await tap(tester, find.text('فرع المالكي').last);
      expect(h.admin.devices.queries.last.branchId, 2);
      expect(find.text('الفرع: الكل'), findsNothing);
    });

    testWidgets('status chips filter; empty list invites without a button', (tester) async {
      await open(tester);
      await tap(tester, find.text('موقوف').first);
      expect(h.admin.devices.queries.last.query.filter('status'), 'revoked');

      h.admin.devices.listResult = ApiSuccess(devicesPage(const []));
      await tap(tester, find.text('مسح الفلاتر'));
      expect(find.text('لا أجهزة استقبال بعد'), findsOneWidget);
    });

    testWidgets('error shows retry', (tester) async {
      h.admin.devices.listResult = const ApiFailure(Failure(type: FailureType.server, message: 'خطأ بالخادم'));
      await open(tester);
      expect(find.text('خطأ بالخادم'), findsOneWidget);
      h.admin.devices.listResult = ApiSuccess(devicesPage([deviceJson()]));
      await tap(tester, find.text('إعادة المحاولة'));
      expect(find.text('كاونتر الاستقبال الرئيسي'), findsOneWidget);
    });

    for (final w in [360.0, 800.0, 1024.0, 1440.0]) {
      testWidgets('fits at ${w.toInt()}px', (tester) async {
        await open(tester, width: w);
        expect(find.text('كاونتر الاستقبال الرئيسي'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
