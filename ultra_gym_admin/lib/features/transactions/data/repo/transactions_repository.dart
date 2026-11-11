import '../../../../core/core.dart';
import '../../domain/models/transaction_models.dart';

/// دفتر الحركات (`/club-admin/transactions`) وتصنيفات المصروف والإيراد.
abstract interface class TransactionsRepository {
  /// الدفتر بفلاتره (`meta.totals` و `meta.period`). بلا فترة ولا بحث = آخر 31 يوماً.
  Future<ApiResult<Paged<LedgerEntry>>> list(ListQuery query, {int? branchId});

  /// حركة واحدة مع إيصال عكسها وما يعادلها بالليرة.
  Future<ApiResult<LedgerEntry>> detail(int id);

  /// التصنيفات الفعّالة بنوعيها (قائمة "التصنيف" بنافذة التسجيل).
  Future<ApiResult<List<FinanceCategory>>> categories();

  /// `{type: income|expense, currency, amount, category_id, description, branch_id?}` بصندوق الفرع المفتوح.
  Future<ApiResult<LedgerEntry>> record(Json body, {required String idempotencyKey});

  /// عكس (للمالك) بسبب إلزامي: حركة معاكسة بإيصال جديد بالوردية المفتوحة.
  Future<ApiResult<LedgerReversal>> reverse(int id, String reason, {required String idempotencyKey});

  /// إيصال الحركة (PDF أو HTML للطباعة).
  Future<ApiResult<FileBlob>> receipt(int id);
}
