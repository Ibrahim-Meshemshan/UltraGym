import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../staff/presentation/widgets/staff_cells.dart';
import '../../domain/models/billing_models.dart';
import '../../domain/models/billing_texts.dart';
import '../bloc/billing_cubits.dart';
import 'invoice_dialog.dart';

/// "فواتير المنصة" (`ClubBilling.html`): الرقم، الفترة، المبلغ (والمتبقي)، الاستحقاق، الحالة (المتأخرة من
/// `is_overdue`)، و PDF. الصف يفتح التفاصيل بالدفعات.
class InvoicesTable extends StatelessWidget {
  const InvoicesTable({super.key});

  static const _statuses = [
    (value: 'pending', label: 'بانتظار الدفع'),
    (value: 'partially_paid', label: 'مدفوعة جزئياً'),
    (value: 'paid', label: 'مدفوعة'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final list = context.read<InvoicesCubit>();
    final state = context.watch<InvoicesCubit>().state;
    final overdue = state.query.filter('overdue') == true;

    Widget pdf(PlatformInvoice i) => TextButton(onPressed: () => InvoiceDialog.pdf(context, i.id), child: const Text('PDF'));
    Widget amount(PlatformInvoice i) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        LtrText(Formatters.usd(i.total), style: UType.body(color: c.ink).weight(600)),
        if (i.remaining > 0 && i.remaining < i.total)
          Text('المتبقي ${Formatters.ltr(Formatters.usd(i.remaining))}', style: UType.caption(color: c.warningInk)),
      ],
    );

    return PagedTable<PlatformInvoice>(
      state: state,
      noun: 'فاتورة',
      minWidth: AppSize.invoicesTableMin,
      onPage: list.goTo,
      onRetry: list.load,
      onClearFilters: list.clearFilters,
      onRowTap: (i) => InvoiceDialog.show(context, i.id),
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.s3,
        children: [
          Text('فواتير المنصة', style: UType.h3(color: c.ink)),
          FilterBar(
            search: state.query.search,
            hint: 'رقم الفاتورة',
            onSearch: list.search,
            onClear: state.query.hasFilters ? list.clearFilters : null,
            filters: [FilterToggle(label: 'المتأخرة', value: overdue, onChanged: (v) => list.filter('overdue', v ? true : null))],
            chips: FilterChoiceChips<String>(
              semanticsLabel: 'حالة الفاتورة',
              options: _statuses,
              value: state.query.filter('status') as String?,
              onChanged: (v) => list.filter('status', v),
            ),
          ),
        ],
      ),
      empty: const EmptyState(
        icon: Icons.receipt_long_rounded,
        title: 'لا فواتير بعد',
        message: 'تظهر هنا فواتير اشتراك النادي حين يصدرها فريق UltraGym، ويصلك إشعار بكل فاتورة جديدة.',
      ),
      mobileItem: (context, i) => StaffMobileCard(
        person: LtrText(i.number, style: UType.body(color: c.ink).weight(600)),
        badge: (label: i.label.text, tone: i.label.tone),
        menu: pdf(i),
        lines: [
          (label: 'الفترة', value: BillingTexts.period(i.periodStart, i.periodEnd), ltr: false),
          (label: 'المبلغ', value: Formatters.usd(i.total), ltr: true),
          (label: 'الاستحقاق', value: Formatters.date(i.dueOn), ltr: true),
        ],
      ),
      columns: [
        TableCol('الرقم', flex: 2, cell: (context, i) => MutedCell(i.number, ltr: true)),
        TableCol(
          'الفترة',
          flex: 3,
          cell: (context, i) => MutedCell(
            '${BillingTexts.period(i.periodStart, i.periodEnd)}${i.planName == null ? '' : '\n${i.planName}'}',
          ),
        ),
        TableCol('المبلغ', flex: 2, cell: (context, i) => amount(i)),
        TableCol('الاستحقاق', flex: 2, cell: (context, i) => MutedCell(Formatters.date(i.dueOn), ltr: true)),
        TableCol('الحالة', flex: 2, cell: (context, i) => BadgeCell((label: i.label.text, tone: i.label.tone))),
        TableCol('PDF', width: AppSize.actionsCol, cell: (context, i) => pdf(i)),
      ],
    );
  }
}
