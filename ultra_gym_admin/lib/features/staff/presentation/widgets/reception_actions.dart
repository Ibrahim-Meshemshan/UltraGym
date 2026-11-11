import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../data/repo/staff_repository.dart';
import '../../domain/models/staff_models.dart';
import 'account_actions.dart';

/// فروع النادي الفعّالة كخيارات (تُقرأ من سياق الشاشة قبل فتح النافذة: النوافذ خارج الهيكل).
typedef BranchOptions = List<FormOption<int>>;

/// أفعال حساب الاستقبال (`club-admin/receptionists`). كل فعل يرجع true إن تمّ.
abstract final class ReceptionActions {
  static StaffRepository get _repo => sl<StaffRepository>();

  /// حساب جديد بفروعه (`Idempotency-Key`)، ثم بيانات الدخول مرة واحدة. رقم له حساب مسبقاً يُربط به،
  /// ورقم استقبال حالي أو مؤرشف (409) وحد الباقة (`PLAN_LIMIT_REACHED`) رسالتهما أعلى النموذج.
  static Future<bool> add(BuildContext context, BranchOptions branches) async {
    final keys = IdempotencyKeeper();
    final done = await FormDialog.show<ReceptionistCreated>(
      context,
      title: 'حساب استقبال جديد',
      icon: Icons.person_add_alt_1_rounded,
      submitLabel: 'إنشاء الحساب',
      message: 'إن كان الرقم مسجلاً بحساب سابق يُربط به. تُولَّد كلمة سر مؤقتة صالحة 7 أيام.',
      initial: {
        if (branches.length == 1) 'branch_ids': [branches.single.value],
      },
      fields: (_) => _fields(branches, withBranches: true),
      onSubmit: (form) {
        final body = _body(form)..['branch_ids'] = _ids(form);
        return _repo.addReceptionist(body, idempotencyKey: keys.keyFor(body));
      },
    );
    if (done == null || !context.mounted) return false;
    await _credentials(context, done.data);
    return true;
  }

  static Future<bool> edit(BuildContext context, Receptionist r) async {
    final done = await FormDialog.show<Receptionist>(
      context,
      title: 'تعديل ${r.name}',
      icon: Icons.edit_rounded,
      initial: {'name': r.name, 'phone': r.phone, 'email': r.email},
      fields: (_) => _fields(const [], withBranches: false),
      onSubmit: (form) => _repo.updateReceptionist(r.id, _body(form)),
    );
    return done != null;
  }

  static Future<bool> branches(BuildContext context, Receptionist r, BranchOptions branches) async {
    final done = await FormDialog.show<void>(
      context,
      title: 'فروع ${r.name}',
      icon: Icons.store_mall_directory_outlined,
      message: 'يرى ويعمل بهذه الفروع فقط: أعضاؤها وصناديقها وحضورها.',
      initial: {
        'branch_ids': [for (final b in r.branches) b.id],
      },
      fields: (_) => FormColumn(
        children: [FormChips<int>('branch_ids', label: 'الفروع', required: true, options: _with(branches, r))],
      ),
      onSubmit: (form) => _repo.setReceptionistBranches(r.id, _ids(form)),
    );
    return done != null;
  }

  static Future<bool> suspend(BuildContext context, Receptionist r) async {
    final done = await FormDialog.show<void>(
      context,
      title: 'إيقاف حساب ${r.name}؟',
      icon: Icons.block_rounded,
      danger: true,
      submitLabel: 'إيقاف الحساب',
      message: 'لا يستطيع الدخول للوحة ولا لشاشة الاستقبال حتى تفعّله، ويبقى سجله كما هو.',
      fields: (_) => const FormColumn(
        children: [FormText('reason', label: 'السبب', required: true, maxLines: 2)],
      ),
      onSubmit: (form) => _repo.suspendReceptionist(r.id, '${form.value('reason')}'.trim()),
    );
    return done != null;
  }

  static Future<bool> activate(BuildContext context, Receptionist r) async => await FormDialog.confirm<void>(
    context,
    title: 'تفعيل حساب ${r.name}؟',
    message: 'يعود للدخول بكلمة سره الحالية.',
    confirmLabel: 'تفعيل',
    icon: Icons.check_circle_outline_rounded,
    danger: false,
    onConfirm: () => _repo.activateReceptionist(r.id),
  ) != null;

  static Future<bool> archive(BuildContext context, Receptionist r) async => await FormDialog.confirm<void>(
    context,
    title: 'أرشفة ${r.name}؟',
    message: 'يتوقف دخوله ويختفي من القائمة، ويبقى سجل عملياته. يمكنك استرجاعه من الأرشيف.',
    confirmLabel: 'أرشفة',
    icon: Icons.inventory_2_outlined,
    onConfirm: () => _repo.archiveReceptionist(r.id),
  ) != null;

