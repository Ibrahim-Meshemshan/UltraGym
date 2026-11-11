import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../widgets/measurements_section.dart';
import '../widgets/workout_plans_section.dart';

/// المدربون والتدريب (`Training.html`): تبويبا "خطط التمارين" و "القياسات"، ورابط "المدربون" لمن يدير الموظفين.
/// التعديل للمالك؛ الاستقبال يقرأ البرامج والقياسات (CLAUDE.md، وإن قبل الخادم كتابته).
/// الرابط: `?tab=measurements&player_id=12` يفتح قياسات عضو (من ملفه).
class TrainingScreen extends StatelessWidget {
  const TrainingScreen({super.key});

  static const measurementsTab = 'measurements';

  @override
  Widget build(BuildContext context) {
    final q = GoRouterState.of(context).uri.queryParameters;
    final playerId = int.tryParse(q['player_id'] ?? '');
    return BlocProvider(
      key: ValueKey('${q['tab']}-$playerId'),
      create: (_) => ValueCubit<int>(q['tab'] == measurementsTab ? 1 : 0),
      child: _Body(playerId: playerId),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.playerId});

  final int? playerId;

  static const _tabs = [(label: 'خطط التمارين', count: null), (label: 'القياسات', count: null)];

  @override
  Widget build(BuildContext context) {
    final owner = context.select<AuthBloc, bool>((b) => b.state.session?.isClubOwner ?? false);
    final staff = context.select<AuthBloc, bool>((b) => b.state.session?.canManageStaff ?? false);
    final tab = context.watch<ValueCubit<int>>().state;
    return AppPage(
      children: [
        Wrap(
          spacing: AppSpace.s3,
          runSpacing: AppSpace.s2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AppTabs(tabs: _tabs, selected: tab, onSelect: context.read<ValueCubit<int>>().set),
            if (staff)
              TextButton.icon(
                onPressed: () => context.go(Routes.staffMembers),
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('المدربون'),
              ),
          ],
        ),
        if (tab == 1)
          MeasurementsSection(editable: owner, playerId: playerId)
        else
          WorkoutPlansSection(editable: owner),
      ],
    );
  }
}
