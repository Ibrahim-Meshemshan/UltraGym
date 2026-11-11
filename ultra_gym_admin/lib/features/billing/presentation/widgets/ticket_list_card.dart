import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../domain/models/support_models.dart';
import '../bloc/billing_cubits.dart';

/// "التذاكر" (`ClubBilling.html` · الدعم الفني): "+ تذكرة"، رقائق الحالة، وسطر لكل تذكرة (العنوان، الشارة،
/// الرقم وآخر نشاط). المحددة بخلفية `primarySoft`. "عرض المزيد" للصفحات التالية.
class TicketListCard extends StatelessWidget {
  const TicketListCard({super.key, required this.selected, required this.onSelect, required this.onNew});

  final int? selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final list = context.read<SupportTicketsCubit>();
    final state = context.watch<SupportTicketsCubit>().state;
    final now = sl<ServerClock>().now();
    return CutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.s3,
        children: [
          Row(
            children: [
              Expanded(child: Text('التذاكر', style: UType.h3(color: c.ink))),
              UGButton(label: 'تذكرة', icon: Icons.add_rounded, kind: UButtonKind.secondary, onPressed: onNew),
            ],
          ),
          FilterChoiceChips<String>(
            semanticsLabel: 'حالة التذكرة',
            options: SupportTexts.statuses,
            value: state.query.filter('status') as String?,
            onChanged: (v) => list.filter('status', v),
          ),
          SliceView<Paged<SupportTicket>>(
            slice: state.slice,
            loading: const ListShimmer(count: 3),
            onRetry: list.load,
            isEmpty: (p) => p.items.isEmpty,
            empty: state.query.hasFilters
                ? Text('لا تذاكر بهذه الحالة.', style: UType.label(color: c.inkMuted))
                : AppEmptyState(
                    icon: Icons.support_agent_rounded,
                    title: 'لا تذاكر بعد',
                    message: 'لأي مشكلة أو سؤال عن الاشتراك افتح تذكرة، ويرد فريق UltraGym هنا.',
                    actionLabel: 'فتح تذكرة',
                    onAction: onNew,
                  ),
            builder: (context, page) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpace.s2,
              children: [
                for (final t in page.items)
                  _TicketTile(t, selected: t.id == selected, now: now, onTap: () => onSelect(t.id)),
                if (state.canLoadMore)
                  TextButton(onPressed: state.loadingMore ? null : list.more, child: const Text('عرض المزيد')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketTile extends StatelessWidget {
  const _TicketTile(this.ticket, {required this.selected, required this.now, required this.onTap});

  final SupportTicket ticket;
  final bool selected;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = ticket;
    final badge = SupportTexts.status(t);
    return Material(
      color: selected ? c.primarySoft : c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.fieldAll,
        side: BorderSide(color: selected ? c.primary : c.line),
      ),
      child: InkWell(
        borderRadius: AppRadius.fieldAll,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.s3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpace.s1,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpace.s2,
                children: [
                  Expanded(
                    child: Text(
                      t.subject,
                      style: UType.body(color: c.ink).weight(600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  StatusBadge(badge.label, tone: badge.tone),
                ],
              ),
              Text(
                '${Formatters.ltr(t.number)} · ${Formatters.relative(t.lastReplyAt ?? t.createdAt, now: now)}',
                style: UType.caption(color: c.inkMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
