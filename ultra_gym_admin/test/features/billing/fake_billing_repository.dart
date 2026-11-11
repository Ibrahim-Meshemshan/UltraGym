import 'package:get_it/get_it.dart';
import 'package:ultra_gym_admin/core/core.dart';
import 'package:ultra_gym_admin/features/billing/data/repo/billing_repository.dart';
import 'package:ultra_gym_admin/features/billing/domain/models/activity_models.dart';
import 'package:ultra_gym_admin/features/billing/domain/models/billing_models.dart';
import 'package:ultra_gym_admin/features/billing/domain/models/support_models.dart';
import 'package:ultra_gym_admin/features/billing/presentation/bloc/billing_cubits.dart';

/// `billing/subscription.current` بشكل `BillingController::subscriptionPayload`.
Json platformSubJson({int id = 4, String status = 'active', bool current = true, String? grace = '2026-12-07'}) => {
  'id': id,
  'plan': {'id': 2, 'name': 'Pro'},
  'status': status,
  'is_trial': status == 'trial',
  'is_current': current,
  'billing_cycle': 'monthly',
  'starts_at': '2026-11-01',
  'ends_at': '2026-11-30',
  'grace_ends_at': grace,
};

Json overviewJson({Json? current, List<Json> history = const [], double outstanding = 0, int overdue = 0}) => {
  'current': current,
  'history': history,
  'balance': {'currency': 'USD', 'outstanding': outstanding, 'overdue_invoices': overdue},
};

/// `GET club` (الاستعمال فقط؛ رد حقيقي 2026-11-11 بحدود null).
Json usageJson({int? playersLimit = 200, int playersUsed = 128, int? branchesLimit = 10}) => {
  'usage': {
    'players': {'used': playersUsed, 'limit': playersLimit},
    'staff': {'used': 2, 'limit': null},
    'branches': {'used': 2, 'limit': branchesLimit},
  },
  'subscription': {'days_remaining': 19},
};

Json invoiceJson({
  int id = 7,
  String number = 'INV-2026-0007',
  String status = 'pending',
  bool overdue = false,
  double total = 49,
  double paid = 0,
  List<Json> payments = const [],
}) => {
  'id': id,
  'number': number,
  'plan_name': 'Pro',
  'billing_cycle': 'monthly',
  'period_start': '2026-11-01',
  'period_end': '2026-11-30',
  'currency': 'USD',
  'subtotal': total,
  'discount': 0,
  'total': total,
  'paid_amount': paid,
  'remaining_amount': total - paid,
  'status': status,
  'is_overdue': overdue,
  'issued_at': '2026-11-01',
  'due_date': '2026-11-08',
  'paid_at': status == 'paid' ? '2026-11-02T10:00:00Z' : null,
  'cancellation_reason': null,
  'payments': payments,
};

Json ticketJson({
  int id = 3,
  String number = 'TCK-000003',
  String subject = 'الإيصال لا يطبع من الاستقبال',
  String status = 'in_progress',
  bool awaiting = true,
  String category = 'technical',
}) => {
  'id': id,
  'number': number,
  'subject': subject,
  'category': category,
  'priority': 'medium',
  'status': status,
  'replies_count': 2,
  'last_reply_at': '2026-11-11T08:00:00Z',
  'last_reply_by': awaiting ? 'support' : 'user',
  'awaiting_reply': awaiting,
  'resolved_at': null,
  'closed_at': null,
  'created_at': '2026-11-10T09:00:00Z',
  'updated_at': '2026-11-11T08:00:00Z',
};

Json replyJson({int id = 1, bool support = false, String message = 'الطابعة لا تستجيب.', List<Json> files = const []}) =>
    {
      'id': id,
      'author': {'type': support ? 'support' : 'user', 'id': support ? null : 1, 'name': support ? 'فريق الدعم' : 'سامر الحلبي'},
      'message': message,
      'attachments': files,
      'created_at': '2026-11-10T09:00:00Z',
    };

/// سطر سجل حقيقي (2026-11-11) مع حقول التفاصيل حين `detail`.
Json activityJson({int id = 206, bool support = false, bool detail = false}) => {
  'id': id,
  'action': 'club.settings_updated',
  'module': 'club',
  'module_label': 'النادي والإعدادات',
  'description': 'تعديل إعدادات النادي',
  'actor': {'id': 1, 'name': 'سامر الحلبي'},
  'by_platform_support': support,
  'subject': {'type': 'Tenant', 'id': 1, 'label': 'نادي القمة التجريبي'},
  'created_at': '2026-11-10T17:32:12Z',
  if (detail) ...{
    'old_values': {'grace_days': 3, 'receipt_footer': null},
    'new_values': {'grace_days': 5, 'receipt_footer': null},
    'ip_address': '127.0.0.1',
  },
};

const activityModules = [
  {'key': 'club', 'label': 'النادي والإعدادات'},
  {'key': 'transaction', 'label': 'الحركات المالية'},
];

Paged<T> pageOf<T>(List<T> items, {Json meta = const {}, int? total}) => Paged(
  items: items,
  pagination: Pagination(total: total ?? items.length, perPage: 15, lastPage: 1),
  meta: meta,
);

class FakeBillingRepository implements BillingRepository {
  ApiResult<BillingOverview> overviewResult = ApiSuccess(
    BillingOverview.fromJson(
      overviewJson(
        current: platformSubJson(),
        history: [platformSubJson(id: 3, status: 'expired', current: false)],
        outstanding: 49,
        overdue: 1,
      ),
    ),
  );
  ApiResult<PlanUsage> usageResult = ApiSuccess(PlanUsage.fromJson(usageJson()));
  ApiResult<Paged<PlatformInvoice>> invoicesResult = ApiSuccess(
    pageOf([
      PlatformInvoice.fromJson(invoiceJson(overdue: true)),
      PlatformInvoice.fromJson(invoiceJson(id: 6, number: 'INV-2026-0006', status: 'paid', paid: 49)),
    ]),
  );
  ApiResult<PlatformInvoice>? invoiceResult;
  final queries = <ListQuery>[];
  final opened = <int>[], pdfs = <int>[];

