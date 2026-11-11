import '../../../../core/core.dart';
import '../../domain/models/activity_models.dart';
import '../../domain/models/billing_models.dart';
import '../../domain/models/support_models.dart';

/// اشتراك النادي بالمنصة وفواتيرها (للمالك، قراءة وطباعة فقط؛ الفواتير والدفعات يسجّلها فريق المنصة).
abstract interface class BillingRepository {
  /// `GET billing/subscription`.
  Future<ApiResult<BillingOverview>> overview();

  /// `GET club` ← الاستعمال مقابل الحدود.
  Future<ApiResult<PlanUsage>> usage();

  /// `GET billing/invoices` (فلاتر `status`، `overdue=1`؛ الأحدث إصداراً أولاً).
  Future<ApiResult<Paged<PlatformInvoice>>> invoices(ListQuery query);

  /// `GET billing/invoices/{id}` مع الدفعات.
  Future<ApiResult<PlatformInvoice>> invoice(int id);

  /// `GET billing/invoices/{id}/pdf`.
  Future<ApiResult<FileBlob>> invoicePdf(int id);
}

/// تذاكر الدعم الفني مع فريق المنصة (للمالك).
abstract interface class SupportRepository {
  /// `GET support/tickets` (فلاتر `status`، `category`، `search`؛ الأحدث نشاطاً أولاً).
  Future<ApiResult<Paged<SupportTicket>>> tickets(ListQuery query);

  /// `GET support/tickets/{id}`.
  Future<ApiResult<TicketThread>> ticket(int id);

  /// `POST support/tickets` (multipart: `subject`، `category`، `priority?`، `message`، `attachments[]`).
  Future<ApiResult<SupportTicket>> open(Json fields, List<PickedUpload> files, {String? idempotencyKey});

  /// `POST support/tickets/{id}/replies` (المغلقة ← 409).
  Future<ApiResult<TicketReply>> reply(int id, String message, List<PickedUpload> files, {String? idempotencyKey});
}

/// سجل النشاط (للمالك): من فعل ماذا ومتى.
abstract interface class ActivityLogRepository {
  /// `GET activity-log` (فلاتر `user_id`، `module`، `from`/`to`، `search`؛ الأقسام بـ `meta.modules`).
  Future<ApiResult<Paged<ActivityEntry>>> list(ListQuery query);

  /// `GET activity-log/{id}` مع القيم قبل وبعد.
  Future<ApiResult<ActivityEntry>> entry(int id);

  /// مستخدمو الفلتر: المالك وموظفو الاستقبال (`GET accounts?role=`).
  Future<ApiResult<List<ActivityUser>>> users();
}
