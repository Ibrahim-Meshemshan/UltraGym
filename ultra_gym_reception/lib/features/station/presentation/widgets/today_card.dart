import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../domain/models/station_models.dart';
import '../bloc/station_bloc.dart';

/// "دخول اليوم" بالعمود الجانبي: المقبول والمرفوض، وآخر الدخول بالفرع (من `attendance/today`) بوقته وطريقته.
class TodayCard extends StatelessWidget {
  const TodayCard({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final today = context.select<StationBloc, Slice<TodaySummary>>((b) => b.state.today);
    return CutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.s3,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('دخول اليوم', style: UType.h3(color: c.ink)),
              ),
              if (today.data case final t?)
                Text.rich(
                  TextSpan(
                    style: UType.label(color: c.inkMuted),
                    children: [
                      TextSpan(
                        text: '${t.accepted}',
                        style: UType.label(color: c.successInk).weight(700),
                      ),
                      const TextSpan(text: ' مقبول · '),
                      TextSpan(
                        text: '${t.rejected}',
                        style: UType.label(color: c.dangerInk).weight(700),
                      ),
                      const TextSpan(text: ' مرفوض'),
                    ],
                  ),
                ),
            ],
          ),
          SliceView<TodaySummary>(
            slice: today,
            loading: const ListShimmer(count: 5),
            onRetry: () => context.read<StationBloc>().add(const StationTodayRequested()),
            isEmpty: (t) => t.latest.isEmpty,
            empty: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.s4),
              child: Text('لا دخول بعد اليوم. أول عضو يمسح رمزه يظهر هنا.', style: UType.body(color: c.inkMuted)),
            ),
            builder: (context, t) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [for (final e in t.latest) _FeedRow(e)],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedRow extends StatelessWidget {
  const _FeedRow(this.entry);

  final AttendanceEntry entry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final status = Labels.attendance(entry.status, inGrace: entry.inGrace);
    final detail = [
      entry.methodLabel,
      if (entry.isRejected) ?entry.rejectionMessage,
      if (entry.isOffline) 'دون اتصال',
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.s2),
      child: Row(
        spacing: AppSpace.s3,
        children: [
          SizedBox(
            width: AppSpace.s10,
            child: LtrText(Formatters.time(entry.checkedInAt), style: UType.caption(color: c.inkMuted)),
          ),
          InitialsAvatar(entry.playerName, size: AppSize.feedAvatar, tone: UTone.neutral),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.playerName,
                  style: UType.label(color: c.ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  detail,
                  style: UType.caption(color: c.inkMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          StatusBadge(status.text, tone: status.tone),
        ],
      ),
    );
  }
}
