import '../../../../core/core.dart';
import '../../domain/models/cash_session_models.dart';

/// ورديات الصندوق (`/club-admin/cash-sessions`): وردية واحدة مفتوحة لكل فرع.
abstract interface class CashSessionsRepository {
  /// صندوق الفرع الآن: الوردية المفتوحة (بأرصدتها الحية) أو null مع الرصيد المقترح.
  Future<ApiResult<CashBox>> current({int? branchId});

  /// `status` ثابت مع الطلب (السابقة = `closed`) فلا يمسحه "مسح الفلاتر".
  Future<ApiResult<Paged<CashSession>>> list(ListQuery query, {int? branchId, String? status});

  /// التفاصيل مع "حسب النوع".
  Future<ApiResult<CashSession>> detail(int id);

  /// `{branch_id?, opening_usd, opening_syp, notes?}`.
  Future<ApiResult<CashSession>> open(Json body, {required String idempotencyKey});

  /// `{closing_usd, closing_syp, notes?}`: الجرد الفعلي بكل عملة.
  Future<ApiResult<CashSession>> close(int id, Json body, {required String idempotencyKey});

  /// تقرير الوردية (PDF أو HTML للطباعة).
  Future<ApiResult<FileBlob>> report(int id);
}
