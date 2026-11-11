import 'package:flutter/material.dart';

import '../../../../core/core.dart';

/// حقول نافذة الخطة (`Plans.html`): الاسم، النوع (مدة / حصص)، الصلاحية والحصص والسعر، الفروع (كلها / محددة)،
/// حدود التجميد (فارغة = افتراضي النادي)، الوصف، التدريب الشخصي، والإتاحة للبيع.
class PlanFormFields extends StatelessWidget {
  const PlanFormFields({super.key, required this.branches});

  /// فروع النادي الفعّالة؛ واحد فقط ← لا اختيار فروع (الخطة لكل الفروع).
  final List<({int id, String name})> branches;

  static const name = 'name',
      type = 'type',
      days = 'duration_days',
      sessions = 'sessions_count',
      price = 'price_usd',
      scope = 'branch_scope',
      branchIds = 'branch_ids',
      freezes = 'max_freezes',
      freezeDays = 'max_freeze_days',
      description = 'description',
      personal = 'is_personal_training',
      active = 'active';

  static String? Function(String?) whole(String empty, int min, int max) => (v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return empty.isEmpty ? null : empty;
    final n = int.tryParse(s);
    if (n == null) return 'اكتب رقماً صحيحاً.';
    return n < min || n > max ? 'بين $min و $max.' : null;
  };

  static String? checkPrice(String? v) {
    final n = num.tryParse((v ?? '').replaceAll(',', '').trim());
    if (n == null) return 'اكتب السعر بالدولار.';
    return n < 0 ? 'السعر لا يكون سالباً.' : null;
  }

  @override
  Widget build(BuildContext context) {
    const number = TextInputType.number;
    return FormColumn(
      children: [
        FormText(name, label: 'اسم الخطة', required: true, validator: Validators.required('اكتب اسم الخطة.')),
        const FormChoice<String>(
          type,
          label: 'النوع',
          options: [(value: 'duration', label: 'حسب المدة'), (value: 'sessions', label: 'عدد حصص')],
        ),
        const _TermsRow(),
        if (branches.length > 1) _BranchFields(branches),
        _Row(
          children: [
            FormText(
              freezes,
              label: 'عدد مرات التجميد',
              ltr: true,
              hint: 'افتراضي النادي',
              keyboardType: number,
              validator: whole('', 0, 20),
            ),
            FormText(
              freezeDays,
              label: 'مجموع أيام التجميد',
              ltr: true,
              hint: 'افتراضي النادي',
              keyboardType: number,
              validator: whole('', 0, 365),
            ),
          ],
        ),
        const FormText(description, label: 'الوصف', maxLines: 2, hint: 'مثلاً: دخول يومي للصالة'),
        const FormSwitch(personal, label: 'تدريب شخصي', hint: 'يتطلب مدرباً عند البيع ويحسب عمولته.'),
        const FormSwitch(active, label: 'فعّالة للبيع', hint: 'الموقوفة لا تظهر بالبيع وتبقى اشتراكاتها كما هي.'),
      ],
    );
  }
}

/// الصلاحية و (لخطط الحصص) عدد الحصص والسعر بصف واحد. حقل الحصص يختفي مع تحققه حين تكون الخطة بالمدة.
class _TermsRow extends StatelessWidget {
  const _TermsRow();

  @override
  Widget build(BuildContext context) {
    final sessions = context.select<AppFormCubit, bool>((f) => f.value(PlanFormFields.type) == 'sessions');
    if (!sessions) context.read<AppFormCubit>().validator(PlanFormFields.sessions, null);
    const number = TextInputType.number;
    return _Row(
      children: [
        FormText(
          PlanFormFields.days,
          label: 'الصلاحية بالأيام',
          required: true,
          ltr: true,
          keyboardType: number,
          validator: PlanFormFields.whole('اكتب عدد الأيام.', 1, 3650),
        ),
        if (sessions)
          FormText(
            PlanFormFields.sessions,
            label: 'عدد الحصص',
            required: true,
            ltr: true,
            keyboardType: number,
            validator: PlanFormFields.whole('اكتب عدد الحصص.', 1, 1000),
          ),
        const FormText(
          PlanFormFields.price,
          label: 'السعر بالدولار',
          required: true,
          ltr: true,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          validator: PlanFormFields.checkPrice,
        ),
      ],
    );
  }
}

class _BranchFields extends StatelessWidget {
  const _BranchFields(this.branches);

  final List<({int id, String name})> branches;

  @override
  Widget build(BuildContext context) {
    final selected = context.select<AppFormCubit, bool>((f) => f.value(PlanFormFields.scope) == 'selected');
    if (!selected) context.read<AppFormCubit>().validator(PlanFormFields.branchIds, null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.s2,
      children: [
        const FormChoice<String>(
          PlanFormFields.scope,
          label: 'الفروع',
          options: [(value: 'all', label: 'كل الفروع'), (value: 'selected', label: 'فروع محددة')],
        ),
        if (selected)
          FormChips<int>(
            PlanFormFields.branchIds,
            label: 'الفروع المشمولة',
            required: true,
            options: [for (final b in branches) (value: b.id, label: b.name)],
          ),
      ],
    );
  }
}

/// حقلان أو ثلاثة بصف واحد، ويلتفّون تحت بعض إن ضاق العرض.
class _Row extends StatelessWidget {
  const _Row({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      if (box.maxWidth < AppSize.formFieldMin * children.length) {
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: AppSpace.s4, children: children);
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpace.s3,
        children: [for (final w in children) Expanded(child: w)],
      );
    },
  );
}
