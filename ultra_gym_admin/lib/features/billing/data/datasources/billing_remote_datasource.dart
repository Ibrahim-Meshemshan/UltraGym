import 'package:dio/dio.dart';

import '../../../../core/core.dart';
import '../../domain/models/activity_models.dart';
import '../../domain/models/billing_models.dart';
import '../../domain/models/support_models.dart';
import '../repo/billing_repository.dart';

const _base = '/club-admin';

class BillingRemoteDataSource implements BillingRepository {
  BillingRemoteDataSource(this._api);

  final ApiClient _api;
  static const _path = '$_base/billing';

  @override
  Future<ApiResult<BillingOverview>> overview() =>
      _api.getObject('$_path/subscription', fromJson: BillingOverview.fromJson);

  @override
  Future<ApiResult<PlanUsage>> usage() => _api.getObject('$_base/club', fromJson: PlanUsage.fromJson);

  @override
  Future<ApiResult<Paged<PlatformInvoice>>> invoices(ListQuery query) =>
      _api.getPaged('$_path/invoices', fromJson: PlatformInvoice.fromJson, query: query);

  @override
  Future<ApiResult<PlatformInvoice>> invoice(int id) =>
      _api.getObject('$_path/invoices/$id', fromJson: PlatformInvoice.fromJson);

  @override
  Future<ApiResult<FileBlob>> invoicePdf(int id) => _api.getBytes('$_path/invoices/$id/pdf');
}

class SupportRemoteDataSource implements SupportRepository {
  SupportRemoteDataSource(this._api);

  final ApiClient _api;
  static const _path = '$_base/support/tickets';

  @override
  Future<ApiResult<Paged<SupportTicket>>> tickets(ListQuery query) =>
      _api.getPaged(_path, fromJson: SupportTicket.fromJson, query: query);

  @override
  Future<ApiResult<TicketThread>> ticket(int id) => _api.getObject('$_path/$id', fromJson: TicketThread.fromJson);

  @override
  Future<ApiResult<SupportTicket>> open(Json fields, List<PickedUpload> files, {String? idempotencyKey}) =>
      _api.post(
        _path,
        body: _form(fields, files),
        idempotencyKey: idempotencyKey,
        parse: Parse.object(SupportTicket.fromJson),
      );

  @override
  Future<ApiResult<TicketReply>> reply(int id, String message, List<PickedUpload> files, {String? idempotencyKey}) =>
      _api.post(
        '$_path/$id/replies',
        body: _form({'message': message}, files),
        idempotencyKey: idempotencyKey,
        parse: Parse.object(TicketReply.fromJson),
      );

  /// الحقول نصوصاً والملفات بـ `attachments[]` (جزء جديد لكل إرسال).
  static FormData _form(Json fields, List<PickedUpload> files) => FormData()
    ..fields.addAll([
      for (final e in fields.entries)
        if (e.value != null) MapEntry(e.key, '${e.value}'),
    ])
    ..files.addAll([for (final f in files) MapEntry('attachments[]', f.part())]);
}

class ActivityLogRemoteDataSource implements ActivityLogRepository {
  ActivityLogRemoteDataSource(this._api);

  final ApiClient _api;
  static const _path = '$_base/activity-log';

  @override
  Future<ApiResult<Paged<ActivityEntry>>> list(ListQuery query) =>
      _api.getPaged(_path, fromJson: ActivityEntry.fromJson, query: query);

  @override
  Future<ApiResult<ActivityEntry>> entry(int id) => _api.getObject('$_path/$id', fromJson: ActivityEntry.fromJson);

  @override
  Future<ApiResult<List<ActivityUser>>> users() async {
    ActivityUser user(Json j) => (id: j.intv('id'), name: j.str('name'));
    final (owners, staff) = await (
      _api.getList('$_base/accounts', fromJson: user, query: {'role': 'club_owner', 'per_page': 100}),
      _api.getList('$_base/accounts', fromJson: user, query: {'role': 'receptionist', 'per_page': 100}),
    ).wait;
    return switch ((owners, staff)) {
      (ApiSuccess(data: final a), ApiSuccess(data: final b)) => ApiSuccess([...a, ...b]),
      (ApiFailure(:final failure), _) || (_, ApiFailure(:final failure)) => ApiFailure(failure),
    };
  }
}
