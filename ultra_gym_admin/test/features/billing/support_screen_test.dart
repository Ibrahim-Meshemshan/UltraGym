import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_gym_admin/core/core.dart';
import 'package:ultra_gym_admin/features/billing/domain/models/activity_models.dart';
import 'package:ultra_gym_admin/features/billing/domain/models/support_models.dart';

import '../../core/layout/shell_harness.dart';
import '../../helpers/app_fonts.dart';
import 'fake_billing_repository.dart';

void main() {
  final h = ShellHarness();
  setUpAll(() async {
    await loadAppFonts();
    Formatters.init('Asia/Damascus');
  });
  setUp(h.setUp);
  tearDown(h.tearDown);

  Future<void> open(WidgetTester tester, {double width = 1280, String at = Routes.billingSupport}) =>
      h.pump(tester, width, at: at);

  Future<void> tap(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  Finder field(String name) => find.descendant(
    of: find.byWidgetPredicate((w) => w is FormText && w.name == name),
    matching: find.byType(TextField),
  );

  Future<void> type(WidgetTester tester, String name, String text) async {
    await tester.ensureVisible(field(name).last);
    await tester.enterText(field(name).last, text);
    await tester.pumpAndSettle();
  }

  group('support', () {
    testWidgets('list with badges; the first ticket opens with its messages and reply box', (tester) async {
      await open(tester);
      expect(find.text('الدعم الفني'), findsWidgets);
      expect(find.text('بانتظار ردك'), findsWidgets);
      expect(find.text('سؤال عن الفاتورة'), findsOneWidget);
      expect(h.admin.support.threadCalls, [3]);
      expect(find.text('الطابعة لا تستجيب.'), findsOneWidget);
      expect(find.text('نعمل عليها الآن.'), findsOneWidget);
      expect(find.text('مشكلة تقنية · أولوية متوسطة'), findsOneWidget);
      expect(find.text('ردّك'), findsOneWidget);
    });

    testWidgets('reply: required, then sent with a key; thread and list refresh, box clears', (tester) async {
      await open(tester);
      await tap(tester, find.text('إرسال'));
      expect(find.text('اكتب ردك أولاً.'), findsOneWidget);
      expect(h.admin.support.replyCalls, isEmpty);

      await type(tester, 'message', '  جربنا طابعة أخرى  ');
      await tap(tester, find.text('إرسال'));
      final call = h.admin.support.replyCalls.single;
      expect((call.id, call.message), (3, 'جربنا طابعة أخرى'));
      expect(call.files, isEmpty);
      expect(call.key, isNotNull);
      expect(h.admin.support.threadCalls, [3, 3]);
      expect(h.admin.support.queries, hasLength(2));
      expect(tester.widget<TextField>(field('message')).controller!.text, isEmpty);

      await type(tester, 'message', 'رد ثانٍ');
      await tap(tester, find.text('إرسال'));
      expect(h.admin.support.replyCalls.last.key, isNot(call.key), reason: 'a new reply gets a new key');
    });

    testWidgets('reply rejected (closed meanwhile) shows the server message above the field', (tester) async {
      h.admin.support.replyResult = const ApiFailure(
        Failure(type: FailureType.conflict, code: 'CONFLICT', message: 'التذكرة مغلقة، افتح تذكرة جديدة'),
      );
      await open(tester);
      await type(tester, 'message', 'مرحبا');
      await tap(tester, find.text('إرسال'));
      expect(find.text('التذكرة مغلقة، افتح تذكرة جديدة'), findsOneWidget);
    });

    testWidgets('closed ticket: no reply box, a note instead; status chips filter', (tester) async {
      await open(tester);
      await tap(tester, find.text('سؤال عن الفاتورة'));
      expect(h.admin.support.threadCalls.last, 2);
      expect(find.text('التذكرة مغلقة. افتح تذكرة جديدة لأي طلب آخر.'), findsOneWidget);
      expect(find.text('ردّك'), findsNothing);

      await tap(tester, find.text('محلولة').first);
      expect(h.admin.support.queries.last.filter('status'), 'resolved');
    });

    testWidgets('resolved ticket says a reply reopens it; ?ticket_id= picks it', (tester) async {
      h.admin.support.threads[5] = ApiSuccess(
        h.admin.support.threadOf(ticketJson(id: 5, subject: 'تم الحل', status: 'resolved', awaiting: false)),
      );
      await open(tester, at: Routes.supportTicket(5));
      expect(h.admin.support.threadCalls, [5]);
      expect(find.text('التذكرة محلولة؛ ردّك يعيد فتحها.'), findsOneWidget);
    });

    testWidgets('new ticket: validation, defaults, keyed body, then it opens', (tester) async {
      await open(tester);
      await tap(tester, find.widgetWithText(UGButton, 'تذكرة'));
      expect(find.text('تذكرة دعم جديدة'), findsOneWidget);
      await tap(tester, find.text('إرسال التذكرة'));
      expect(find.text('اكتب عنواناً للتذكرة.'), findsOneWidget);
      expect(find.text('اكتب تفاصيل الطلب.'), findsOneWidget);

      await type(tester, 'subject', 'تعديل الفاتورة');
      await type(tester, 'message', 'نريد تغيير اسم النادي على الفاتورة.');
      await tap(tester, find.text('الاشتراك والفواتير').last);
      await tap(tester, find.text('إرسال التذكرة'));
      final call = h.admin.support.openCalls.single;
      expect(call.fields, {
        'subject': 'تعديل الفاتورة',
        'category': 'billing',
        'priority': 'medium',
        'message': 'نريد تغيير اسم النادي على الفاتورة.',
      });
      expect(call.files, isEmpty);
      expect(call.key, isNotNull);
      expect(find.byType(Dialog), findsNothing);
      expect(h.admin.support.threadCalls.last, 9, reason: 'the new ticket opens');
    });

    testWidgets('new ticket rejected keeps the dialog and the server message', (tester) async {
      h.admin.support.openResult = const ApiFailure(
        Failure(
          type: FailureType.validation,
          message: 'البيانات المدخلة غير صالحة',
          errors: {'subject': ['العنوان طويل جداً']},
        ),
      );
      await open(tester);
      await tap(tester, find.widgetWithText(UGButton, 'تذكرة'));
      await type(tester, 'subject', 'س');
      await type(tester, 'message', 'نص');
      await tap(tester, find.text('إرسال التذكرة'));
      expect(find.text('العنوان طويل جداً'), findsOneWidget);
      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('no tickets: invitation opens the new ticket dialog', (tester) async {
      h.admin.support.ticketsResult = ApiSuccess(pageOf(<SupportTicket>[]));
      await open(tester);
      expect(find.text('لا تذاكر بعد'), findsOneWidget);
      await tap(tester, find.text('فتح تذكرة'));
      expect(find.text('تذكرة دعم جديدة'), findsOneWidget);
    });
  });

  group('activity log', () {
    testWidgets('rows with platform support badge; filters by user, module and search', (tester) async {
      await open(tester, at: Routes.activityLog);
      expect(find.text('تعديل إعدادات النادي'), findsNWidgets(2));
      expect(find.text('دعم UltraGym'), findsOneWidget);
      expect(h.admin.log.queries.single.perPage, 50);

      await tap(tester, find.text('المستخدم: الكل'));
      await tap(tester, find.widgetWithText(MenuItemButton, 'ريم العلي'));
      expect(h.admin.log.queries.last.filter('user_id'), 2);
      await tap(tester, find.text('القسم: الكل'));
      await tap(tester, find.widgetWithText(MenuItemButton, 'الحركات المالية'));
      expect(h.admin.log.queries.last.filter('module'), 'transaction');

      await tester.enterText(find.byType(TextField).first, 'إيراد');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(h.admin.log.queries.last.search, 'إيراد');
    });

    testWidgets('entry dialog: who, when, IP and only the changed fields', (tester) async {
      await open(tester, at: Routes.activityLog);
      await tap(tester, find.text('تعديل إعدادات النادي').first);
      expect(h.admin.log.entries, [206]);
      expect(find.text('127.0.0.1'), findsOneWidget);
      expect(find.text('ما تغيّر'), findsOneWidget);
      expect(find.text('3 ← 5'), findsOneWidget);
      expect(find.text('receipt_footer'), findsNothing);
      await tap(tester, find.text('إغلاق'));
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('users failure hides only that filter; empty log invites', (tester) async {
      h.admin.log
        ..usersResult = const ApiFailure(Failure(type: FailureType.server, message: 'x'))
        ..listResult = ApiSuccess(pageOf(<ActivityEntry>[]));
      await open(tester, at: Routes.activityLog);
      expect(find.text('المستخدم: الكل'), findsNothing);
      expect(find.text('لا نشاط مسجّل بعد'), findsOneWidget);
    });

    testWidgets('tabs switch between the three views', (tester) async {
      await open(tester, at: Routes.billing);
      await tap(tester, find.text('سجل النشاط'));
      expect(find.text('تعديل إعدادات النادي'), findsWidgets);
      await tap(tester, find.text('الدعم الفني'));
      expect(find.text('التذاكر'), findsOneWidget);
    });
  });

  for (final w in [360.0, 800.0, 1024.0, 1440.0]) {
    testWidgets('support and activity fit at ${w.toInt()}px', (tester) async {
      await open(tester, width: w);
      expect(find.text('نعمل عليها الآن.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tap(tester, find.widgetWithText(UGButton, 'تذكرة'));
      expect(tester.takeException(), isNull);
      await tap(tester, find.text('إلغاء'));
      await tap(tester, find.text('سجل النشاط'));
      await tap(tester, find.text('تعديل إعدادات النادي').first);
      expect(tester.takeException(), isNull);
    });
  }
}
