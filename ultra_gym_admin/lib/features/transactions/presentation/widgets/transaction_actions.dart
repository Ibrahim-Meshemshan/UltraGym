import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../memberships/presentation/widgets/cash_fields.dart';
import '../../data/repo/transactions_repository.dart';
import '../../domain/models/transaction_models.dart';
import 'ledger_cells.dart';
import 'record_transaction_fields.dart';

/// أفعال الدفتر: تسجيل إيراد أو مصروف (المالك والاستقبال)، العكس (للمالك)، والإيصال.
abstract final class TransactionActions {
  static TransactionsRepository get _repo => sl<TransactionsRepository>();

  /// نافذة "تسجيل حركة" بصندوق الفرع: `branchId` ثابت (من بطاقة وردية)، وإلا فرع الشريط العلوي أو حقل اختيار
  /// يبدأ بـ `fallbackBranch` حين يكون الشريط على "كل الفروع".
  /// ترجع الحركة المسجّلة (للتحديث)، و null عند الإلغاء.
  static Future<LedgerEntry?> record(BuildContext context, {int? branchId, int? fallbackBranch}) async {
    final owner = context.read<AuthBloc>().state.session?.isClubOwner ?? false;
    final branch = branchId == null ? CashBranch.of(context, fallback: fallbackBranch) : null;
    final categories = await _repo.categories();
    if (!context.mounted) return null;
    final list = switch (categories) {
      ApiSuccess(:final data) => data,
      ApiFailure(:final failure) => () {
        AppSnackbar.show(failure.message);
        return null;
      }(),
    };
    if (list == null) return null;
    final keeper = IdempotencyKeeper();
    final done = await FormDialog.show<LedgerEntry>(
      context,
      title: 'تسجيل حركة',
      icon: Icons.add_card_rounded,
      submitLabel: 'تسجيل',
      initial: {
        RecordTransactionFields.type: TransactionTypes.expense,
        RecordTransactionFields.currency: 'USD',
        ...?branch?.initial,
      },
      message: 'تُسجَّل على الوردية المفتوحة بصندوق الفرع، وبسعر صرف اليوم.',
      fields: (_) => RecordTransactionFields(categories: list, branch: branch, owner: owner),
      onSubmit: (form) async {
        final category = form.value(RecordTransactionFields.category);
        if (category == null) {
          return const ApiFailure(
            Failure(type: FailureType.validation, message: 'لا تصنيف لهذا النوع. أضف تصنيفاً ثم سجّل الحركة.'),
          );
        }
        final body = {
          RecordTransactionFields.type: form.value(RecordTransactionFields.type),
          RecordTransactionFields.currency: form.value(RecordTransactionFields.currency),
          RecordTransactionFields.amount: _num(form.value(RecordTransactionFields.amount)),
          RecordTransactionFields.category: category,
          RecordTransactionFields.description: '${form.value(RecordTransactionFields.description)}'.trim(),
          CashBranch.key: ?(branchId ?? branch?.idOf(form)),
        };
        return _repo.record(body, idempotencyKey: keeper.keyFor(body));
      },
    );
    return done?.data;
  }

  /// عكس حركة (للمالك) بسبب إلزامي. ترجع الأصلية والعكس، و null عند التراجع.
  static Future<LedgerReversal?> reverse(BuildContext context, LedgerEntry e) async {
    final keeper = IdempotencyKeeper();
    final done = await FormDialog.show<LedgerReversal>(
      context,
      title: 'عكس الحركة',
      icon: Icons.undo_rounded,
      danger: true,
      submitLabel: 'تأكيد العكس',
      fields: (_) => FormColumn(
        children: [
          ReverseSummary(e),
          const FormText(
            'reason',
            label: 'السبب',
            required: true,
            maxLines: 3,
            hint: 'مثلاً: سُجّلت الدفعة على العضو الخطأ',
            validator: _reason,
          ),
        ],
      ),
      onSubmit: (form) {
        final reason = '${form.value('reason')}'.trim();
        return _repo.reverse(e.id, reason, idempotencyKey: keeper.keyFor({'id': e.id, 'reason': reason}));
      },
    );
    return done?.data;
  }

  /// إيصال الحركة PDF (أو صفحة HTML للطباعة).
  static Future<void> receipt(int id) async {
    switch (await _repo.receipt(id)) {
      case ApiSuccess(:final data):
        await BlobOpener.open(data);
      case ApiFailure(:final failure):
        AppSnackbar.show(failure.message);
    }
  }

  static String? _reason(String? v) => (v ?? '').trim().isEmpty ? 'اكتب سبب العكس.' : null;

  static num? _num(Object? v) => num.tryParse('${v ?? ''}'.replaceAll(',', '').trim());
}
