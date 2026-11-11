import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../data/repo/staff_repository.dart';
import '../../domain/models/staff_models.dart';
import '../../domain/models/staff_texts.dart';
import 'issued_credentials_dialog.dart';

/// أفعال حساب الدخول (`club-admin/accounts`) المشتركة بين تبويبي الاستقبال والحسابات. كلها بتأكيد،
/// وكل واحد يرجع true إن تمّ (لتحديث القائمة).
abstract final class AccountActions {
  static StaffRepository get _repo => sl<StaffRepository>();

  /// كلمة سر مؤقتة جديدة لحساب واحد، ثم بياناتها مع الطباعة.
  static Future<bool> newPassword(BuildContext context, {required int userId, required String name}) async {
    final done = await FormDialog.confirm<ResetResult>(
      context,
      title: 'كلمة سر جديدة لـ $name؟',
      message: 'تتوقف كلمة السر الحالية ويخرج من كل أجهزته، ويدخل بالكلمة المؤقتة الجديدة ثم يغيّرها.',
      confirmLabel: 'إصدار كلمة جديدة',
      icon: Icons.key_rounded,
      successMessage: '',
      onConfirm: () => _repo.resetPasswords({
        'user_ids': [userId],
      }),
    );
    if (done == null || !context.mounted) return false;
    await IssuedCredentialsDialog.show(context, done.data);
    return true;
  }

  /// كلمات سر جديدة لمجموعة حسب حالتها (من لم يدخل بعد، أو انتهت كلمته المؤقتة)، ولدور محدد إن مُرّر.
  static Future<bool> bulkReset(BuildContext context, {String? role, int validDays = 7}) async {
    final done = await FormDialog.show<ResetResult>(
      context,
      title: role == 'receptionist' ? 'بطاقات دخول الاستقبال' : 'كلمات سر جديدة لمجموعة',
      icon: Icons.print_rounded,
      submitLabel: 'إصدار الكلمات',
      successMessage: '',
      message:
          'الخادم لا يحفظ كلمات السر، فالبطاقات تُطبع مع كلمات مؤقتة جديدة. تنتهي جلسات من تشملهم، '
          'ويُتخطى حساب المالك وأي حساب مرتبط بنادٍ آخر.',
      initial: {'state': 'never_logged_in', 'role': ?role, 'valid_days': '$validDays'},
      fields: (form) => FormColumn(
        children: [
          const FormChoice<String>('state', label: 'الحسابات', options: StaffTexts.bulkStates),
          if (role == null)
            const FormDropdown<String>('role', label: 'الدور', options: StaffTexts.roles, hint: 'كل الأدوار'),
          FormText(
            'valid_days',
            label: 'صلاحية الكلمة (أيام)',
            ltr: true,
            keyboardType: TextInputType.number,
            validator: (v) {
              final n = int.tryParse((v ?? '').trim());
              return n == null || n < 1 || n > 30 ? 'من 1 إلى 30 يوماً.' : null;
            },
          ),
        ],
      ),
      onSubmit: (form) => _repo.resetPasswords({
        'state': form.value('state'),
        'role': ?form.value('role'),
        'valid_days': int.parse('${form.value('valid_days')}'.trim()),
      }),
    );
    if (done == null || !context.mounted) return false;
    await IssuedCredentialsDialog.show(context, done.data);
    return true;
  }

  static Future<bool> endSessions(BuildContext context, {required int userId, required String name}) async {
    final done = await FormDialog.confirm<void>(
      context,
      title: 'إنهاء جلسات $name؟',
      message: 'يخرج من كل الأجهزة والمتصفحات فوراً، ويدخل من جديد بكلمة سره الحالية.',
      confirmLabel: 'إنهاء الجلسات',
      icon: Icons.logout_rounded,
      onConfirm: () => _repo.endSessions(userId),
    );
    return done != null;
  }

  /// معرّف دخول جديد (`PREFIX-123456`): القديم يتوقف فوراً.
  static Future<bool> regenerateCode(BuildContext context, {required int userId, required String name}) async {
    final done = await FormDialog.confirm<void>(
      context,
      title: 'معرّف جديد لـ $name؟',
      message: 'يتوقف المعرّف الحالي عن الدخول وعن مسح بطاقته، ويدخل بالمعرّف الجديد أو برقم موبايله.',
      confirmLabel: 'إصدار معرّف جديد',
      icon: Icons.badge_outlined,
      onConfirm: () => _repo.regenerateCode(userId),
    );
    return done != null;
  }
}

/// عناصر قائمة الحساب (كلمة سر، معرّف، جلسات). `blocked` من الخادم يعطّلها مع سببه كتلميح.
List<Widget> accountMenuItems(
  BuildContext context, {
  required int userId,
  required String name,
  required VoidCallback onDone,
  bool canReset = true,
}) {
  Future<void> run(Future<bool> Function() action) async {
    if (await action()) onDone();
  }

  return [
    MenuItemButton(
      leadingIcon: const Icon(Icons.key_rounded, size: AppSize.iconSm),
      onPressed: canReset ? () => run(() => AccountActions.newPassword(context, userId: userId, name: name)) : null,
      child: const Text('كلمة سر جديدة'),
    ),
    MenuItemButton(
      leadingIcon: const Icon(Icons.badge_outlined, size: AppSize.iconSm),
      onPressed: canReset
          ? () => run(() => AccountActions.regenerateCode(context, userId: userId, name: name))
          : null,
      child: const Text('معرّف جديد'),
    ),
    MenuItemButton(
      leadingIcon: const Icon(Icons.logout_rounded, size: AppSize.iconSm),
      onPressed: () => run(() => AccountActions.endSessions(context, userId: userId, name: name)),
      child: const Text('إنهاء الجلسات'),
    ),
  ];
}
