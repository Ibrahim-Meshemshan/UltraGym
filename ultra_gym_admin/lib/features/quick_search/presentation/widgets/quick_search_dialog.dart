import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../domain/models/quick_search_models.dart';
import '../bloc/quick_search_cubit.dart';
import 'lookup_tile.dart';

/// نافذة البحث السريع: حقل البحث بالأعلى والنتائج تحته. Enter يفتح أول نتيجة، و Esc يغلق.
/// الضغط على عضو يفتح ملفه (`/members/{id}`)، أو يرجعه للنافذة المستدعية بوضع الاختيار (`picking`).
class QuickSearchDialog extends StatelessWidget {
  const QuickSearchDialog({super.key, this.picking = false});

  /// اختيار عضو لعملية (البيع مثلاً): يغلق النافذة ويرجع العضو بدل فتح ملفه.
  final bool picking;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final cubit = context.read<QuickSearchCubit>();
    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.fromLTRB(AppSpace.s4, AppSpace.s16, AppSpace.s4, AppSpace.s4),
      backgroundColor: c.surface,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(AppRadius.hero))),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSize.searchDialog, maxHeight: AppSize.searchDialog),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpace.s4),
              child: TextField(
                autofocus: true,
                onChanged: cubit.changed,
                onSubmitted: (_) => _chooseFirst(context),
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: 'ابحث بالاسم أو الموبايل أو معرّف العضو',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
            Divider(height: 1, color: c.line),
            Flexible(
              child: BlocBuilder<QuickSearchCubit, QuickSearchState>(
                builder: (context, s) =>
                    s.tooShort ? const _Hint() : _Results(state: s, onPick: (p) => choose(context, p)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _chooseFirst(BuildContext context) {
    final first = context.read<QuickSearchCubit>().state.results.data?.firstOrNull;
    if (first != null) choose(context, first);
  }

  void choose(BuildContext context, LookupPlayer p) => picking ? Navigator.of(context).pop(p) : openMember(context, p);

  /// يغلق النافذة ثم يفتح ملف العضو.
  static void openMember(BuildContext context, LookupPlayer p) {
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.go(Routes.child(Routes.members, p.id));
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.state, required this.onPick});

  final QuickSearchState state;
  final ValueChanged<LookupPlayer> onPick;

  @override
  Widget build(BuildContext context) => SliceView<List<LookupPlayer>>(
    slice: state.results,
    loading: const Padding(padding: EdgeInsets.all(AppSpace.s4), child: ListShimmer(count: 3)),
    onRetry: context.read<QuickSearchCubit>().retry,
    frame: (child) => Padding(padding: const EdgeInsets.all(AppSpace.s4), child: child),
    isEmpty: (list) => list.isEmpty,
    empty: _Note(
      icon: Icons.person_search_rounded,
      text: 'لا يوجد عضو يطابق "${state.query}". تأكد من الرقم أو جرّب جزءاً من الاسم.',
    ),
    builder: (context, list) => ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.all(AppSpace.s2),
      itemCount: list.length,
      separatorBuilder: (_, _) => AppSpace.gap1,
      itemBuilder: (context, i) => LookupTile(player: list[i], onTap: () => onPick(list[i])),
    ),
  );
}

class _Hint extends StatelessWidget {
  const _Hint();

  @override
  Widget build(BuildContext context) =>
      const _Note(icon: Icons.keyboard_rounded, text: 'اكتب حرفين على الأقل من الاسم أو الموبايل أو معرّف العضو.');
}

/// سطر توضيح هادئ داخل النافذة (التلميح، لا نتائج).
class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.s5, vertical: AppSpace.s6),
      child: Row(
        children: [
          Icon(icon, size: AppSize.icon, color: c.inkFaint),
          AppSpace.gap3,
          Expanded(
            child: Text(text, style: UType.body(color: c.inkMuted)),
          ),
        ],
      ),
    );
  }
}
