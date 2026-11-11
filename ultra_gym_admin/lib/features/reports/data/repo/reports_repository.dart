import '../../../../core/core.dart';
import '../../domain/models/reports_models.dart';

/// التقارير: القائمة المتاحة وصيغها، والتقرير JSON للعرض، والملف (PDF / Excel) للتصدير.
abstract interface class ReportsRepository {
  /// `GET club-admin/reports` + `meta.formats`.
  Future<ApiResult<ReportCatalog>> catalog();

  /// `GET club-admin/reports/{key}?from&to&branch_id&page&per_page`.
  Future<ApiResult<ReportResult>> report(ReportQuery query);

  /// `GET club-admin/reports/{key}?format=pdf|xlsx&…` (ميزة `reports_export`).
  Future<ApiResult<FileBlob>> export(ReportQuery query, String format);
}
