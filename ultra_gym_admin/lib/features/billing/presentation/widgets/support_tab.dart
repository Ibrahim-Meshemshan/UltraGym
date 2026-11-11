import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../bloc/billing_cubits.dart';
import 'support_actions.dart';
import 'ticket_list_card.dart';
import 'ticket_thread.dart';

/// تبويب "الدعم الفني" (`ClubBilling.html`): التذاكر بجانب محادثة المحددة من `AppSize.profileSplit`، وأضيق فوقها.
/// المحددة `ValueCubit<int?>` (null = الأولى بالقائمة؛ رابط الإشعار `?ticket_id=` يحددها).
class SupportTab extends StatelessWidget {
  const SupportTab({super.key});

  @override
  Widget build(BuildContext context) {
    final list = context.read<SupportTicketsCubit>();
    final picked = context.watch<ValueCubit<int?>>();
    final first = context.select<SupportTicketsCubit, int?>((l) => l.state.slice.data?.items.firstOrNull?.id);
    final id = picked.state ?? first;

    Future<void> create() async {
      final t = await SupportActions.open(context);
      if (t == null || !context.mounted) return;
      await list.load();
      picked.set(t.id);
    }

    final tickets = TicketListCard(selected: id, onSelect: picked.set, onNew: create);
    final thread = id == null
        ? null
        : BlocProvider(
            key: ValueKey(id),
            create: (_) => TicketThreadCubit(sl(), id)..load(),
            child: TicketThreadCard(onReplied: () => list.refresh(keepPage: true)),
          );
    return LayoutBuilder(
      builder: (context, box) => box.maxWidth >= AppSize.profileSplit
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpace.s4,
              children: [
                SizedBox(width: AppSize.ticketListWidth, child: tickets),
                Expanded(child: thread ?? const SizedBox.shrink()),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpace.s4,
              children: [tickets, ?thread],
            ),
    );
  }
}
