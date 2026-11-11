import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../branches/domain/models/branch_models.dart';
import '../../domain/models/branch_draft.dart';
import '../../domain/models/settings_models.dart';
import '../bloc/settings_cubits.dart';
import 'branch_editor.dart';
import 'branch_list_card.dart';

/// تبويب الفروع (`BranchSettings.html`): القائمة بجانب المحرر من `AppSize.profileSplit`، وأضيق فوقه.
/// الفرع المفتوح `ValueCubit<int?>` (null = الأول، 0 = جديد)، والمحرر يُنشأ من جديد مع كل فرع أو نسخة منه أو "إلغاء".
class BranchesTab extends StatelessWidget {
  const BranchesTab({super.key});

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(create: (_) => ValueCubit<int?>(null)),
      BlocProvider(create: (_) => ValueCubit<int>(0)),
    ],
    child: BlocBuilder<SettingsBranchesCubit, Slice<List<Branch>>>(
      builder: (context, slice) => SliceView<List<Branch>>(
        slice: slice,
        loading: const DetailsShimmer(lines: 8),
        onRetry: context.read<SettingsBranchesCubit>().load,
        builder: (context, branches) => _Body(branches),
      ),
    ),
  );
}

class _Body extends StatelessWidget {
  const _Body(this.branches);

  final List<Branch> branches;

  @override
  Widget build(BuildContext context) {
    final picked = context.watch<ValueCubit<int?>>().state;
    final version = context.watch<ValueCubit<int>>().state;
    final club = context.select<ClubCubit, ClubProfile?>((c) => c.state.data);
    final branch = picked == 0 ? null : (branches.where((b) => b.id == picked).firstOrNull ?? branches.firstOrNull);
    final selected = branch?.id ?? 0;
    final list = BranchListCard(
      branches: branches,
      selected: selected,
      club: club,
      onSelect: context.read<ValueCubit<int?>>().set,
    );
    final editor = BlocProvider(
      key: ValueKey((selected, branch, version)),
      create: (_) => sl<BranchEditorCubit>(param1: branch == null ? const BranchDraft() : BranchDraft.of(branch)),
      child: BranchEditor(
        branch: branch,
        onSaved: (b) {
          context.read<ValueCubit<int?>>().set(b.id);
          if (branch == null) context.read<ClubCubit>().refresh();
        },
        onCancel: () => picked == 0
            ? context.read<ValueCubit<int?>>().set(null)
            : context.read<ValueCubit<int>>().update((v) => v + 1),
      ),
    );
    return LayoutBuilder(
      builder: (context, box) => box.maxWidth >= AppSize.profileSplit
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpace.s5,
              children: [
                SizedBox(width: AppSize.branchListWidth, child: list),
                Expanded(child: editor),
              ],
            )
          : Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: AppSpace.s5, children: [list, editor]),
    );
  }
}
