import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../domain/models/staff_models.dart';
import '../../domain/models/staff_texts.dart';

/// حقول نافذة المدرب أو العامل (`Staff.html`): النوع، الاسم والمسمى، الفرع وتاريخ التعيين، الراتب وعملته،
/// الموبايل، العمولة (للمدرب فقط: نسبة أو مبلغ ثابت لكل عميل)، الحالة بالتعديل، والملاحظات.
class StaffMemberFields extends StatelessWidget {
  const StaffMemberFields({super.key, required this.branches, required this.editing});

  final List<FormOption<int>> branches;
  final bool editing;

  /// حقلا العمولة بمفتاحي الخادم (فيظهر 422 تحت الحقل نفسه)؛ الظاهر حسب النوع.
  static const percent = 'commission_percent', fixedUsd = 'commission_fixed_usd';

  static String commissionField({required bool fixed}) => fixed ? fixedUsd : percent;

  static Json initial(StaffMember? s) => {
    'type': s?.type ?? 'trainer',
    'name': s?.name,
    'job_title': s?.jobTitle,
    'branch_id': s?.branch?.id,
    'hired_on': ?(s?.hiredOn == null ? null : DateTime.tryParse(s!.hiredOn!)),
    'salary_amount': s == null || s.salaryAmount == 0 ? null : _plain(s.salaryAmount),
    'salary_currency': s?.salaryCurrency ?? 'USD',
    'phone': s?.phone,
    'commission_type': s?.commissionType ?? 'percent',
    percent: s == null || s.commissionPercent == 0 ? null : _plain(s.commissionPercent),
    fixedUsd: s == null || s.commissionFixedUsd == 0 ? null : _plain(s.commissionFixedUsd),
    'status': s?.status ?? 'active',
    'notes': s?.notes,
  };

  /// الجسم نفسه للإضافة والتعديل؛ العمولة تُرسل صفراً لغير المدرب، والفارغ يُرسل null.
  static Json body(AppFormCubit f) {
    final trainer = f.value('type') == 'trainer';
    final fixed = f.value('commission_type') == 'fixed';
    final value = trainer ? (_num(f.value(commissionField(fixed: fixed))) ?? 0) : 0;
    final hired = f.value('hired_on');
    return {
      'type': f.value('type'),
      'name': _text(f.value('name')),
      'job_title': _text(f.value('job_title')),
      'branch_id': f.value('branch_id'),
      'hired_on': hired is DateTime ? _ymd(hired) : null,
      'salary_amount': _num(f.value('salary_amount')) ?? 0,
      'salary_currency': f.value('salary_currency'),
      'phone': _text(f.value('phone')),
      'commission_type': trainer ? f.value('commission_type') : 'percent',
      'commission_percent': fixed ? 0 : value,
      'commission_fixed_usd': fixed ? value : 0,
      'status': f.value('status'),
      'notes': _text(f.value('notes')),
    };
  }

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _plain(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  static num? _num(Object? v) => num.tryParse('${v ?? ''}'.replaceAll(',', '').trim());

  static String? _text(Object? v) {
    final s = '${v ?? ''}'.trim();
    return s.isEmpty ? null : s;
  }

  static String? Function(String?) _range(num max, String what, {bool optional = true}) => (v) {
    final s = (v ?? '').replaceAll(',', '').trim();
    if (s.isEmpty) return optional ? null : 'اكتب $what.';
    final n = num.tryParse(s);
    if (n == null) return 'اكتب رقماً.';
    return n < 0 || n > max ? 'بين 0 و ${Formatters.number(max)}.' : null;
  };

  @override
  Widget build(BuildContext context) {
    const number = TextInputType.numberWithOptions(decimal: true);
    final today = DateTime.now();
    return FormColumn(
      children: [
        const FormChoice<String>('type', label: 'النوع', options: StaffTexts.types),
        FormText('name', label: 'الاسم', required: true, validator: Validators.required('اكتب الاسم.')),
        const FormText('job_title', label: 'المسمى الوظيفي', hint: 'مدرب حديد، عامل نظافة...'),
        _Pair(
          first: FormDropdown<int>('branch_id', label: 'الفرع', options: branches, hint: 'بلا فرع محدد'),
          second: FormDate('hired_on', label: 'تاريخ التعيين', firstDate: DateTime(today.year - 40), lastDate: today),
        ),
        _Pair(
          first: FormText(
            'salary_amount',
            label: 'الراتب الأساسي الشهري',
            ltr: true,
            hint: '0',
            keyboardType: number,
            validator: _range(100000000, 'الراتب'),
          ),
          second: const FormChoice<String>(
            'salary_currency',
            label: 'العملة',
            options: [(value: 'USD', label: 'دولار'), (value: 'SYP', label: 'ليرة')],
          ),
        ),
        FormText(
          'phone',
          label: 'رقم الموبايل (اختياري)',
          ltr: true,
          keyboardType: TextInputType.phone,
          validator: Validators.phone(optional: true),
        ),
        const _Commission(),
        if (editing) const FormChoice<String>('status', label: 'الحالة', options: StaffTexts.staffStatuses),
        const FormText('notes', label: 'ملاحظات', maxLines: 3),
      ],
    );
  }
}

/// العمولة للمدرب فقط؛ غيره يزيل تحققها.
class _Commission extends StatelessWidget {
  const _Commission();

  @override
  Widget build(BuildContext context) {
    final form = context.read<AppFormCubit>();
    final (trainer, fixed) = context.select<AppFormCubit, (bool, bool)>(
      (f) => (f.value('type') == 'trainer', f.value('commission_type') == 'fixed'),
    );
    // الحقل المخفي (أو كلاهما لغير المدرب) بلا تحقق.
    form.validator(StaffMemberFields.commissionField(fixed: !fixed), null);
    if (!trainer) {
      form.validator(StaffMemberFields.commissionField(fixed: fixed), null);
      return const SizedBox.shrink();
    }
    return _Pair(
      first: const FormChoice<String>(
        'commission_type',
        label: 'العمولة على العملاء',
        options: [(value: 'percent', label: 'نسبة %'), (value: 'fixed', label: r'مبلغ ثابت $')],
      ),
      second: FormText(
        StaffMemberFields.commissionField(fixed: fixed),
        key: ValueKey(fixed),
        label: fixed ? 'بالدولار لكل عميل' : 'النسبة من اشتراك العميل',
        ltr: true,
        hint: fixed ? '5' : '20',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: StaffMemberFields._range(fixed ? 100000 : 100, 'العمولة'),
      ),
    );
  }
}

/// حقلان بصف واحد، ويلتفّان تحت بعض إن ضاق العرض.
class _Pair extends StatelessWidget {
  const _Pair({required this.first, required this.second});

  final Widget first, second;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => box.maxWidth < AppSize.formFieldMin * 2
        ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: AppSpace.s4, children: [first, second])
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpace.s3,
            children: [Expanded(child: first), Expanded(child: second)],
          ),
  );
}
