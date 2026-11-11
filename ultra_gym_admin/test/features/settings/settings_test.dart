import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_gym_admin/core/bloc/app_form_cubit.dart';
import 'package:ultra_gym_admin/core/error/failure.dart';
import 'package:ultra_gym_admin/core/networking/api_result.dart';
import 'package:ultra_gym_admin/features/settings/domain/models/branch_draft.dart';
import 'package:ultra_gym_admin/features/settings/domain/models/settings_models.dart';
import 'package:ultra_gym_admin/features/settings/presentation/bloc/settings_cubits.dart';
import 'package:ultra_gym_admin/features/settings/presentation/widgets/club_form.dart';

import 'fake_settings_repository.dart';

void main() {
  group('models', () {
    test('club profile reads contact, settings and the branch limit', () {
      final c = ClubProfile.fromJson(clubJson());
      expect(c.name, 'نادي الأبطال');
      expect(c.contactPhone, '+963112223344');
      expect(c.settings.graceDays, 3);
      expect(c.settings.duplicateCheckInMinutes, 120);
      expect(c.settings.dayPassPriceUsd, 5);
      expect(c.settings.weekendDays, ['friday']);
      expect((c.branchesUsed, c.branchesLimit, c.branchLimitReached), (2, 10, false));
      expect(ClubProfile.fromJson(clubJson(used: 3, limit: 3)).branchLimitReached, isTrue);
      expect(ClubProfile.fromJson(clubJson(limit: null)).branchLimitReached, isFalse);
    });

    test('notification catalog groups by audience in order, with platform labels', () {
      final c = NotificationCatalog.fromJson(catalogJson());
      expect(c.groups.map((g) => g.label), ['المالك', 'المالك والاستقبال', 'العضو']);
      expect(c.groups.first.types.single.type, 'cash_session_closed');
      expect(c.platform, ['فواتير المنصة']);
    });

    test('branch parses its schedule and overnight slots', () {
      final b = settingsBranches()[1];
      expect(b.timeSplit, isTrue);
      expect(b.schedule.map((s) => s.overnight), [false, true]);
      expect(b.schedule.first.daysLabel, 'السبت، الإثنين، الأربعاء');
    });

    test('day-end and policy texts', () {
      expect(SettingsTexts.dayEnd(0), 'منتصف الليل');
      expect(SettingsTexts.dayEnd(2), '2 فجراً');
      expect(SettingsTexts.dayEnd(6), '6 صباحاً');
      expect(SettingsTexts.timezones('Europe/Berlin').last.value, 'Europe/Berlin');
      expect(SettingsTexts.timezones('Asia/Damascus').where((z) => z.value == 'Asia/Damascus'), hasLength(1));
    });
  });

  group('branch draft', () {
    test('normalises times and sends days in week order', () {
      expect(BranchDraft.time('8:00'), '08:00');
      expect(BranchDraft.time('24:00'), isNull);
      expect(BranchDraft.time('8'), isNull);
      const slot = SlotDraft(uid: 1, days: ['wednesday', 'saturday'], from: '8:00', to: '1:30', gender: 'male');
      expect(slot.overnight, isTrue);
      expect(slot.body(), {
        'days': ['saturday', 'wednesday'],
        'from': '08:00',
        'to': '01:30',
        'gender': 'male',
      });
    });

    test('mixed leaves the saved schedule untouched; time_split sends it', () {
      final d = BranchDraft.of(settingsBranches()[1]);
      expect(d.copyWith(policy: 'mixed').body().containsKey('gender_schedule'), isFalse);
      final body = d.copyWith(price: '7.5', phone: ' ').body();
      expect(body['gender_schedule'], hasLength(2));
      expect(body['day_pass_price_usd'], 7.5);
      expect(body['phone'], isNull);
      expect(BranchDraft.of(settingsBranches()[0]).body()['day_pass_price_usd'], isNull);
    });

    test('validates with server keys', () {
      const bad = BranchDraft(
        price: 'abc',
        policy: 'time_split',
        slots: [
          SlotDraft(uid: 1, from: '9', to: '14:00'),
          SlotDraft(uid: 2, days: ['friday'], from: '10:00', to: '10:00'),
        ],
      );
      expect(bad.validate(), {
        'name': 'اكتب اسم الفرع.',
        'day_pass_price_usd': 'اكتب السعر بالأرقام، أو اتركه فارغاً لسعر النادي.',
        'gender_schedule.0.days': 'اختر يوماً واحداً على الأقل.',
        'gender_schedule.0.from': 'الوقت بصيغة 08:00.',
        'gender_schedule.1.to': 'النهاية غير البداية.',
      });
      expect(const BranchDraft(name: 'x', policy: 'time_split').validate(), {
        'gender_schedule': 'أضف فترة واحدة على الأقل، أو اختر "مختلط".',
      });
    });
  });

  group('club form', () {
    final club = ClubProfile.fromJson(clubJson());

    test('initial values round-trip to unchanged bodies', () {
      final v = ClubForm.initial(club);
      expect(ClubForm.clubBody((k) => v[k]), {
        'contact_phone': '+963112223344',
        'contact_email': 'info@demo.test',
        'city': 'دمشق',
        'address': 'المزة، شارع الجلاء',
      });
      final s = ClubForm.settingsBody((k) => v[k]);
      expect(s['membership_grace_days'], 3);
      expect(s['day_pass_price_usd'], 5);
      expect(s['weekend_days'], ['friday']);
      expect(s['disabled_notifications'], isEmpty);
    });

    test('save sends nothing without changes', () async {
      final repo = FakeSettingsRepository();
      final f = AppFormCubit(initial: ClubForm.initial(club));
      final r = await ClubForm.save(repo, f, club);
      expect((r as ApiSuccess).message, 'لا تغييرات للحفظ.');
      expect(repo.clubBodies, isEmpty);
      expect(repo.settingsBodies, isEmpty);
      await f.close();
    });

    test('save sends only the changed request; cleared text goes as null', () async {
      final repo = FakeSettingsRepository();
      final f = AppFormCubit(initial: ClubForm.initial(club));
      f.text('city').text = '';
      expect((await ClubForm.save(repo, f, club) as ApiSuccess).message, 'تم حفظ الإعدادات.');
      expect(repo.clubBodies.single['city'], isNull);
      expect(repo.settingsBodies, isEmpty);

      f
        ..set('weekend_days', ['friday', 'saturday'])
        ..set(ClubForm.disabled, ['membership_expiring', 'cash_session_closed']);
      final club2 = ClubProfile.fromJson({...clubJson(), 'city': null});
      await ClubForm.save(repo, f, club2);
      expect(repo.clubBodies, hasLength(1));
      expect(repo.settingsBodies.single['weekend_days'], ['saturday', 'friday']);
      expect(repo.settingsBodies.single['disabled_notifications'], ['cash_session_closed', 'membership_expiring']);
      await f.close();
    });

    test('more than three weekend days fails locally on the field', () async {
      final repo = FakeSettingsRepository();
      final f = AppFormCubit(initial: ClubForm.initial(club))
        ..set('weekend_days', ['thursday', 'friday', 'saturday', 'sunday']);
      final r = await ClubForm.save(repo, f, club);
      expect((r as ApiFailure).failure.fieldError('weekend_days'), 'اختر 3 أيام عطلة على الأكثر.');
      expect(repo.settingsBodies, isEmpty);
      await f.close();
    });
  });

  group('branch editor cubit', () {
    test('switching to time_split starts with a blank slot; slot edits clear their error', () {
      final cubit = BranchEditorCubit(FakeSettingsRepository(), BranchDraft.of(settingsBranches()[0]))
        ..setPolicy('time_split');
      expect(cubit.state.draft.slots, hasLength(1));
      final uid = cubit.state.draft.slots.single.uid;
      cubit
        ..setFrom(uid, '07:00')
        ..toggleDay(uid, 'friday')
        ..setGender(uid, 'female');
      final s = cubit.state.draft.slots.single;
      expect((s.from, s.days.contains('friday'), s.gender), ('07:00', true, 'female'));
      cubit.removeSlot(uid);
      expect(cubit.state.draft.slots, isEmpty);
    });

    test('local errors stop the request', () async {
      final repo = FakeSettingsRepository();
      final cubit = BranchEditorCubit(repo, const BranchDraft());
      expect(await cubit.save(), isNull);
      expect(cubit.state.error('name'), 'اكتب اسم الفرع.');
      expect(repo.savedBranches, isEmpty);
      cubit.setName('فرع');
      expect(cubit.state.error('name'), isNull);
    });

    test('a new branch posts with a key, an existing one patches without', () async {
      final repo = FakeSettingsRepository();
      final add = BranchEditorCubit(repo, const BranchDraft())..setName('فرع جديد');
      expect((await add.save())?.name, 'فرع جديد');
      expect(repo.savedBranches.single.key, isNotNull);
      expect(repo.savedBranches.single.id, isNull);
      final edit = BranchEditorCubit(repo, BranchDraft.of(settingsBranches()[1]))..setCity('حلب');
      await edit.save();
      expect(repo.savedBranches.last.id, 2);
      expect(repo.savedBranches.last.key, isNull);
      expect(repo.savedBranches.last.body['city'], 'حلب');
    });

    test('422 errors land under their server keys', () async {
      final repo = FakeSettingsRepository()
        ..saveBranchResult = const ApiFailure(
          Failure(
            type: FailureType.validation,
            message: 'البيانات المدخلة غير صالحة',
            errors: {
              'name': ['يوجد فرع بنفس الاسم'],
              'gender_schedule.1.to': ['وقت غير صالح'],
            },
          ),
        );
      final cubit = BranchEditorCubit(repo, BranchDraft.of(settingsBranches()[1]));
      expect(await cubit.save(), isNull);
      expect(cubit.state.error('name'), 'يوجد فرع بنفس الاسم');
      expect(cubit.state.error('gender_schedule.1.to'), 'وقت غير صالح');
      expect(cubit.state.saving, isFalse);
    });
  });
}
