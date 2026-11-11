import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../domain/models/sale_models.dart';
import '../bloc/sell_membership_cubit.dart';
import 'membership_actions.dart';

/// بعد البيع: رسالة الخادم، إيصال لكل دفعة للطباعة، وفتح الاشتراك أو بيع آخر.
class SaleDone extends StatelessWidget {
  const SaleDone(this.result, {super.key});

  final SaleResult result;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Align(
      alignment: AlignmentDirectional.topStart,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSize.dialog),
        child: CutCard(
          padding: const EdgeInsets.all(AppSpace.s6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpace.s4,
            children: [
              Row(
                spacing: AppSpace.s3,
                children: [
                  const IconSlab(Icons.check_rounded, tone: UTone.success),
                  Expanded(
                    child: Semantics(
                      header: true,
                      liveRegion: true,
                      child: Text('تم البيع', style: UType.displayMd(color: c.ink)),
                    ),
                  ),
                ],
              ),
              Text(result.message ?? 'تم تسجيل الاشتراك بنجاح', style: UType.bodyLg(color: c.ink)),
              if (result.dueUsd > 0)
                Text(
                  'الباقي ${Formatters.ltr(Formatters.usd(result.dueUsd))} دين على العضو ويظهر بقائمة الديون.',
                  style: UType.body(color: c.warningInk),
                ),
              if (result.receipts.isNotEmpty) ...[
                Text('الإيصالات', style: UType.label(color: c.inkMuted)),
                for (final r in result.receipts) _ReceiptRow(r),
              ],
              Wrap(
                spacing: AppSpace.s2,
                runSpacing: AppSpace.s2,
                children: [
                  UGButton(
                    label: 'فتح الاشتراك',
                    icon: Icons.open_in_new_rounded,
                    onPressed: () => context.go(Routes.child(Routes.memberships, result.membershipId)),
                  ),
                  UGButton(
                    label: 'بيع اشتراك آخر',
                    icon: Icons.add_rounded,
                    kind: UButtonKind.secondary,
                    onPressed: context.read<SellMembershipCubit>().startOver,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow(this.r);

  final SaleReceipt r;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsetsDirectional.only(start: AppSpace.s3),
      decoration: BoxDecoration(color: c.surfaceAlt, borderRadius: AppRadius.smAll),
      child: Row(
        spacing: AppSpace.s3,
        children: [
          Expanded(
            child: LtrText(r.number ?? '—', style: UType.body(color: c.ink).weight(600)),
          ),
          LtrText(Formatters.money(r.amount, r.currency), style: UType.body(color: c.successInk)),
          TextButton.icon(
            onPressed: () => openReceipt(r.id),
            icon: const Icon(Icons.print_rounded, size: AppSize.iconSm),
            label: const Text('طباعة الإيصال'),
          ),
        ],
      ),
    );
  }
}
