import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../branches/presentation/bloc/branch_scope_cubit.dart';
import '../../domain/models/member_models.dart';
import '../../domain/models/member_profile_models.dart';
import '../bloc/member_profile_cubit.dart';

/// عمليات ملف العضو: كل واحدة بنافذة (`FormDialog`)، ثم رسالة الخادم وتحديث صامت للملف.
/// المالك والاستقبال معاً (الخادم يقيّد الاستقبال بفروعه).

/// تعديل البيانات: `PATCH players/{id}` بكل الحقول (الفارغ يُرسل null فيُمسح).
Future<void> editMember(BuildContext context, MemberProfile p) async {
  final cubit = context.read<MemberProfileCubit>();
  final branches = [for (final b in context.read<BranchScopeCubit>().state.active) (value: b.id, label: b.name)];
  final now = DateTime.now();
  final done = await FormDialog.show<void>(
    context,
    title: 'تعديل بيانات ${p.name}',
    icon: Icons.edit_rounded,
    initial: p.formValues,
    fields: (form) => FormColumn(
      children: [
        const FormText('name', label: 'الاسم الكامل', required: true),
        FormText(
          'phone',
          label: 'رقم الموبايل',
          required: true,
          ltr: true,
          keyboardType: TextInputType.phone,
          validator: Validators.phone(),
        ),
        FormText('email', label: 'البريد الإلكتروني', ltr: true, validator: Validators.email(optional: true)),
        const FormDropdown<String>('gender', label: 'الجنس', options: MemberFilters.genders, hint: 'اختر'),
        if (branches.length > 1) FormDropdown<int>('branch_id', label: 'الفرع', options: branches, hint: 'اختر الفرع'),
        FormDate(
          'birth_date',
          label: 'تاريخ الميلاد',
          firstDate: DateTime(now.year - 90),
          lastDate: DateTime(now.year, now.month, now.day - 1),
        ),
        const FormText('address', label: 'العنوان'),
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
    onSubmit: (form) => cubit.update(form.apiBody(keepNulls: true)),
  );
  if (done != null) await cubit.refresh();
}

/// إيقاف الحساب بسبب إلزامي: يُرفض دخوله للنادي ("حساب موقوف") واشتراكاته تبقى.
Future<void> suspendMember(BuildContext context, MemberProfile p) async {
  final cubit = context.read<MemberProfileCubit>();
  final done = await FormDialog.show<void>(
    context,
    title: 'إيقاف ${p.name}',
    icon: Icons.block_rounded,
    message: 'يُرفض دخوله للنادي بسبب "حساب موقوف" حتى تعيد تفعيله. اشتراكاته تبقى كما هي.',
    submitLabel: 'إيقاف العضو',
    danger: true,
    fields: (form) =>
        const FormColumn(children: [FormText('reason', label: 'السبب', required: true, maxLines: 3, autofocus: true)]),
    onSubmit: (form) => cubit.suspend('${form.value('reason') ?? ''}'.trim()),
  );
  if (done != null) await cubit.refresh();
}

Future<void> activateMember(BuildContext context, MemberProfile p) async {
  final cubit = context.read<MemberProfileCubit>();
  final done = await FormDialog.confirm<void>(
    context,
    title: 'تفعيل ${p.name}؟',
    message: 'يعود دخوله للنادي حسب اشتراكه، ويُمسح سبب الإيقاف.',
    confirmLabel: 'تفعيل',
    icon: Icons.check_circle_outline_rounded,
    danger: false,
    onConfirm: cubit.activate,
  );
  if (done != null) await cubit.refresh();
}

/// كلمة سر مؤقتة جديدة (7 أيام): تُلغى الحالية ويخرج من التطبيق، ثم تظهر مرة واحدة للإرسال.
Future<void> resetMemberPassword(BuildContext context, MemberProfile p) async {
  final cubit = context.read<MemberProfileCubit>();
  final done = await FormDialog.confirm<NewMember>(
    context,
    title: 'كلمة سر جديدة لـ${p.name}؟',
    message: 'تتوقف كلمة سره الحالية ويخرج من التطبيق على كل أجهزته، ثم تظهر كلمة سر مؤقتة ترسلها له.',
    confirmLabel: 'إنشاء كلمة سر',
    icon: Icons.key_rounded,
    danger: false,
    onConfirm: cubit.resetPassword,
  );
  if (done == null || !context.mounted) return;
  final creds = done.data;
  final password = creds.temporaryPassword;
  await CredentialsDialog.show(
    context,
    title: 'كلمة سر مؤقتة لـ${p.name}',
    note: 'تظهر هنا مرة واحدة فقط، ويُطلب منه تغييرها عند أول دخول.',
    validUntil: switch (creds.passwordExpiresAt) {
      final d? => Formatters.date(d, fromUtc: true),
      null => null,
    },
    lines: [
      (label: 'رقم الموبايل', value: creds.phone.isEmpty ? p.phone : creds.phone),
      if (creds.memberCode ?? p.memberCode case final code?) (label: 'معرّف العضو', value: code),
      if (password != null) (label: 'كلمة السر المؤقتة', value: password),
    ],
    whatsappPhone: password == null ? null : p.phone,
    whatsappText: creds.whatsappMessage,
  );
  await cubit.refresh();
}

/// صورة العضو (تظهر بشاشة الاستقبال عند الدخول): png / jpg / webp حتى 3MB.
Future<void> changeMemberPhoto(BuildContext context) async {
  final cubit = context.read<MemberProfileCubit>();
  final picked = await FilePick.image();
  if (picked == null) return;
  if (picked.error case final error?) return AppSnackbar.show(error);
  final r = await cubit.uploadPhoto(picked.form('photo'));
  switch (r) {
    case ApiSuccess(:final message):
      AppSnackbar.show(message ?? 'تم تحديث الصورة.');
      await cubit.refresh();
    case ApiFailure(:final failure):
      AppSnackbar.show(failure.message);
  }
}
