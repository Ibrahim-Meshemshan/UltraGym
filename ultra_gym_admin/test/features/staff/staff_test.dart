import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_gym_admin/core/core.dart';
import 'package:ultra_gym_admin/features/staff/domain/models/staff_models.dart';
import 'package:ultra_gym_admin/features/staff/domain/models/staff_texts.dart';
import 'package:ultra_gym_admin/features/staff/presentation/bloc/staff_cubits.dart';
import 'package:ultra_gym_admin/features/staff/presentation/widgets/staff_member_fields.dart';

import 'fake_staff_repository.dart';

void main() {
  setUpAll(() => Formatters.init('Asia/Damascus'));

  group('models', () {
    test('receptionist reads branches, code and status badge', () {
      final r = Receptionist.fromJson(receptionistJson(mustChange: true));
      expect(r.branches.single.name, 'الفرع الرئيسي');
      expect(r.memberCode, 'DMO-100002');
      expect(r.lastLoginAt, DateTime.utc(2026, 11, 10, 9));
      expect(StaffTexts.reception(r).label, 'بانتظار تغيير كلمة السر');
      expect(StaffTexts.reception(Receptionist.fromJson(receptionistJson(status: 'suspended'))).tone, UTone.danger);
      expect(StaffTexts.reception(Receptionist.fromJson(receptionistJson(status: 'archived'))).label, 'مؤرشف');
      expect(StaffTexts.branches(const []), '—');
    });

    test('created receptionist carries the one-time password', () {
      final c = ReceptionistCreated.fromJson({
        ...receptionistJson(),
        'is_existing_account': true,
        'temporary_password': null,
        'temporary_password_expires_at': null,
        'whatsapp_message': null,
      });
      expect((c.isExistingAccount, c.temporaryPassword, c.account.id), (true, null, 21));
    });

    test('staff member parses string amounts, branch and commission text', () {
      final s = StaffMember.fromJson(staffJson());
      expect((s.salaryAmount, s.branch?.id, s.isTrainer), (300.0, 1, true));
      expect(StaffTexts.salary(s), r'$300.00');
      expect(StaffTexts.commission(s), Formatters.ltr('20%'));
      expect(StaffTexts.commission(StaffMember.fromJson(staffJson(commissionType: 'fixed', fixed: 5))), '${Formatters.ltr(r'$5.00')} لكل عميل');
      expect(StaffTexts.commission(StaffMember.fromJson(staffJson(type: 'worker'))), '—');
      expect(StaffMember.fromJson({...staffJson(), 'branch': null}).branch, isNull);
      expect(StaffTexts.staffStatus(s.asArchived()).label, 'مؤرشف');
    });

    test('account: blocked and shared accounts cannot get a password', () {
      expect(ClubAccount.fromJson(accountJson()).canResetPassword, isTrue);
      expect(ClubAccount.fromJson(accountJson(blocked: 'هذا حسابك')).canResetPassword, isFalse);
      expect(ClubAccount.fromJson(accountJson(shared: true)).canResetPassword, isFalse);
      expect(StaffTexts.stateTone('pending_change'), UTone.warning);
      expect(StaffTexts.stateTone('expired'), UTone.danger);
    });

    test('reset result and print card body', () {
      final r = ResetResult.fromJson({
        'credentials': [credentialJson()],
        'skipped': [
          {'user_id': 1, 'name': 'سامر', 'reason': 'حساب المالك'},
        ],
      });
      expect(r.credentials.single.password, 'Kx7-49QpL');
      expect(r.skipped.single.reason, 'حساب المالك');
      expect(r.credentials.single.card(), {
        'name': 'رنا الخطيب',
        'role_label': 'موظف استقبال',
        'member_code': 'DMO-100002',
        'phone': '+963933100002',
        'temporary_password': 'Kx7-49QpL',
        'expires_at': '2026-11-18T09:00:00Z',
      });
    });

    test('staff usage reads usage.staff', () {
      final u = StaffUsage.fromJson({
        'usage': {
          'staff': {'used': 5, 'limit': 5},
        },
      });
      expect(u.reached, isTrue);
      expect(StaffUsage.fromJson(const {}).limit, isNull);
    });
  });

  group('staff member body', () {
    test('trainer with a fixed commission; worker sends zero commission', () async {
      final f = AppFormCubit(
        initial: StaffMemberFields.initial(StaffMember.fromJson(staffJson(commissionType: 'fixed', fixed: 5))),
      );
      expect(f.value(StaffMemberFields.fixedUsd), '5');
      f.text('salary_amount').text = '1,250';
      var body = StaffMemberFields.body(f);
      expect(body['salary_amount'], 1250);
      expect((body['commission_type'], body['commission_fixed_usd'], body['commission_percent']), ('fixed', 5, 0));
      expect(body['hired_on'], '2026-01-15');
      f.set('type', 'worker');
      body = StaffMemberFields.body(f);
      expect((body['commission_type'], body['commission_fixed_usd'], body['commission_percent']), ('percent', 0, 0));
      await f.close();
    });

    test('a new member defaults to an active trainer in dollars', () async {
      final f = AppFormCubit(initial: StaffMemberFields.initial(null))..set('name', ' سامر ');
      final body = StaffMemberFields.body(f);
      expect(body['type'], 'trainer');
      expect(body['status'], 'active');
      expect(body['salary_currency'], 'USD');
      expect(body['salary_amount'], 0);
      expect(body['hired_on'], isNull);
      await f.close();
    });
  });

  test('cubits pass their query to the repository', () async {
    final repo = FakeStaffRepository();
    final rec = ReceptionistsCubit(repo);
    await rec.load();
    await rec.filter('archived', 'only');
    expect(repo.queries['reception']!.last.toParams()['archived'], 'only');
    final acc = AccountsCubit(repo);
    await acc.load();
    expect(acc.state.slice.data!.summary['never_logged_in'], 1);
    await rec.close();
    await acc.close();
  });
}
