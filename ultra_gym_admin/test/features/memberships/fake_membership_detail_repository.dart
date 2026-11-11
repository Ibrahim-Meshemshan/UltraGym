import 'package:ultra_gym_admin/core/error/failure.dart';
import 'package:ultra_gym_admin/core/networking/api_client.dart';
import 'package:ultra_gym_admin/core/networking/api_result.dart';
import 'package:ultra_gym_admin/core/networking/list_query.dart';
import 'package:ultra_gym_admin/core/networking/paged.dart';
import 'package:ultra_gym_admin/core/utils/json_x.dart';
import 'package:ultra_gym_admin/features/memberships/data/repo/membership_detail_repository.dart';
import 'package:ultra_gym_admin/features/memberships/domain/models/membership_detail_models.dart';

/// رد حقيقي من `GET club-admin/memberships/3` (الخادم التجريبي، 2026-11-09): تدريب خاص عليه 20$.
/// `created_by` بالبذرة null؛ هنا اسم لأول دفعة ليُختبر عمود "بواسطة".
Json ahmadDetailJson({String status = 'active', String label = 'فعّال', String type = 'duration'}) => {
  'id': 3,
  'player': {'id': 3, 'name': 'أحمد الخطيب'},
  'plan': {'id': 4, 'name': 'تدريب خاص شهري'},
  'type': type,
  'branch': {'id': 1, 'name': 'الفرع الرئيسي - المزة'},
  'starts_on': '2026-10-25',
  'ends_on': '2026-11-23',
  'days_remaining': 15,
  'sessions_total': type == 'sessions' ? 12 : null,
  'sessions_used': type == 'sessions' ? 4 : 0,
  'sessions_remaining': type == 'sessions' ? 8 : null,
  'status': status,
  'status_label': label,
  'frozen_until': status == 'frozen' ? '2026-11-12' : null,
  'price_usd': 60,
  'discount_usd': 0,
  'net_usd': 60,
  'paid_usd': 40,
  'due_usd': 20,
  'due_syp': 260000,
  'trainer': {'id': 1, 'name': 'كابتن مازن'},
  'created_at': '2026-10-25T16:30:00Z',
  'coupon': null,
  'trainer_commission_percent': 20,
  'trainer_commission_usd': 12,
  'freezes': {
    'max_freezes': 2,
    'max_freeze_days': 30,
    'freezes_used': status == 'frozen' ? 1 : 0,
    'freeze_days_used': status == 'frozen' ? 10 : 0,
    'history': [
      if (status == 'frozen')
        {
          'id': 1,
          'starts_on': '2026-11-03',
          'ends_on': '2026-11-12',
          'days': 10,
          'ended_early_on': null,
          'reason': 'سفر',
        },
    ],
  },
  'previous_membership_id': null,
  'cancelled_at': status == 'cancelled' ? '2026-11-09T10:00:00Z' : null,
  'cancellation_reason': status == 'cancelled' ? 'انتقل لمدينة أخرى' : null,
  'notes': null,
  'transactions': [
    {
      'id': 3,
      'receipt_number': 'B1-2026-000003',
      'type_label': 'دفعة اشتراك',
      'direction': 'in',
      'currency': 'USD',
      'amount': 30,
      'amount_usd': 30,
      'is_reversed': false,
      'business_date': '2026-10-25',
      'occurred_at': '2026-10-25T16:30:00Z',
      'created_by': {'id': 2, 'name': 'ريم العلي'},
    },
    {
      'id': 4,
      'receipt_number': 'B1-2026-000004',
      'type_label': 'دفعة اشتراك',
      'direction': 'in',
      'currency': 'SYP',
      'amount': 130000,
      'amount_usd': 10,
      'is_reversed': false,
      'business_date': '2026-10-25',
      'occurred_at': '2026-10-25T16:30:00Z',
      'created_by': null,
    },
  ],
};

/// رد حقيقي من `POST memberships/quote {plan_id: 4, previous_membership_id: 3}`.
final quoteJson = {
  'starts_on': '2026-11-24',
  'ends_on': '2026-12-23',
  'price_usd': 60,
  'discount_usd': 0,
  'net_usd': 60,
  'net_syp': 780000,
  'allow_partial_payment': true,
};

const cashRequired = Failure(
  type: FailureType.conflict,
  code: 'CASH_SESSION_REQUIRED',
  message: 'لا توجد وردية صندوق مفتوحة بهذا الفرع',
);

typedef Sent = ({String action, Json body, String? key});

class FakeMembershipDetailRepository implements MembershipDetailRepository {
  ApiResult<MembershipDetail> detailResult = ApiSuccess(MembershipDetail.fromJson(ahmadDetailJson()));
  ApiResult<void> actionResult = const ApiSuccess(null, message: 'تم بنجاح');
  ApiResult<int> renewResult = const ApiSuccess(14, message: 'تم تسجيل الاشتراك بنجاح');
  ApiResult<Paged<AttendanceEntry>> attendanceResult = const ApiSuccess(
    Paged(items: [], pagination: Pagination(currentPage: 1, perPage: 10, total: 0, lastPage: 1, from: null, to: null)),
  );

  final detailCalls = <int>[];
  final sent = <Sent>[];
  final attendanceCalls = <({int playerId, DateTime? from, DateTime? to})>[];
  final files = <String>[];

  @override
  Future<ApiResult<MembershipDetail>> detail(int id) async {
    detailCalls.add(id);
    return detailResult;
  }

  @override
  Future<ApiResult<Paged<AttendanceEntry>>> attendance(
    ListQuery query, {
    required int playerId,
    DateTime? from,
    DateTime? to,
  }) async {
    attendanceCalls.add((playerId: playerId, from: from, to: to));
    return attendanceResult;
  }

  Future<ApiResult<void>> _record(String action, Json body, [String? key]) async {
    sent.add((action: action, body: body, key: key));
    return actionResult;
  }

  @override
  Future<ApiResult<void>> pay(int id, Json body, {required String idempotencyKey}) =>
      _record('pay', body, idempotencyKey);

  @override
  Future<ApiResult<void>> freeze(int id, Json body) => _record('freeze', body);

  @override
  Future<ApiResult<void>> unfreeze(int id) => _record('unfreeze', const {});

  @override
  Future<ApiResult<void>> cancel(int id, Json body, {required String idempotencyKey}) =>
      _record('cancel', body, idempotencyKey);

  @override
  Future<ApiResult<MembershipQuote>> renewQuote({required int planId, required int previousId}) async =>
      ApiSuccess(MembershipQuote.fromJson(quoteJson));

  @override
  Future<ApiResult<int>> renew(int id, Json body, {required String idempotencyKey}) async {
    sent.add((action: 'renew', body: body, key: idempotencyKey));
    return renewResult;
  }

  @override
  Future<ApiResult<void>> consumeSession(int id, Json body, {required String idempotencyKey}) =>
      _record('session', body, idempotencyKey);

  @override
  Future<ApiResult<FileBlob>> invoice(int id) async {
    files.add('invoice $id');
    return const ApiFailure(Failure(type: FailureType.network, message: 'تعذّر الاتصال.'));
  }

  @override
  Future<ApiResult<FileBlob>> receipt(int transactionId) async {
    files.add('receipt $transactionId');
    return const ApiFailure(Failure(type: FailureType.network, message: 'تعذّر الاتصال.'));
  }
}