  @override
  Future<ApiResult<BillingOverview>> overview() async => overviewResult;

  @override
  Future<ApiResult<PlanUsage>> usage() async => usageResult;

  @override
  Future<ApiResult<Paged<PlatformInvoice>>> invoices(ListQuery query) async {
    queries.add(query);
    return invoicesResult;
  }

  @override
  Future<ApiResult<PlatformInvoice>> invoice(int id) async {
    opened.add(id);
    return invoiceResult ??
        ApiSuccess(
          PlatformInvoice.fromJson(
            invoiceJson(
              id: id,
              status: 'partially_paid',
              paid: 20,
              payments: [
                {'id': 1, 'amount': 20, 'method': 'bank_transfer', 'reference_number': 'TRX-55', 'paid_at': '2026-11-03'},
              ],
            ),
          ),
        );
  }

  @override
  Future<ApiResult<FileBlob>> invoicePdf(int id) async {
    pdfs.add(id);
    // بلا ملف حقيقي بالاختبار (BlobOpener للمتصفح فقط): الفشل يظهر برسالة.
    return const ApiFailure(Failure(type: FailureType.network, message: 'تعذّر التنزيل.'));
  }
}

class FakeSupportRepository implements SupportRepository {
  ApiResult<Paged<SupportTicket>> ticketsResult = ApiSuccess(
    pageOf([
      SupportTicket.fromJson(ticketJson()),
      SupportTicket.fromJson(
        ticketJson(id: 2, number: 'TCK-000002', subject: 'سؤال عن الفاتورة', status: 'closed', awaiting: false),
      ),
    ]),
  );
  final threads = <int, ApiResult<TicketThread>>{};
  ApiResult<SupportTicket>? openResult;
  ApiResult<TicketReply>? replyResult;

  final queries = <ListQuery>[];
  final threadCalls = <int>[];
  final openCalls = <({Json fields, List<PickedUpload> files, String? key})>[];
  final replyCalls = <({int id, String message, List<PickedUpload> files, String? key})>[];

  TicketThread threadOf(Json ticket, {List<Json>? replies}) => TicketThread.fromJson({
    'ticket': ticket,
    'replies': replies ?? [replyJson(), replyJson(id: 2, support: true, message: 'نعمل عليها الآن.')],
    'replies_total': 2,
    'replies_truncated': false,
  });

  @override
  Future<ApiResult<Paged<SupportTicket>>> tickets(ListQuery query) async {
    queries.add(query);
    return ticketsResult;
  }

  @override
  Future<ApiResult<TicketThread>> ticket(int id) async {
    threadCalls.add(id);
    return threads[id] ??
        ApiSuccess(threadOf(ticketJson(id: id, status: id == 2 ? 'closed' : 'in_progress', awaiting: id != 2)));
  }

  @override
  Future<ApiResult<SupportTicket>> open(Json fields, List<PickedUpload> files, {String? idempotencyKey}) async {
    openCalls.add((fields: fields, files: files, key: idempotencyKey));
    return openResult ??
        ApiSuccess(
          SupportTicket.fromJson(ticketJson(id: 9, number: 'TCK-000009', subject: '${fields['subject']}', status: 'open')),
          message: 'تم فتح التذكرة',
        );
  }

  @override
  Future<ApiResult<TicketReply>> reply(int id, String message, List<PickedUpload> files, {String? idempotencyKey}) async {
    replyCalls.add((id: id, message: message, files: files, key: idempotencyKey));
    return replyResult ?? ApiSuccess(TicketReply.fromJson(replyJson(id: 5, message: message)), message: 'تم إرسال الرد');
  }
}

class FakeActivityLogRepository implements ActivityLogRepository {
  ApiResult<Paged<ActivityEntry>> listResult = ApiSuccess(
    pageOf(
      [ActivityEntry.fromJson(activityJson()), ActivityEntry.fromJson(activityJson(id: 205, support: true))],
      meta: {'modules': activityModules},
    ),
  );
  ApiResult<List<ActivityUser>> usersResult = const ApiSuccess([(id: 1, name: 'سامر الحلبي'), (id: 2, name: 'ريم العلي')]);
  ApiResult<ActivityEntry>? entryResult;
  final queries = <ListQuery>[];
  final entries = <int>[];

  @override
  Future<ApiResult<Paged<ActivityEntry>>> list(ListQuery query) async {
    queries.add(query);
    return listResult;
  }

  @override
  Future<ApiResult<ActivityEntry>> entry(int id) async {
    entries.add(id);
    return entryResult ?? ApiSuccess(ActivityEntry.fromJson(activityJson(id: id, detail: true)));
  }

  @override
  Future<ApiResult<List<ActivityUser>>> users() async => usersResult;
}

void registerBillingFakes(FakeBillingRepository billing, FakeSupportRepository support, FakeActivityLogRepository log) {
  GetIt.instance
    ..registerSingleton<BillingRepository>(billing)
    ..registerSingleton<SupportRepository>(support)
    ..registerSingleton<ActivityLogRepository>(log)
    ..registerFactory(() => BillingOverviewCubit(billing))
    ..registerFactory(() => PlanUsageCubit(billing))
    ..registerFactory(() => InvoicesCubit(billing))
    ..registerFactory(() => SupportTicketsCubit(support))
    ..registerFactory(() => ActivityLogCubit(log))
    ..registerFactory(() => ActivityUsersCubit(log));
}
