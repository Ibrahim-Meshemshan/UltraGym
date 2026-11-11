import '../../../../core/core.dart';
import '../../data/repo/reports_repository.dart';
import '../../domain/models/reports_models.dart';

/// التقارير المتاحة للمستخدم وصيغ التصدير.
class ReportCatalogCubit extends LoadCubit<ReportCatalog> {
  ReportCatalogCubit(ReportsRepository repo) : super(repo.catalog);
}

/// تقرير واحد بفترته وفرعه وصفحته (Cubit جديد لكل طلب مختلف).
class ReportCubit extends LoadCubit<ReportResult> {
  ReportCubit(ReportsRepository repo, ReportQuery query) : super(() => repo.report(query));
}
