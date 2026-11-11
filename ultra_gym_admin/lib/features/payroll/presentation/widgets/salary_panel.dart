import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../../members/presentation/widgets/member_cells.dart';
import '../../../memberships/presentation/widgets/membership_actions.dart' show openReceipt;
import '../../domain/models/payroll_models.dart';
import '../bloc/payroll_cubits.dart';
import 'salary_breakdown.dart';
import 'salary_form.dart';

/// لوحة راتب موظف لشهر: الرأس، ثم الراتب المصروف كما ثبّته الخادم (مع الإيصال)، أو المعاينة ونموذج الصرف.
class SalaryPanel extends StatelessWidget {
  const SalaryPanel({super.key, required this.staff, required this.period, required this.paid, required this.onPaid});

  final PayrollStaff staff;
  final String period;
  final SalaryPayment? paid;
  final Future<void> Function() onPaid;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final paid = this.paid;
    return CutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.s4,
        children: [
          Row(
            spacing: AppSpace.s3,
            children: [
              MemberAvatar(staff.name),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(staff.name, style: UType.h3(color: c.ink), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(
                      '${PayrollTexts.role(staff)} · راتب ${PayrollTexts.month(period)}',
                      style: UType.label(color: c.inkMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (paid != null)
            _PaidView(paid)
          else
            BlocProvider(
              create: (_) => sl<SalaryPreviewCubit>(param1: (staffId: staff.id, period: period))..load(),
              child: Builder(
                builder: (context) => SliceView<SalaryPreview>(
                  slice: context.watch<SalaryPreviewCubit>().state,
                  onRetry: context.read<SalaryPreviewCubit>().load,
                  loading: const _Shimmer(),
                  builder: (context, p) => p.alreadyPaid
                      ? _PaidElsewhere(onRefresh: onPaid)
                      : SalaryForm(preview: p, onPaid: onPaid),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// الراتب المصروف: التنبيه بتاريخه، الإيصال، والأسطر كما حُفظت.
class _PaidView extends StatelessWidget {
  const _PaidView(this.s);

  final SalaryPayment s;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tx = s.transactionId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.s4,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: StatusBadge('مصروف ${Formatters.date(s.createdAt, fromUtc: true)}', tone: UTone.success),
        ),
        DecoratedBox(
          decoration: BoxDecoration(color: c.successSoft, borderRadius: AppRadius.fieldAll),
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.s3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpace.s2,
              children: [
                Text(
                  'صُرف راتب ${PayrollTexts.month(s.period)}. لا يمكن صرفه مرة ثانية؛ للتصحيح اعكس الحركة من دفتر الحركات.',
                  style: UType.label(color: c.successInk),
                ),
                Wrap(
                  spacing: AppSpace.s2,
                  children: [
                    if (tx != null) TextButton(onPressed: () => openReceipt(tx), child: const Text('طباعة الإيصال')),
                    TextButton(onPressed: () => context.go(Routes.transactions), child: const Text('دفتر الحركات')),
                  ],
                ),
              ],
            ),
          ),
        ),
        SalaryBreakdown(
          lines: [
            (label: 'الراتب الأساسي', usd: s.baseUsd, sign: ''),
            (label: 'العمولة', usd: s.commissionUsd, sign: '+'),
            (label: 'المكافأة', usd: s.bonusUsd, sign: '+'),
            (label: 'الخصومات', usd: s.deductionsUsd, sign: '−'),
            (label: 'خصم السلف', usd: s.advanceDeductionUsd, sign: '−'),
          ],
          netLabel: 'الصافي المصروف',
          net: s.netUsd,
        ),
        if (s.note != null) Text(s.note!, style: UType.label(color: c.inkMuted)),
      ],
    );
  }
}

/// المعاينة تقول إن الراتب صُرف (من جهاز آخر مثلاً) والقائمة لم تتحدث بعد.
class _PaidElsewhere extends StatelessWidget {
  const _PaidElsewhere({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: AppSpace.s2,
    children: [
      Text('صُرف راتب هذا الشهر مسبقاً.', style: UType.body(color: context.colors.ink)),
      TextButton(onPressed: onRefresh, child: const Text('تحديث القائمة')),
    ],
  );
}

class _Shimmer extends StatelessWidget {
  const _Shimmer();

  @override
  Widget build(BuildContext context) => const AppShimmer(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.s3,
      children: [
        Row(
          spacing: AppSpace.s3,
          children: [
            Expanded(child: ShimmerBox(height: AppSpace.s16)),
            Expanded(child: ShimmerBox(height: AppSpace.s16)),
            Expanded(child: ShimmerBox(height: AppSpace.s16)),
          ],
        ),
        ShimmerBox(height: AppSpace.s12),
        ShimmerBox(height: AppSpace.s16),
      ],
    ),
  );
}
