import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../domain/models/announcements_models.dart';
import '../bloc/announcements_cubit.dart';
import 'announcement_actions.dart';

/// بطاقة الإعلانات: الرأس (الحالة، الشرح، "إعلان جديد")، ثم الإعلانات مفصولة بخطوط، والصفحات.
class AnnouncementsList extends StatelessWidget {
  const AnnouncementsList({super.key});

  @override
  Widget build(BuildContext context) {
    final list = context.read<AnnouncementsCubit>();
    final state = context.watch<AnnouncementsCubit>().state;
    final filtered = state.query.hasFilters;
    Future<void> save([Announcement? a]) async {
      if (await AnnouncementActions.save(context, existing: a)) await list.refresh(keepPage: a != null);
    }

    Future<void> delete(Announcement a) async {
      if (await AnnouncementActions.delete(context, a)) await list.refresh(keepPage: true);
    }

    // زر الرأس يغيب حين تعرض الحالة الفارغة زرها نفسه (زر أساسي واحد).
    final emptyInvite = !filtered && (state.slice.data?.isEmpty ?? false);
    return CutCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            state: state.query.filter(AnnouncementState.filter) as String?,
            onState: (v) => list.filter(AnnouncementState.filter, v),
            onAdd: emptyInvite ? null : save,
          ),
          SliceView<Paged<Announcement>>(
            slice: state.slice,
            loading: const Padding(padding: EdgeInsets.all(AppSpace.s5), child: ListShimmer(count: 4)),
            onRetry: list.load,
            frame: (child) => Padding(padding: const EdgeInsets.all(AppSpace.s5), child: child),
            isEmpty: (p) => p.isEmpty,
            empty: Padding(
              padding: const EdgeInsets.all(AppSpace.s5),
              child: filtered
                  ? NoResults(onClear: list.clearFilters)
                  : AppEmptyState(
                      icon: Icons.campaign_rounded,
                      title: 'لا إعلانات بعد',
                      message: 'انشر موعداً أو عرضاً أو تنبيهاً ليظهر في تطبيق الأعضاء، مع إشعار لهواتفهم إن أردت.',
                      actionLabel: 'إعلان جديد',
                      onAction: save,
                    ),
            ),
            builder: (context, page) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final a in page.items) ...[
                  Divider(height: 1, color: context.colors.line),
                  AnnouncementTile(a, onEdit: () => save(a), onDelete: () => delete(a)),
                ],
                PaginationBar(pagination: page.pagination, onPage: list.goTo, noun: 'إعلاناً'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.state, required this.onState, required this.onAdd});

  final String? state;
  final ValueChanged<String?> onState;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpace.s5, vertical: AppSpace.s4),
    child: Wrap(
      spacing: AppSpace.s3,
      runSpacing: AppSpace.s3,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        FilterChoiceChips<String>(
          semanticsLabel: 'الحالة',
          options: AnnouncementTexts.states,
          value: state,
          onChanged: onState,
        ),
        Text('تظهر في تطبيق العضو، ويمكن إرسالها إشعاراً لهاتفه.', style: UType.label(color: context.colors.inkMuted)),
        if (onAdd != null) UGButton(label: 'إعلان جديد', icon: Icons.add_rounded, onPressed: onAdd),
      ],
    ),
  );
}

/// إعلان بالقائمة: شارة الحالة، العنوان والنص، سطر التفاصيل، و "تعديل" / حذف.
class AnnouncementTile extends StatelessWidget {
  const AnnouncementTile(this.a, {super.key, required this.onEdit, required this.onDelete});

  final Announcement a;
  final VoidCallback onEdit, onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final st = AnnouncementTexts.state(a.state);
    final push = AnnouncementTexts.push(a);
    final meta = UType.caption(color: c.inkMuted);
    final mobile = context.isMobile;
    final badge = StatusBadge(st.text, tone: st.tone);
    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(onPressed: onEdit, child: const Text('تعديل')),
        IconButton(
          tooltip: 'حذف ${a.title}',
          onPressed: onDelete,
          color: c.dangerInk,
          icon: const Icon(Icons.delete_outline_rounded),
        ),
      ],
    );
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpace.s1,
      children: [
        if (mobile) badge,
        Text(a.title, style: UType.h3(color: c.ink)),
        Text(a.body, style: UType.body(color: c.inkMuted), maxLines: 3, overflow: TextOverflow.ellipsis),
        Wrap(
          spacing: AppSpace.s2,
          runSpacing: AppSpace.s1,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(AnnouncementTexts.audience(a.audience), style: meta),
            Text('·', style: meta),
            Text(AnnouncementTexts.branch(a), style: meta),
            Text('·', style: meta),
            Text(AnnouncementTexts.when(a), style: meta),
            if (push != null) StatusBadge(push, tone: UTone.info),
          ],
        ),
      ],
    );
    return InkWell(
      onTap: onEdit,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.s5, vertical: AppSpace.s4),
        child: mobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [content, Align(alignment: AlignmentDirectional.centerEnd, child: actions)],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpace.s4,
                children: [badge, Expanded(child: content), actions],
              ),
      ),
    );
  }
}
