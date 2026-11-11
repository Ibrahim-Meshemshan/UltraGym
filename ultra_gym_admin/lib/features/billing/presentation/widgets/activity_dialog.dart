import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../domain/models/activity_models.dart';
import '../bloc/billing_cubits.dart';
import 'subscription_card.dart';

/// تفاصيل عملية بالسجل (`GET activity-log/{id}`): من ومتى وعلى ماذا، ثم الحقول التي تغيّرت (قبل ← بعد)
/// بمفاتيح الخادم كما هي، وعنوان IP.
abstract final class ActivityDialog {
  static Future<void> show(BuildContext context, int id) => showDialog<void>(
    context: context,
    builder: (_) => BlocProvider(create: (_) => ActivityEntryCubit(sl(), id)..load(), child: const _Body()),
  );
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final cubit = context.watch<ActivityEntryCubit>();
    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpace.s4),
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(AppRadius.hero))),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSize.dialog),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpace.s6),
          child: SliceView<ActivityEntry>(
            slice: cubit.state,
            loading: const DetailsShimmer(),
            onRetry: cubit.load,
            builder: (context, e) => _Content(e),
          ),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content(this.entry);

  final ActivityEntry entry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final e = entry;
    final changes = e.changes;
    final created = e.oldValues == null;
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
            Text(e.description, style: UType.h3(color: c.ink)),
            StatusBadge(e.moduleLabel, tone: UTone.neutral, dot: false),
            if (e.byPlatformSupport) const StatusBadge('دعم UltraGym', tone: UTone.accent, dot: false),
          ],
        ),
        Column(
          children: [
            BillingRow('المستخدم', e.actor),
            BillingRow('الوقت', Formatters.dateTime(e.createdAt), ltr: true),
            if (e.subject case final s?) BillingRow('على', s),
            BillingRow('العملية', e.action, ltr: true),
            if (e.ip case final ip?) BillingRow('عنوان IP', ip, ltr: true),
          ],
        ),
        if (changes.isNotEmpty) ...[
          Text(created ? 'القيم المسجّلة' : 'ما تغيّر', style: UType.label(color: c.inkMuted).weight(600)),
          for (final ch in changes)
            BillingRow(
              ch.key,
              created
                  ? ActivityEntry.show(ch.after)
                  : '${ActivityEntry.show(ch.before)} ← ${ActivityEntry.show(ch.after)}',
            ),
        ] else if (e.newValues != null || e.oldValues != null)
          Text('لم تتغيّر أي قيمة.', style: UType.label(color: c.inkMuted)),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: UGButton(label: 'إغلاق', kind: UButtonKind.secondary, onPressed: () => Navigator.of(context).pop()),
        ),
      ],
    );
  }
}
