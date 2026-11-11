import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../branches/presentation/bloc/branch_scope_cubit.dart';
import '../../domain/models/member_models.dart';
import '../bloc/members_cubit.dart';
import '../widgets/add_member_dialog.dart';
import '../widgets/members_table.dart';

/// الأعضاء (`Members.html`): تبويبا الأعضاء والأرشيف بعدّادين، وجدول `GET club-admin/players`
/// بفرع الشريط العلوي. الفلتر الأولي من رابط الصفحة (`membersQueryFrom`).
class MembersScreen extends StatelessWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final (ready, branchId) = context.select<BranchScopeCubit, (bool, int?)>(
      (c) => (!c.state.branches.isFirstLoad, c.state.branchId),
    );
    if (!ready) return const AppPage(children: [TableShimmer(columns: 6)]);
    final initial = membersQueryFrom(GoRouterState.of(context).uri.queryParameters);
    return MultiBlocProvider(
      key: ValueKey(branchId),
      providers: [
        BlocProvider(create: (_) => ValueCubit<MembersTab>(MembersTab.current)),
        BlocProvider(create: (_) => sl<MemberCountsCubit>(param1: branchId)..load()),
      ],
      child: BlocBuilder<ValueCubit<MembersTab>, MembersTab>(
        builder: (context, tab) => BlocProvider(
          key: ValueKey((tab, initial)),
          create: (_) => sl<MembersListCubit>(
            param1: (tab: tab, branchId: branchId, query: tab == MembersTab.current ? initial : const ListQuery()),
          )..load(),
          child: const _MembersView(),
        ),
      ),
    );
  }
}

class _MembersView extends StatelessWidget {
  const _MembersView();

  @override
  Widget build(BuildContext context) {
    final isOwner = context.select<AuthBloc, bool>((b) => b.state.session?.isClubOwner ?? false);
    final current = context.read<MembersListCubit>().tab == MembersTab.current;
    return AppPage(
      children: [
        const _Header(),
        MembersTable(isOwner: isOwner, onAdd: current ? () => addMember(context) : null),
      ],
    );
  }
}

/// التبويبان بعدّاديهما، وزر "إضافة عضو". فشل العدّادين يُخفي الأرقام فقط.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final tab = context.watch<ValueCubit<MembersTab>>();
    final counts = context.select<MemberCountsCubit, MemberCounts?>((c) => c.state.data);
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: AppSpace.s4,
      runSpacing: AppSpace.s3,
      children: [
        AppTabs(
          tabs: [(label: 'الأعضاء', count: counts?.members), (label: 'الأرشيف', count: counts?.archived)],
          selected: tab.state.index,
          onSelect: (i) => tab.set(MembersTab.values[i]),
        ),
        UGButton(label: 'إضافة عضو', icon: Icons.person_add_alt_1_rounded, onPressed: () => addMember(context)),
      ],
    );
  }
}
