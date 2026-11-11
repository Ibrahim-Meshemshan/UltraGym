import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../transactions/domain/models/transaction_models.dart';
import '../../data/repo/finance_settings_repository.dart';
import '../bloc/finance_settings_cubit.dart';

/// أفعال المالك على التصنيفات: إضافة، تعديل الاسم والحالة، حذف غير المستعمل. بعد كل منها تحديث صامت.
abstract final class CategoryActions {
  static const _name = 'name', _status = 'status';

  static String _kindLabel(String kind) => kind == 'income' ? 'إيراد' : 'مصروف';

  static String? _nameValidator(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'اكتب اسم التصنيف.';
    return s.length > 100 ? 'الاسم أطول من 100 حرف.' : null;
  }

  /// `POST finance/categories {kind, name}`.
  static Future<void> add(BuildContext context, String kind) async {
    final cubit = context.read<FinanceCategoriesCubit>();
    final keeper = IdempotencyKeeper();
    final done = await FormDialog.show<FinanceCategory>(
      context,
      title: 'تصنيف ${_kindLabel(kind)} جديد',
      icon: Icons.sell_rounded,
      submitLabel: 'إضافة',
      fields: (_) => const FormColumn(
        children: [
          FormText(_name, label: 'اسم التصنيف', required: true, validator: _nameValidator),
        ],
      ),
      onSubmit: (form) {
        final body = {'kind': kind, _name: '${form.value(_name) ?? ''}'.trim()};
        return sl<FinanceSettingsRepository>().addCategory(body, idempotencyKey: keeper.keyFor(body));
      },
    );
    if (done != null) await cubit.refresh();
  }

  /// `PATCH finance/categories/{id}`: الاسم والحالة بجسم واحد (المتغيّر فقط).
  static Future<void> edit(BuildContext context, FinanceCategory cat) async {
    final cubit = context.read<FinanceCategoriesCubit>();
    final done = await FormDialog.show<FinanceCategory>(
      context,
      title: 'تعديل التصنيف',
      icon: Icons.edit_rounded,
      submitLabel: 'حفظ',
      initial: {_name: cat.name, _status: cat.active ? 'active' : 'inactive'},
      fields: (_) => FormColumn(
        children: [
          const FormText(_name, label: 'اسم التصنيف', required: true, validator: _nameValidator),
          const FormChoice<String>(
            _status,
            label: 'الحالة',
            options: [(value: 'active', label: 'فعّال'), (value: 'inactive', label: 'متوقف')],
          ),
          Text(
            'التصنيف المتوقف يختفي من نموذج تسجيل الحركة ويبقى ظاهراً بالحركات والتقارير السابقة.',
            style: UType.caption(color: context.colors.inkMuted),
          ),
        ],
      ),
      onSubmit: (form) {
        final name = '${form.value(_name) ?? ''}'.trim();
        final status = '${form.value(_status)}';
        final body = {
          if (name != cat.name) _name: name,
          if (status != (cat.active ? 'active' : 'inactive')) _status: status,
        };
        if (body.isEmpty) return Future.value(ApiSuccess(cat, message: 'لا تغييرات.'));
        return sl<FinanceSettingsRepository>().updateCategory(cat.id, body);
      },
    );
    if (done != null) await cubit.refresh();
  }

  /// `DELETE finance/categories/{id}`: للتصنيف غير المستعمل فقط (المستعمل يرفضه الخادم بـ `CONFLICT`).
  static Future<void> delete(BuildContext context, FinanceCategory cat) async {
    final cubit = context.read<FinanceCategoriesCubit>();
    final done = await FormDialog.confirm<void>(
      context,
      title: 'حذف التصنيف',
      message: 'سيُحذف تصنيف "${cat.name}" نهائياً. لا حركات عليه.',
      confirmLabel: 'حذف',
      icon: Icons.delete_outline_rounded,
      onConfirm: () => sl<FinanceSettingsRepository>().deleteCategory(cat.id),
    );
    if (done != null) await cubit.refresh();
  }
}
