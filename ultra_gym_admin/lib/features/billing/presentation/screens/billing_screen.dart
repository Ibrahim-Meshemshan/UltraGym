import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../bloc/billing_cubits.dart';
import '../widgets/activity_tab.dart';
import '../widgets/invoice_dialog.dart';
import '../widgets/invoices_table.dart';
import '../widgets/subscription_card.dart';
import '../widgets/support_tab.dart';
import '../widgets/usage_card.dart';

/// اشتراك النادي والدعم (`ClubBilling.html`، للمالك): تبويبات "اشتراك النادي والفواتير" / "الدعم الفني"
/// (`?tab=support`، و `&ticket_id=` يفتح تذكرة) / "سجل النشاط" (`?tab=activity`). `?invoice_id=` (إشعار
/// `billing_invoice`) يفتح الفاتورة فوق التبويب الأول. شريط فترة السماح / القراءة فقط يعرضه الهيكل.
class BillingScreen extends StatelessWidget {
  const BillingScreen({super.key});

  static const tabKeys = [null, 'support', 'activity'];

  @override
  Widget build(BuildContext context) {
    final params = GoRouterState.of(context).uri.queryParameters;
    final tab = params['tab'];
    final ticket = int.tryParse(params['ticket_id'] ?? '');
    final invoice = int.tryParse(params['invoice_id'] ?? '');
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<BillingOverviewCubit>()..load()),
        BlocProvider(create: (_) => sl<PlanUsageCubit>()..load()),
        BlocProvider(create: (_) => sl<InvoicesCubit>()..load()),
        BlocProvider(create: (_) => sl<SupportTicketsCubit>()..load()),
        BlocProvider(create: (_) => sl<ActivityLogCubit>()..load()),
        BlocProvider(create: (_) => sl<ActivityUsersCubit>()..load()),
        BlocProvider(key: ValueKey(tab), create: (_) => ValueCubit<int>(tabKeys.indexOf(tab).clamp(0, 2))),
        BlocProvider(key: ValueKey(ticket), create: (_) => ValueCubit<int?>(ticket)),
      ],
      child: OnInit(
        key: ValueKey(invoice),
        onInit: (context) {
          if (invoice != null) InvoiceDialog.show(context, invoice);
        },
        child: const _Body(),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  static const _tabs = [
    (label: 'اشتراك النادي والفواتير', count: null),
    (label: 'الدعم الفني', count: null),
    (label: 'سجل النشاط', count: null),
  ];

  @override
  Widget build(BuildContext context) {
    final tab = context.watch<ValueCubit<int>>().state;
    return AppPage(
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: tab == 2,
            child: AppTabs(tabs: _tabs, selected: tab, onSelect: context.read<ValueCubit<int>>().set),
          ),
        ),
        switch (tab) {
          1 => const SupportTab(),
          2 => const ActivityTab(),
          _ => const _SubscriptionTab(),
        },
      ],
    );
  }
}

/// الاشتراك والفواتير بعمود، والاستخدام بجانبهما من `AppSize.profileSplit` (وأضيق تحت الاشتراك).
class _SubscriptionTab extends StatelessWidget {
  const _SubscriptionTab();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      const main = [SubscriptionCard(), InvoicesTable()];
      if (box.maxWidth < AppSize.profileSplit) {
        return const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpace.s5,
          children: [SubscriptionCard(), UsageCard(), InvoicesTable()],
        );
      }
      return const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpace.s5,
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: AppSpace.s5, children: main),
          ),
          SizedBox(width: AppSize.usageCardWidth, child: UsageCard()),
        ],
      );
    },
  );
}
