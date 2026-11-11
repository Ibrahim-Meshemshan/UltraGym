import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../domain/models/support_models.dart';
import '../bloc/billing_cubits.dart';
import 'reply_box.dart';

/// محادثة التذكرة (`ClubBilling.html`): العنوان والشارة والرقم والنوع، الرسائل (النادي بجهة البداية، فريق الدعم
/// بجهة النهاية) بمرفقاتها، ثم الرد. المغلقة بلا رد: "افتح تذكرة جديدة".
class TicketThreadCard extends StatelessWidget {
  const TicketThreadCard({super.key, required this.onReplied});

  /// بعد إرسال رد: تحديث القائمة (الحالة وآخر نشاط).
  final VoidCallback onReplied;

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<TicketThreadCubit>();
    return CutCard(
      child: SliceView<TicketThread>(
        slice: cubit.state,
        loading: const DetailsShimmer(),
        onRetry: cubit.load,
        builder: (context, t) => _Thread(
          t,
          onReplied: () {
            cubit.refresh();
            onReplied();
          },
        ),
      ),
    );
  }
}

class _Thread extends StatelessWidget {
  const _Thread(this.thread, {required this.onReplied});

  final TicketThread thread;
  final VoidCallback onReplied;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = thread.ticket;
    final badge = SupportTexts.status(t);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.s4,
      children: [
        Wrap(
          spacing: AppSpace.s3,
          runSpacing: AppSpace.s2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(t.subject, style: UType.h3(color: c.ink)),
            StatusBadge(badge.label, tone: badge.tone),
            LtrText(t.number, style: UType.caption(color: c.inkMuted)),
            Text(
              '${SupportTexts.category(t.category)} · أولوية ${SupportTexts.priority(t.priority)}',
              style: UType.caption(color: c.inkMuted),
            ),
          ],
        ),
        if (thread.truncated) Text('تظهر آخر 200 رسالة.', style: UType.caption(color: c.inkFaint)),
        for (final r in thread.replies) _Message(r),
        if (t.isClosed)
          Text('التذكرة مغلقة. افتح تذكرة جديدة لأي طلب آخر.', style: UType.label(color: c.inkMuted))
        else ...[
          if (t.status == 'resolved')
            Text('التذكرة محلولة؛ ردّك يعيد فتحها.', style: UType.caption(color: c.inkMuted)),
          ReplyBox(key: ValueKey(t.id), ticketId: t.id, onSent: onReplied),
        ],
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.reply);

  final TicketReply reply;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final r = reply;
    final when = r.createdAt == null ? '' : ' · ${Formatters.ltr(Formatters.dateTime(r.createdAt))}';
    return Align(
      alignment: r.fromSupport ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSize.messageMax),
        child: Container(
          padding: const EdgeInsets.all(AppSpace.s3),
          decoration: BoxDecoration(
            color: r.fromSupport ? c.surfaceAlt : c.primarySoft,
            borderRadius: AppRadius.fieldAll,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpace.s1,
            children: [
              Text('${r.fromSupport ? 'فريق UltraGym' : r.author}$when', style: UType.caption(color: c.inkMuted)),
              SelectableText(r.message, style: UType.body(color: c.ink)),
              if (r.attachments.isNotEmpty)
                Wrap(
                  spacing: AppSpace.s2,
                  runSpacing: AppSpace.s1,
                  children: [
                    for (final a in r.attachments)
                      ActionChip(
                        avatar: Icon(Icons.attach_file_rounded, size: AppSize.iconSm, color: c.inkMuted),
                        label: Text('${a.name} · ${SupportTexts.size(a.sizeKb)}', style: UType.caption(color: c.ink)),
                        tooltip: 'فتح المرفق',
                        onPressed: a.url == null ? null : () => Launcher.url(a.url!),
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
