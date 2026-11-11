import '../../../../core/core.dart';
import '../../domain/models/reports_models.dart';
import '../repo/reports_repository.dart';

class ReportsRemoteDataSource implements ReportsRepository {
  ReportsRemoteDataSource(this._api);

  final ApiClient _api;

  static const _base = '/club-admin/reports';

  @override
  Future<ApiResult<ReportCatalog>> catalog() async =>
      (await _api.getWithMeta(_base, parse: Parse.list(ReportInfo.fromJson))).map(
        (r) => ReportCatalog(reports: r.$1, formats: r.$2.strList('formats')),
      );

  @override
  Future<ApiResult<ReportResult>> report(ReportQuery query) =>
      _api.get('$_base/${query.key}', query: query.params(), parse: Parse.object(ReportResult.fromJson));

  @override
  Future<ApiResult<FileBlob>> export(ReportQuery query, String format) =>
      _api.getBytes('$_base/${query.key}', query: query.params(format: format));
}
