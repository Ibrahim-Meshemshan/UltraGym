import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../branches/presentation/bloc/branch_scope_cubit.dart';
import '../../domain/models/member_models.dart';
import '../bloc/members_cubit.dart';
import 'member_actions.dart';

/// إضافة عضو (`POST club-admin/players` مع `Idempotency-Key`)، ثم بيانات الدخول مرة واحدة.
/// رقم له حساب UltraGym مسبقاً يُربط بالنادي بلا كلمة سر جديدة. حد الباقة (`PLAN_LIMIT_REACHED`)
/// ورقم مسجّل أو مؤرشف (409) تظهر رسالتهما أعلى النموذج كما هي.
Future<void> addMember(BuildContext context) async {
  final list = context.read<MembersListCubit>();
  final scope = context.read<BranchScopeCubit>().state;
  final branches = [for (final b in scope.active) (value: b.id, label: b.name)];
  final keys = IdempotencyKeeper();
  final now = DateTime.now();

  final done = await FormDialog.show<NewMember>(
    context,
    title: 'إضافة عضو',
    icon: Icons.person_add_alt_1_rounded,
    submitLabel: 'إضافة',
    initial: {'branch_id': ?(scope.branchId ?? (branches.length == 1 ? branches.first.value : null))},
    fields: (form) => FormColumn(
      children: [
        const FormText('name', label: 'الاسم الكامل', required: true, textInputAction: TextInputAction.next),
        FormText(
          'phone',
          label: 'رقم الموبايل',
          hint: '0944 123 456',
          required: true,
          ltr: true,
          keyboardType: TextInputType.phone,
          validator: Validators.phone(),
        ),
        const FormDropdown<String>('gender', label: 'الجنس', options: MemberFilters.genders, hint: 'اختر'),
        if (branches.length > 1) FormDropdown<int>('branch_id', label: 'الفرع', options: branches, hint: 'اختر الفرع'),
        FormDate(
          'birth_date',
          label: 'تاريخ الميلاد',
          firstDate: DateTime(now.year - 90),
          lastDate: DateTime(now.year, now.month, now.day - 1),
        ),
        const FormText('emergency_contact_name', label: 'اسم جهة الطوارئ'),
        FormText(
          'emergency_contact_phone',
          label: 'موبايل جهة الطوارئ',
          ltr: true,
          keyboardType: TextInputType.phone,
          validator: Validators.phone(optional: true),
        ),
        const FormText('notes', label: 'ملاحظات', maxLines: 3),
      ],
    ),
    onSubmit: (form) {
      final body = form.payload;
      return list.create(body, idempotencyKey: keys.keyFor(body));
    },
  );
  if (done == null || !context.mounted) return;
  refreshMembers(context);
  await showNewMemberCredentials(context, done.data);
}

/// بيانات الدخول بعد الإضافة. الحساب الموجود مسبقاً: رسالة الربط فقط.
Future<void> showNewMemberCredentials(BuildContext context, NewMember m) {
  final password = m.temporaryPassword;
  final expires = m.passwordExpiresAt;
  return CredentialsDialog.show(
    context,
    title: m.isExistingAccount ? 'رُبط حساب ${m.name} بالنادي' : 'تمت إضافة ${m.name}',
    note: password == null
        ? 'لهذا الرقم حساب UltraGym مسبقاً، فيدخل بكلمة سره الحالية.'
        : 'كلمة السر المؤقتة تظهر هنا مرة واحدة فقط، فأرسلها للعضو الآن.',
    validUntil: expires == null ? null : Formatters.date(expires, fromUtc: true),
    lines: [
      (label: 'رقم الموبايل', value: m.phone),
      if (m.memberCode case final code?) (label: 'معرّف العضو', value: code),
      if (password != null) (label: 'كلمة السر المؤقتة', value: password),
    ],
    whatsappPhone: password == null ? null : m.phone,
    whatsappText: m.whatsappMessage,
  );
}
