import '../../../../core/core.dart';
import '../../data/repo/billing_repository.dart';
import '../../domain/models/activity_models.dart';
import '../../domain/models/billing_models.dart';
import '../../domain/models/support_models.dart';

/// اشتراك النادي الحالي وسجله والمستحق للمنصة.
class BillingOverviewCubit extends LoadCubit<BillingOverview> {
  BillingOverviewCubit(BillingRepository repo) : super(repo.overview);
}

/// الاستعمال مقابل الحدود (`GET club.usage`). فشله يخفي البطاقة فقط.
class PlanUsageCubit extends LoadCubit<PlanUsage> {
  PlanUsageCubit(BillingRepository repo) : super(repo.usage);
}

/// فواتير المنصة.
class InvoicesCubit extends ListCubit<PlatformInvoice> {
  InvoicesCubit(BillingRepository repo) : super(repo.invoices);
}

/// فاتورة واحدة بدفعاتها (نافذة التفاصيل).
class InvoiceDetailCubit extends LoadCubit<PlatformInvoice> {
  InvoiceDetailCubit(BillingRepository repo, int id) : super(() => repo.invoice(id));
}

/// تذاكر الدعم.
class SupportTicketsCubit extends ListCubit<SupportTicket> {
  SupportTicketsCubit(SupportRepository repo) : super(repo.tickets);
}

/// محادثة تذكرة واحدة.
class TicketThreadCubit extends LoadCubit<TicketThread> {
  TicketThreadCubit(SupportRepository repo, int id) : super(() => repo.ticket(id));
}

/// سجل النشاط (50 بالصفحة).
class ActivityLogCubit extends ListCubit<ActivityEntry> {
  ActivityLogCubit(ActivityLogRepository repo) : super(repo.list, query: const ListQuery(perPage: 50));
}

/// مستخدمو فلتر السجل. فشله يخفي الفلتر فقط.
class ActivityUsersCubit extends LoadCubit<List<ActivityUser>> {
  ActivityUsersCubit(ActivityLogRepository repo) : super(repo.users);
}

/// تفاصيل سطر بالسجل (القيم قبل وبعد).
class ActivityEntryCubit extends LoadCubit<ActivityEntry> {
  ActivityEntryCubit(ActivityLogRepository repo, int id) : super(() => repo.entry(id));
}
