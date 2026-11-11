import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../domain/models/attendance_models.dart';
import '../bloc/attendance_cubit.dart';

/// أرقام اليوم (`.stat` بالنموذج) بجانب الدخول حسب الساعة. "مرفوض" يفلتر السجل على المرفوض.
/// الفشل يعرض خطأً مختصراً بإعادة محاولة ولا يوقف السجل.
class AttendanceTodaySection extends StatelessWidget {
  const AttendanceTodaySection({super.key, this.onRejected});

  final VoidCallback? onRejected;

  @override
  Widget build(BuildContext context) {
    final slice = context.watch<AttendanceTodayCubit>().state;
    if (slice.isFirstLoad) return const StatsShimmer();
    final t = slice.data;
    if (t == null) {
      final f = slice.failure;
      return f == null
          ? const SizedBox.shrink()
          : ErrorState(failure: f, onRetry: context.read<AttendanceTodayCubit>().load, compact: true);
    }
    final stats = ResponsiveGrid(
      children: [
        AppStatCard(icon: Icons.login_rounded, label: 'دخول مقبول اليوم', value: t.accepted.toDouble()),
        AppStatCard(
          icon: Icons.do_not_disturb_on_outlined,
          label: 'مرفوض اليوم',
          value: t.rejected.toDouble(),
          note: t.rejected > 0 ? 'اعرض الأسباب' : 'لا رفض اليوم',
          noteTone: t.rejected > 0 ? UTone.danger : UTone.success,
          onTap: t.rejected > 0 ? onRejected : null,
        ),
        AppStatCard(
          icon: Icons.hourglass_bottom_rounded,
          label: 'بفترة السماح',
          value: t.inGrace.toDouble(),
          note: t.inGrace > 0 ? 'اشتراكات منتهية: ذكّرهم بالتجديد' : null,
          noteTone: t.inGrace > 0 ? UTone.warning : null,
        ),
        AppStatCard(
          icon: Icons.confirmation_number_outlined,
          label: 'جلسات مستهلكة',
          value: t.sessionsConsumed.toDouble(),
        ),
      ],
    );
    return Semantics(
      container: true,
      label: 'حضور اليوم',
      child: LayoutBuilder(
        builder: (context, box) => box.maxWidth >= AppSize.splitMin
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: stats),
                  AppSpace.gap3,
                  Expanded(child: HoursCard(t)),
                ],
              )
            : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [stats, AppSpace.gap3, HoursCard(t)]),
      ),
    );
  }
}

/// الدخول المقبول حسب الساعة (`.hours`): عمود لكل ساعة من بداية يوم العمل، والضعيفة بلون الخط.
class HoursCard extends StatelessWidget {
  const HoursCard(this.today, {super.key});

  final AttendanceToday today;

  /// أقل من هذه النسبة من الذروة = عمود باهت (كما بالنموذج).
  static const _low = 0.3;

  static String _hour(int h) => '${h.toString().padLeft(2, '0')}:00';

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hours = today.hours;
    final peak = today.peakHour;
    final max = hours.fold(0, (m, h) => h.count > m ? h.count : m);
    return CutCard(
      padding: const EdgeInsets.all(AppSpace.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.s2,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text('الدخول حسب الساعة · اليوم', style: UType.body(color: c.ink).weight(600)),
                ),
              ),
              if (peak != null) LtrText('الذروة ${_hour(peak)}', style: UType.caption(color: c.inkMuted)),
            ],
          ),
          SizedBox(
            height: AppSize.hoursChart,
            child: max == 0
                ? Center(
                    child: Text('لا دخول مقبول اليوم بعد.', style: UType.label(color: c.inkMuted)),
                  )
                : Semantics(
                    label: 'الدخول حسب الساعة، الذروة ${_hour(peak!)}',
                    child: ExcludeSemantics(
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            for (final h in hours)
                              Expanded(
                                child: Tooltip(
                                  message: '${_hour(h.hour)} · ${h.count}',
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.s1 / 2),
                                    child: FractionallySizedBox(
                                      alignment: Alignment.bottomCenter,
                                      heightFactor: h.count == 0 ? 0.02 : h.count / max,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: h.count >= max * _low ? c.primary : c.line,
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xs)),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
          ExcludeSemantics(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                children: [
                  for (final h in hours)
                    Expanded(
                      child: Text(
                        h.hour % 4 == 0 ? h.hour.toString().padLeft(2, '0') : '',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.visible,
                        softWrap: false,
                        style: UType.caption(color: c.inkFaint),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
