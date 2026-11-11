import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../../branches/presentation/bloc/branch_scope_cubit.dart';
import '../../domain/models/attendance_models.dart';
import '../bloc/attendance_cubit.dart';
import '../widgets/attendance_table.dart';
import '../widgets/attendance_today.dart';
import '../widgets/check_in_dialog.dart';

/// الحضور (`Attendance.html`): أرقام اليوم والدخول حسب الساعة لفرع، ثم سجل الحضور بفلاتره، و "تسجيل دخول يدوي".
/// أرقام اليوم تحتاج فرعاً: فرع الشريط العلوي، أو الرئيسي حين يكون على "كل الفروع".
class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final (ready, branchId, todayBranch) = context.select<BranchScopeCubit, (bool, int?, int?)>(
      (c) => (!c.state.branches.isFirstLoad, c.state.branchId, c.state.branchId ?? c.state.mainId),
    );
    if (!ready) return const AppPage(children: [StatsShimmer(), TableShimmer(columns: 6)]);
    final query = attendanceQueryFrom(GoRouterState.of(context).uri.queryParameters);
    return MultiBlocProvider(
      key: ValueKey((branchId, query)),
      providers: [
        BlocProvider(create: (_) => sl<AttendanceTodayCubit>(param1: todayBranch)..load()),
        BlocProvider(create: (_) => sl<AttendanceListCubit>(param1: (branchId: branchId, query: query))..load()),
      ],
      child: _Body(todayBranch: todayBranch),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.todayBranch});

  final int? todayBranch;

  Future<void> _checkIn(BuildContext context) async {
    final today = context.read<AttendanceTodayCubit>();
    final list = context.read<AttendanceListCubit>();
    final recorded = await CheckInDialog.show(context, fallbackBranch: todayBranch);
    if (!recorded) return;
    await Future.wait([today.refresh(), list.refresh(keepPage: true)]);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final list = context.read<AttendanceListCubit>();
    final branchName = context.select<AttendanceTodayCubit, String?>((t) => t.state.data?.branchName);
    final isDefault = context.select<AttendanceListCubit, bool>(
      (l) => asJson(l.state.slice.data?.meta['period']).flag('is_default'),
    );
    return AppPage(
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpace.s4,
          runSpacing: AppSpace.s3,
          children: [
            Semantics(
              header: true,
              child: Text(
                branchName == null ? 'حضور اليوم' : 'حضور اليوم · $branchName',
                style: UType.h3(color: c.ink),
              ),
            ),
            UGButton(label: 'تسجيل دخول يدوي', icon: Icons.login_rounded, onPressed: () => _checkIn(context)),
          ],
        ),
        AttendanceTodaySection(onRejected: () => list.filter(AttendanceFilters.status, 'rejected')),
        const AttendanceTable(),
        Text(
          isDefault
              ? 'الدخول المرفوض يُحفظ مع سببه. بلا فترة محددة يعرض السجل آخر ${AttendanceFilters.defaultDays} يوماً.'
              : 'الدخول المرفوض يُحفظ مع سببه ليعرف المالك من حاول الدخول.',
          style: UType.caption(color: c.inkMuted),
        ),
      ],
    );
  }
}
