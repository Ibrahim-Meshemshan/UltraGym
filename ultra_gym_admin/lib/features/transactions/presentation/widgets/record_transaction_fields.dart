import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../memberships/presentation/widgets/cash_fields.dart';
import '../../domain/models/transaction_models.dart';

/// حقول "تسجيل حركة" (`Transactions.html`): الاتجاه (مصروف / إيراد)، المبلغ والعملة، التصنيف من نفس الاتجاه،
/// الوصف، وصندوق الفرع حين يلزم. تغيير الاتجاه يمسح التصنيف لأن الخادم يرفض تصنيفاً من النوع الآخر.
class RecordTransactionFields extends StatelessWidget {
  const RecordTransactionFields({super.key, required this.categories, required this.branch, required this.owner});

  final List<FinanceCategory> categories;

  /// null = فرع ثابت (من بطاقة وردية) بلا حقل.
  final CashBranch? branch;
  final bool owner;

  static const type = 'type', currency = 'currency', amount = 'amount', category = 'category_id';
  static const description = 'description';

  @override
  Widget build(BuildContext context) {
    final form = context.read<AppFormCubit>();
    return FormColumn(
      children: [
        FormChoice<String>(
          type,
          label: 'الاتجاه',
          options: const [
            (value: TransactionTypes.expense, label: 'مصروف'),
            (value: TransactionTypes.income, label: 'إيراد آخر'),
          ],
          onChanged: (_) => form.set(category, null),
        ),
        ResponsiveGrid(
          maxColumns: 2,
          children: [
            FormText(
              amount,
              label: 'المبلغ',
              required: true,
              ltr: true,
              hint: '0.00',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: Validators.all([Validators.amount(), _positive]),
            ),
            const FormChoice<String>(currency, label: 'العملة', options: TransactionFilters.currencies),
          ],
        ),
        BlocSelector<AppFormCubit, AppFormState, Object?>(
          selector: (s) => s.values[type],
          builder: (context, kind) {
            final options = [
              for (final c in categories)
                if (c.kind == kind) (value: c.id, label: c.name),
            ];
            if (options.isEmpty) {
              form.validator(category, null);
              return _NoCategories(income: kind == TransactionTypes.income, owner: owner);
            }
            return FormDropdown<int>(
              category,
              key: ValueKey(kind),
              label: 'التصنيف',
              options: options,
              required: true,
              hint: 'اختر التصنيف',
            );
          },
        ),
        const FormText(
          description,
          label: 'الوصف',
          required: true,
          hint: 'مثلاً: تبديل حزام جهاز المشي رقم 3',
          validator: _describe,
        ),
        if (branch case final b? when b.needsField) b.field(),
      ],
    );
  }

  static String? _positive(String? v) =>
      num.tryParse((v ?? '').replaceAll(',', '').trim()) == 0 ? 'اكتب مبلغاً أكبر من صفر.' : null;

  static String? _describe(String? v) => (v ?? '').trim().isEmpty ? 'اكتب وصفاً قصيراً للحركة.' : null;
}

/// لا تصنيف فعّال لهذا الاتجاه: التسجيل يحتاجه، والتصنيفات من تبويب "التصنيفات" (للمالك).
class _NoCategories extends StatelessWidget {
  const _NoCategories({required this.income, required this.owner});

  final bool income, owner;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final what = income ? 'إيراد' : 'مصروف';
    return Container(
      padding: const EdgeInsets.all(AppSpace.s3),
      decoration: BoxDecoration(color: c.warningSoft, borderRadius: AppRadius.fieldAll),
      child: Text(
        owner
            ? 'لا تصنيفات $what بعد. أضف تصنيفاً من تبويب "التصنيفات" ثم سجّل الحركة.'
            : 'لا تصنيفات $what بعد. اطلب من مالك النادي إضافة تصنيف.',
        style: UType.label(color: c.warningInk),
      ),
    );
  }
}
