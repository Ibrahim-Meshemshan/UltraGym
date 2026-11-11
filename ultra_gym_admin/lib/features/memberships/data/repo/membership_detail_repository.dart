import '../../../../core/core.dart';
import '../../domain/models/membership_detail_models.dart';

/// صفحة الاشتراك وعملياته. المال (السداد، التجديد، الاسترجاع، الجلسة) يُرسل بـ `Idempotency-Key`.
/// `branch_id` = صندوق الفرع الذي يقبض أو يصرف (null = فرع واحد أو الرئيسي للمالك، يقرره الخادم).
abstract interface class MembershipDetailRepository {
  Future<ApiResult<MembershipDetail>> detail(int id);

  /// زيارات العضو خلال فترة الاشتراك (الحضور بلا فلتر اشتراك بالخادم).
  Future<ApiResult<Paged<AttendanceEntry>>> attendance(
    ListQuery query, {
    required int playerId,
    DateTime? from,
    DateTime? to,
  });

  /// سداد دين: `{payments: [{currency, amount}], branch_id?}` بأي مبلغ ≤ الدين.
  Future<ApiResult<void>> pay(int id, Json body, {required String idempotencyKey});

  /// تجميد `{days, reason?}`.
  Future<ApiResult<void>> freeze(int id, Json body);

  Future<ApiResult<void>> unfreeze(int id);

  /// إلغاء للمالك `{reason, refunds?: [...], branch_id?}`.
  Future<ApiResult<void>> cancel(int id, Json body, {required String idempotencyKey});

  /// تسعير التجديد بنفس الخطة.
  Future<ApiResult<MembershipQuote>> renewQuote({required int planId, required int previousId});

  /// تجديد `{payments?, branch_id?, trainer_id?}` ← معرّف الاشتراك الجديد.
  Future<ApiResult<int>> renew(int id, Json body, {required String idempotencyKey});

  /// استهلاك جلسة يدوياً `{note?, branch_id?}`.
  Future<ApiResult<void>> consumeSession(int id, Json body, {required String idempotencyKey});

  Future<ApiResult<FileBlob>> invoice(int id);

  Future<ApiResult<FileBlob>> receipt(int transactionId);
}
