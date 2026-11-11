import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_gym_admin/core/router/routes.dart';
import 'package:ultra_gym_admin/features/quick_search/presentation/widgets/quick_search_button.dart';
import 'package:ultra_gym_admin/features/quick_search/presentation/widgets/quick_search_dialog.dart';

import '../../features/notifications/fake_notifications_repository.dart';
import 'shell_harness.dart';

void main() {
  final h = ShellHarness();
  setUp(h.setUp);
  tearDown(h.tearDown);

  group('quick search', () {
    testWidgets('pill opens the dialog; results show status, debt and refusal; tap opens the member', (tester) async {
      // قسم بلا محتوى (الأعضاء فيه بحث وصفوف بنفس الأسماء)
      await h.pump(tester, 1280, at: pendingRoute);
      // حبة أو أيقونة حسب العرض المتبقي بالشريط (خط الاختبار أعرض من الحقيقي)
      await tester.tap(
        find.descendant(of: find.byType(QuickSearchButton), matching: find.byIcon(Icons.search_rounded)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(QuickSearchDialog), findsOneWidget);
      expect(find.text('اكتب حرفين على الأقل من الاسم أو الموبايل أو معرّف العضو.'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '944');
      await tester.pumpAndSettle();
      expect(h.search.calls.single, ('944', null));
      expect(find.text('أحمد الخطيب'), findsOneWidget);
      expect(find.text('دين \$20.00'), findsOneWidget);
      expect(find.text('انتهى اشتراك العضو. جدّد الاشتراك ثم سجّل الدخول.'), findsOneWidget);

      await tester.tap(find.text('أحمد الخطيب'));
      await tester.pumpAndSettle();
      expect(find.byType(QuickSearchDialog), findsNothing);
      expect(h.location, Routes.child(Routes.members, 3));
    });

    testWidgets('Ctrl K opens it, the chosen branch is sent, and no match is an invitation', (tester) async {
      await h.pump(tester, 1280, at: pendingRoute);
      await tester.tap(find.text('كل الفروع'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('فرع المالكي').last);
      await tester.pumpAndSettle();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(find.byType(QuickSearchDialog), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'زيد');
      await tester.pumpAndSettle();
      expect(h.search.calls.single, ('زيد', 2));
      expect(find.textContaining('لا يوجد عضو يطابق'), findsOneWidget);
    });

    testWidgets('tablet shows a search icon, mobile hides search', (tester) async {
      await h.pump(tester, 800);
      expect(find.byTooltip('بحث عن عضو (Ctrl K)'), findsOneWidget);
      await h.pump(tester, 360);
      expect(find.byTooltip('بحث عن عضو (Ctrl K)'), findsNothing);
      expect(find.byTooltip('الإشعارات، 1 غير مقروءة'), findsOneWidget);
    });
  });

  group('notifications bell', () {
    testWidgets('count badge, panel lists newest first, tap marks read and opens its screen', (tester) async {
      await h.pump(tester, 1280);
      expect(find.byTooltip('الإشعارات، 1 غير مقروءة'), findsOneWidget);

      await tester.tap(find.byTooltip('الإشعارات، 1 غير مقروءة'));
      await tester.pumpAndSettle();
      expect(find.text('الإشعارات · 1 جديدة'), findsOneWidget);
      expect(find.text(cashLeftOpen.title), findsOneWidget);
      expect(find.text(dailySummary.title), findsOneWidget);
      expect(find.text('قبل 5 دقائق'), findsOneWidget);
      expect(find.text('إعدادات الإشعارات'), findsOneWidget);

      await tester.tap(find.text(cashLeftOpen.title));
      await tester.pumpAndSettle();
      expect(h.notifications.read, [cashLeftOpen.id]);
      expect(h.location, Routes.child(Routes.cashSessions, 47));
      expect(find.text(cashLeftOpen.title), findsNothing);
      expect(find.byTooltip('الإشعارات'), findsOneWidget);
    });

    testWidgets('read all clears the counter; receptionist has no settings link', (tester) async {
      await h.pump(tester, 1280, session: receptionist);
      await tester.tap(find.byTooltip('الإشعارات، 1 غير مقروءة'));
      await tester.pumpAndSettle();
      expect(find.text('إعدادات الإشعارات'), findsNothing);

      await tester.tap(find.text('قراءة الكل'));
      await tester.pumpAndSettle();
      expect(h.notifications.readAll, 1);
      expect(find.text('الإشعارات'), findsOneWidget);
    });

    testWidgets('empty list invites, not apologises', (tester) async {
      h.notifications
        ..count = 0
        ..items.clear();
      await h.pump(tester, 1280);
      await tester.tap(find.byTooltip('الإشعارات'));
      await tester.pumpAndSettle();
      expect(find.text('لا إشعارات بعد'), findsOneWidget);
    });
  });
}
