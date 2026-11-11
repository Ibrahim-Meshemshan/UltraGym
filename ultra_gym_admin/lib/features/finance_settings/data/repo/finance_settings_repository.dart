import '../../../../core/core.dart';
import '../../../transactions/domain/models/transaction_models.dart';
import '../../domain/models/finance_settings_models.dart';

/// الإعدادات المالية (`/club-admin/finance`): سعر الصرف وسجله، وتصنيفات المصروف والإيراد.
/// القراءة للمالك والاستقبال، والتعديل للمالك فقط.
abstract interface class FinanceSettingsRepository {
  /// السجل (الأحدث أولاً) والسعر الحالي بـ `meta.current`.
  Future<ApiResult<Paged<ExchangeRateEntry>>> rates(ListQuery query);

  /// `{syp_per_usd, note?}`: يُطبَّق على الحركات الجديدة فقط.
  Future<ApiResult<void>> setRate(Json body, {required String idempotencyKey});

  /// كل التصنيفات (الفعّالة والمتوقفة) مع عدد حركات كل منها.
  Future<ApiResult<List<FinanceCategory>>> categories();

  /// `{kind: expense|income, name}`.
  Future<ApiResult<FinanceCategory>> addCategory(Json body, {required String idempotencyKey});

  /// `{name?}` أو `{status: active|inactive}`.
  Future<ApiResult<FinanceCategory>> updateCategory(int id, Json body);

  /// حذف تصنيف لم يُستعمل؛ المستعمل يرفضه الخادم بـ `CONFLICT` ("أوقفه بدل حذفه").
  Future<ApiResult<void>> deleteCategory(int id);
}
