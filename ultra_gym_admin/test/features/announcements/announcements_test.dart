import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_gym_admin/core/bloc/app_form_cubit.dart';
import 'package:ultra_gym_admin/core/utils/formatters.dart';
import 'package:ultra_gym_admin/features/announcements/domain/models/announcements_models.dart';
import 'package:ultra_gym_admin/features/announcements/presentation/widgets/announcement_actions.dart';
import 'package:ultragym_design/ultragym_design.dart';

import 'fake_announcements_repository.dart';

void main() {
  setUpAll(() => Formatters.init('Asia/Damascus'));

  final rows = announcementRows();
  String plain(String s) => s.split('').where((ch) => !Formatters.ltr('').contains(ch)).join();

  group('Announcement.fromJson', () {
    test('reads the payload, with the branch as {id, name} and null for all branches', () {
      final a = rows.first;
      expect(a.id, 1);
      expect(a.branch, (id: 1, name: 'الفرع الرئيسي - المزة'));
      expect(a.isPublished, isTrue);
      expect(a.pushed, isTrue);
      expect(a.pushRecipients, 12);
      expect(a.expiresAt, DateTime.utc(2026, 11, 16, 20, 59, 59));
      expect(Announcement.fromJson(announcementJson()).branch, isNull);
      expect(rows[1].isDraft, isTrue);
    });
  });

  group('AnnouncementTexts', () {
    test('state badges', () {
      expect(AnnouncementTexts.state('published'), (text: 'منشور', tone: UTone.success));
      expect(AnnouncementTexts.state('draft'), (text: 'مسودة', tone: UTone.neutral));
      expect(AnnouncementTexts.state('expired'), (text: 'منتهٍ', tone: UTone.neutral));
    });

    test('audience, branch and when (club days)', () {
      expect(AnnouncementTexts.audience('all'), 'كل الأعضاء');
      expect(AnnouncementTexts.audience('active'), 'الفعّالون');
      expect(AnnouncementTexts.audience('expired'), 'المنتهية اشتراكاتهم');
      expect(AnnouncementTexts.branch(Announcement.fromJson(announcementJson())), 'كل الفروع');
      expect(plain(AnnouncementTexts.when(rows[0])), 'نُشر 2026-11-02 · حتى 2026-11-16');
      expect(AnnouncementTexts.when(rows[1]), 'لم يُنشر');
      expect(plain(AnnouncementTexts.when(rows[2])), 'انتهى 2026-10-25');
      expect(plain(AnnouncementTexts.when(Announcement.fromJson(announcementJson(expiresAt: null)))), 'نُشر 2026-11-02');
    });

    test('push badge: sent with a count, pending in the background, or nothing', () {
      expect(AnnouncementTexts.push(rows[0]), 'أُرسل إشعاراً لـ 12 عضواً');
      expect(AnnouncementTexts.push(rows[1]), isNull);
      final pending = Announcement.fromJson(announcementJson(pushedAt: null, recipients: null));
      expect(AnnouncementTexts.push(pending), 'الإشعار قيد الإرسال');
      expect(AnnouncementTexts.push(Announcement.fromJson(announcementJson(recipients: null))), 'أُرسل إشعاراً');
    });
  });

  group('AnnouncementActions.bodyOf', () {
    AppFormCubit form(Map<String, Object?> values) => AppFormCubit(
      initial: {
        AnnouncementActions.title: '  مواعيد العيد ',
        AnnouncementActions.body: 'النادي مفتوح أيام العيد.',
        AnnouncementActions.audience: 'active',
        AnnouncementActions.branch: AnnouncementActions.allBranches,
        AnnouncementActions.push: true,
        ...values,
      },
    );

    test('new: trimmed text, all branches = null, push, expiry = end of the club day in UTC, publish flag', () {
      final f = form({AnnouncementActions.expires: DateTime(2026, 11, 12)});
      expect(AnnouncementActions.bodyOf(f, publish: true), {
        'title': 'مواعيد العيد',
        'body': 'النادي مفتوح أيام العيد.',
        'audience': 'active',
        'branch_id': null,
        'send_push': true,
        'expires_at': '2026-11-12T20:59:59.000Z',
        'publish': true,
      });
      final draft = AnnouncementActions.bodyOf(form({AnnouncementActions.branch: 2}), publish: false);
      expect(draft['branch_id'], 2);
      expect(draft['expires_at'], isNull);
      expect(draft['publish'], isFalse);
      addTearDown(f.close);
    });

    test('edit: no publish key for a live one, no push once sent, expiry only when its day changes', () {
      final a = rows.first;
      final same = form({AnnouncementActions.expires: AnnouncementActions.clubDay(a.expiresAt)});
      final body = AnnouncementActions.bodyOf(same, publish: null, existing: a);
      expect(body.containsKey('publish'), isFalse);
      expect(body.containsKey('send_push'), isFalse);
      expect(body.containsKey('expires_at'), isFalse);

      final cleared = AnnouncementActions.bodyOf(form({}), publish: false, existing: a);
      expect(cleared['expires_at'], isNull);
      expect(cleared.containsKey('expires_at'), isTrue);
      expect(cleared['publish'], isFalse);

      final draft = AnnouncementActions.bodyOf(form({}), publish: true, existing: rows[1]);
      expect(draft['send_push'], isTrue);
      expect(draft.containsKey('expires_at'), isFalse, reason: 'no expiry before and none now');
    });

    test('clubDay converts a UTC time to the club calendar day', () {
      expect(AnnouncementActions.clubDay(DateTime.utc(2026, 11, 16, 22)), DateTime(2026, 11, 17));
      expect(AnnouncementActions.clubDay(null), isNull);
      expect(Formatters.clubDayEndUtc(DateTime(2026, 11, 17)), DateTime.utc(2026, 11, 17, 20, 59, 59));
    });
  });
}
