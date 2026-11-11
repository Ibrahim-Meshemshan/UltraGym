import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../domain/models/staff_models.dart';
import '../bloc/staff_cubits.dart';

/// "حد الموظفين بالخطة N / L" (`usage.staff`): حسابات المالك والاستقبال فقط. فشلها أو غيابها يخفي البطاقة.
class StaffLimitCard extends StatelessWidget {
  const StaffLimitCard({super.key});

  @override
  Widget build(BuildContext context) {
    final usage = context.select<StaffUsageCubit, StaffUsage?>((c) => c.state.data);
    if (usage == null) return const SizedBox.shrink();
    final c = context.colors;
    final limit = usage.limit;
    return CutCard(
      child: Wrap(
        spacing: AppSpace.s4,
        runSpacing: AppSpace.s3,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpace.s1,
            children: [
              Text('حد الموظفين بالخطة', style: UType.label(color: c.inkMuted)),
              Text(
                'يشمل حسابات المالك والاستقبال؛ المدربون والعمال لا يُحسبون.',
                style: UType.caption(color: c.inkFaint),
              ),
            ],
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: AppSpace.s2,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: AppSpace.s2,
                children: [
                  if (usage.reached) const StatusBadge('وصلت للحد', tone: UTone.warning),
                  LtrText(
                    limit == null ? '${usage.used} / ∞' : '${usage.used} / $limit',
                    style: UType.h2(color: usage.reached ? c.warningInk : c.ink),
                  ),
                ],
              ),
              if (limit != null && limit > 0)
                SizedBox(
                  width: AppSize.staffLimitBar,
                  child: ClipRRect(
                    borderRadius: AppRadius.fullAll,
                    child: LinearProgressIndicator(
                      value: (usage.used / limit).clamp(0, 1).toDouble(),
                      minHeight: AppSpace.s1,
                      color: usage.reached ? c.warning : c.primary,
                      backgroundColor: c.surfaceAlt,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
