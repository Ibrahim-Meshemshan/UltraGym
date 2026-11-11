import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_gym_super_admin/core/utils/validators.dart';
import 'package:ultra_gym_super_admin/features/auth/domain/models/auth_models.dart';

/// أشكال الردود الحقيقية من الباك اند (commit 32b0294): AuthController و SuperAdminAuthController.
void main() {
  group('Session.fromJson', () {
    test('club login: account under user, roles and permissions', () {
      final s = Session.fromJson({
        'requires_tenant_selection': false,
        'token': 't',
        'expires_at': '2027-01-31T08:00:00Z',
        'must_change_password': false,
        'user': {'id': 41, 'name': 'سامر الحلبي', 'phone': '+963933000041'},
        'member_code': 'QMA-482913',
        'tenant': {'id': 12, 'name': 'نادي القمة الرياضي', 'slug': 'qimma', 'logo_url': null},
        'roles': ['club_owner'],
        'permissions': {'can_view_finance': true, 'can_manage_staff': false},
        'other_tenants_count': 1,
      });
      expect(s.user.name, 'سامر الحلبي');
      expect(s.isClubOwner, isTrue);
      expect(s.canViewFinance, isTrue);
      expect(s.canManageStaff, isFalse);
      expect(s.canSwitchTenant, isTrue);
      expect(s.tenant!.slug, 'qimma');
    });

    test('club me: impersonation and session.expires_at', () {
      final s = Session.fromJson({
        'user': {'id': 41, 'name': 'سامر'},
        'tenant': {'id': 12, 'name': 'نادي القمة'},
        'roles': ['receptionist'],
        'permissions': {},
        'is_impersonated': true,
        'session': {'expires_at': '2027-01-31T08:00:00Z'},
      });
      expect(s.isReceptionist, isTrue);
      expect(s.isImpersonated, isTrue);
      expect(s.expiresAt, DateTime.utc(2027, 1, 31, 8));
    });

    test('platform login: account under admin with its role', () {
      final s = Session.fromJson({
        'token': 't',
        'token_type': 'Bearer',
        'expires_at': '2027-01-31T08:00:00Z',
        'must_change_password': true,
        'admin': {'id': 1, 'name': 'مالك المنصة', 'phone': '+963911000001', 'role': 'owner', 'must_change_password': true},
      });
      expect(s.user.name, 'مالك المنصة');
      expect(s.roles, ['owner']);
      expect(s.isPlatformOwner, isTrue);
      expect(s.mustChangePassword, isTrue);
      expect(s.tenant, isNull);
    });

    test('platform me: account at the root with role', () {
      final s = Session.fromJson({'id': 2, 'name': 'مشرف', 'role': 'admin', 'must_change_password': false});
      expect(s.user.name, 'مشرف');
      expect(s.roles, ['admin']);
      expect(s.isPlatformOwner, isFalse);
    });
  });

  group('Validators.newPassword (server rule)', () {
    final check = Validators.newPassword();

    test('needs length, a letter and a digit', () {
      expect(check(''), isNotNull);
      expect(check('abc1'), isNotNull);
      expect(check('abcdefgh'), isNotNull);
      expect(check('12345678'), isNotNull);
      expect(check('abcd1234'), isNull);
      expect(check('كلمةسر2026'), isNull);
    });

    test('respects a higher platform minimum', () {
      expect(Validators.newPassword(minLength: 10)('abcd1234'), isNotNull);
    });
  });
}
