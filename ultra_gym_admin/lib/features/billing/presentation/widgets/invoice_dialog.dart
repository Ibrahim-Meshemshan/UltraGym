import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../data/repo/billing_repository.dart';
import '../../domain/models/billing_models.dart';
import '../../domain/models/billing_texts.dart';
import '../bloc/billing_cubits.dart';
import 'subscription_card.dart';

/// تفاصيل فاتورة المنصة (من الجدول أو إشعار `billing_invoice`): المبالغ والاستحقاق والدفعات المسجّلة و PDF.
abstract final class InvoiceDialog {
  static Future<void> show(BuildContext context, int id) => showDialog<void>(
    context: context,
    builder: (_) => BlocProvider(create: (_) => InvoiceDetailCubit(sl(), id)..load(), child: const _Body()),
  );

  /// `GET billing/invoices/{id}/pdf` ← `BlobOpener` (أو HTML للطباعة حين لا محرك PDF بالخادم).
  static Future<void> pdf(BuildContext context, int id) async {
    switch (await sl<BillingRepository>().invoicePdf(id)) {
      case ApiSuccess(:final data):
        await BlobOpener.open(data);
      case ApiFailure(:final failure):
        AppSnackbar.show(failure.message);
    }
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final cubit = context.watch<InvoiceDetailCubit>();
    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpace.s4),
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(AppRadius.hero))),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSize.dialog),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpace.s6),
          child: SliceView<PlatformInvoice>(
            slice: cubit.state,
            loading: const DetailsShimmer(),
            onRetry: cubit.load,
            builder: (context, i) => _Content(i),
          ),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content(this.invoice);

  final PlatformInvoice invoice;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final i = invoice;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpace.s4,
      children: [
        Wrap(
          spacing: AppSpace.s3,
          runSpacing: AppSpace.s2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('فاتورة', style: UType.h2(color: c.ink)),
            LtrText(i.number, style: UType.h2(color: c.ink)),
            StatusBadge(i.label.text, tone: i.label.tone),
          ],
        ),
        if (i.cancellationReason case final r?) Text('سبب الإلغاء: $r', style: UType.label(color: c.inkMuted)),
        Column(
          children: [
            BillingRow('الباقة', [?i.planName, BillingTexts.cycle(i.cycle)].join(' · ')),
            BillingRow('الفترة', BillingTexts.period(i.periodStart, i.periodEnd)),
            BillingRow('الإصدار', Formatters.date(i.issuedOn), ltr: true),
            BillingRow('الاستحقاق', Formatters.date(i.dueOn), ltr: true),
            BillingRow('المجموع', Formatters.usd(i.subtotal), ltr: true),
            if (i.discount > 0) BillingRow('الخصم', Formatters.usd(-i.discount), ltr: true),
            BillingRow('الإجمالي', Formatters.usd(i.total), ltr: true),
            BillingRow('المدفوع', Formatters.usd(i.paid), ltr: true),
            if (i.remaining > 0) BillingRow('المتبقي', Formatters.usd(i.remaining), ltr: true),
          ],
        ),
        Text('الدفعات', style: UType.label(color: c.inkMuted).weight(600)),
        if (i.payments.isEmpty)
          Text('لا دفعات مسجّلة على هذه الفاتورة بعد.', style: UType.label(color: c.inkMuted))
        else
          for (final p in i.payments)
            BillingRow(
              Formatters.ltr(Formatters.date(p.paidOn)),
              '${Formatters.ltr(Formatters.usd(p.amount))} · ${BillingTexts.method(p.method)}'
              '${p.reference == null ? '' : ' · ${Formatters.ltr(p.reference!)}'}',
            ),
        Text(
          'الفواتير والدفعات يسجّلها فريق UltraGym. الدفع يدوي بتحويل أو نقداً.',
          style: UType.caption(color: c.inkMuted),
        ),
        Wrap(
          spacing: AppSpace.s2,
          children: [
            UGButton(
              label: 'تنزيل PDF',
              icon: Icons.picture_as_pdf_rounded,
              onPressed: () => InvoiceDialog.pdf(context, i.id),
            ),
            UGButton(label: 'إغلاق', kind: UButtonKind.secondary, onPressed: () => Navigator.of(context).pop()),
          ],
        ),
      ],
    );
  }
}