  static Future<bool> restore(BuildContext context, Receptionist r) async => await FormDialog.confirm<void>(
    context,
    title: 'استرجاع ${r.name}؟',
    message: 'يعود حسابه بفروعه، ويُحسب ضمن حد الموظفين بالباقة.',
    confirmLabel: 'استرجاع',
    icon: Icons.restore_rounded,
    danger: false,
    onConfirm: () => _repo.restoreReceptionist(r.id),
  ) != null;

  static Widget _fields(BranchOptions branches, {required bool withBranches}) => FormColumn(
    children: [
      const FormText('name', label: 'الاسم الكامل', required: true, textInputAction: TextInputAction.next),
      FormText(
        'phone',
        label: 'رقم الموبايل',
        hint: '0944 123 456',
        required: true,
        ltr: true,
        keyboardType: TextInputType.phone,
        validator: Validators.all([Validators.required('اكتب رقم الموبايل.'), Validators.phone()]),
      ),
      FormText('email', label: 'البريد الإلكتروني (اختياري)', ltr: true, validator: Validators.email()),
      if (withBranches && branches.length > 1)
        FormChips<int>('branch_ids', label: 'الفروع المسموحة', required: true, options: branches),
    ],
  );

  static Json _body(AppFormCubit form) => {
    'name': '${form.value('name') ?? ''}'.trim(),
    'phone': '${form.value('phone') ?? ''}'.trim(),
    'email': _text(form.value('email')),
  };

  static List<int> _ids(AppFormCubit form) => [...?(form.value('branch_ids') as List<dynamic>?)?.whereType<int>()];

  /// فروع الحساب الحالية تبقى خياراً حتى لو أُوقف الفرع.
  static BranchOptions _with(BranchOptions active, Receptionist r) => [
    ...active,
    for (final b in r.branches)
      if (!active.any((o) => o.value == b.id)) (value: b.id, label: b.name),
  ];

  static String? _text(Object? v) {
    final s = '${v ?? ''}'.trim();
    return s.isEmpty ? null : s;
  }

  static Future<void> _credentials(BuildContext context, ReceptionistCreated x) {
    final a = x.account;
    final password = x.temporaryPassword;
    return CredentialsDialog.show(
      context,
      title: x.isExistingAccount ? 'رُبط حساب ${a.name} بالاستقبال' : 'تم إنشاء حساب ${a.name}',
      note: password == null
          ? 'لهذا الرقم حساب UltraGym مسبقاً، فيدخل بكلمة سره الحالية.'
          : 'كلمة السر المؤقتة تظهر هنا مرة واحدة فقط، فأرسلها الآن. يغيّرها عند أول دخول.',
      validUntil: x.expiresAt == null ? null : Formatters.date(x.expiresAt, fromUtc: true),
      lines: [
        (label: 'رقم الموبايل', value: a.phone),
        if (a.memberCode.isNotEmpty) (label: 'المعرّف', value: a.memberCode),
        if (password != null) (label: 'كلمة السر المؤقتة', value: password),
      ],
      whatsappPhone: password == null ? null : a.phone,
      whatsappText: x.whatsappMessage,
    );
  }
}

/// قائمة ⋯ لصف حساب الاستقبال. المؤرشف: الاسترجاع فقط.
class ReceptionRowMenu extends StatelessWidget {
  const ReceptionRowMenu(this.r, {super.key, required this.branches, required this.onDone});

  final Receptionist r;
  final BranchOptions branches;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Future<void> run(Future<bool> Function() action) async {
      if (await action()) onDone();
    }

    MenuItemButton item(IconData icon, String label, Future<bool> Function() action, {bool danger = false}) =>
        MenuItemButton(
          leadingIcon: Icon(icon, size: AppSize.iconSm, color: danger ? c.dangerInk : null),
          onPressed: () => run(action),
          child: Text(label, style: danger ? UType.body(color: c.dangerInk) : null),
        );

    return MenuAnchor(
      menuChildren: r.isArchived
          ? [item(Icons.restore_rounded, 'استرجاع', () => ReceptionActions.restore(context, r))]
          : [
              item(Icons.edit_rounded, 'تعديل البيانات', () => ReceptionActions.edit(context, r)),
              item(Icons.store_mall_directory_outlined, 'الفروع', () => ReceptionActions.branches(context, r, branches)),
              ...accountMenuItems(context, userId: r.id, name: r.name, onDone: onDone),
              if (r.isSuspended)
                item(Icons.check_circle_outline_rounded, 'تفعيل', () => ReceptionActions.activate(context, r))
              else
                item(Icons.block_rounded, 'إيقاف', () => ReceptionActions.suspend(context, r), danger: true),
              item(Icons.inventory_2_outlined, 'أرشفة', () => ReceptionActions.archive(context, r), danger: true),
            ],
      builder: (context, menu, _) => IconButton(
        tooltip: 'إجراءات ${r.name}',
        onPressed: () => menu.isOpen ? menu.close() : menu.open(),
        icon: Icon(Icons.more_horiz_rounded, color: c.inkMuted),
      ),
    );
  }
}
