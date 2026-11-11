import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../domain/models/plans_models.dart';

/// بطاقة خطة (`Plans.html`): الاسم والنوع والحالة، السعر (+ عدد الحصص)، المدة والفروع والتجميد والمباع، ثم شارة
/// التدريب الشخصي وأفعال المالك (تعديل وأرشفة، أو استرجاع بالأرشيف).
class PlanCard extends StatelessWidget {
  const PlanCard(this.plan, {super.key, required this.archived, this.onEdit, this.onArchive, this.onRestore});

  final Plan plan;
  final bool archived;

  /// null = بلا أفعال (الاستقبال).
  final VoidCallback? onEdit, onArchive, onRestore;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final p = plan;
    final (status, tone) = archived
        ? ('مؤرشفة', UTone.neutral)
        : p.active
        ? ('فعّالة', UTone.success)
        : ('متوقفة', UTone.neutral);
    return CutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.s3,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpace.s2,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: UType.h3(color: p.active && !archived ? c.ink : c.inkMuted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(PlanTexts.kind(p), style: UType.caption(color: c.inkMuted)),
                  ],
                ),
              ),
              StatusBadge(status, tone: tone),
            ],
          ),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: AppSpace.s2,
            children: [
              LtrText(Formatters.usd(p.priceUsd), style: UType.h2(color: c.ink)),
              if (p.isSessions && p.sessionsCount != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.s1),
                  child: Text(PlanTexts.sessions(p.sessionsCount!), style: UType.label(color: c.inkMuted)),
                ),
            ],
          ),
          if (p.description != null) Text(p.description!, style: UType.label(color: c.inkMuted)),
          Column(
            spacing: AppSpace.s1,
            children: [
              _Line('المدة', PlanTexts.duration(p.durationDays)),
              _Line('الفروع', PlanTexts.branches(p)),
              _Line('التجميد', PlanTexts.freeze(p)),
              if (p.sold != null) _Line('اشتراكات مباعة', Formatters.number(p.sold!), ltr: true),
            ],
          ),
          if (p.isPersonal)
            const Align(
              alignment: AlignmentDirectional.centerStart,
              child: StatusBadge('تدريب شخصي · يحتاج مدرباً', tone: UTone.info),
            ),
          if (onEdit != null || onRestore != null) ...[
            Divider(height: 1, color: c.line),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              spacing: AppSpace.s1,
              children: [
                if (onRestore != null) TextButton(onPressed: onRestore, child: const Text('استرجاع')),
                if (onEdit != null) TextButton(onPressed: onEdit, child: const Text('تعديل')),
                if (onArchive != null)
                  IconButton(
                    tooltip: 'أرشفة ${p.name}',
                    onPressed: onArchive,
                    icon: const Icon(Icons.archive_outlined),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value, {this.ltr = false});

  final String label, value;
  final bool ltr;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = UType.label(color: c.ink);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpace.s3,
      children: [
        Text(label, style: UType.label(color: c.inkMuted)),
        Expanded(
          child: ltr
              ? Align(alignment: AlignmentDirectional.centerEnd, child: LtrText(value, style: style))
              : Text(value, style: style, textAlign: TextAlign.end),
        ),
      ],
    );
  }
}
