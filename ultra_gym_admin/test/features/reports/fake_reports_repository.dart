import 'package:ultra_gym_admin/core/error/failure.dart';
import 'package:ultra_gym_admin/core/networking/api_client.dart';
import 'package:ultra_gym_admin/core/networking/api_result.dart';
import 'package:ultra_gym_admin/core/utils/json_x.dart';
import 'package:ultra_gym_admin/features/reports/data/repo/reports_repository.dart';
import 'package:ultra_gym_admin/features/reports/domain/models/reports_models.dart';

/// قائمة `GET reports` كما ردّها الخادم للمالك.
List<Json> catalogRows({bool branchesAvailable = true}) => [
  {'key': 'financial_summary', 'label': 'الأرباح والخسائر', 'is_financial': true, 'available': true, 'uses_period': true},
  {'key': 'daily_cash', 'label': 'الصندوق اليومي', 'is_financial': true, 'available': true, 'uses_period': true},
  {'key': 'attendance', 'label': 'الحضور', 'is_financial': false, 'available': true, 'uses_period': true},
  {'key': 'debts', 'label': 'الديون', 'is_financial': false, 'available': true, 'uses_period': false},
  {'key': 'branches', 'label': 'مقارنة الفروع', 'is_financial': true, 'available': branchesAvailable, 'uses_period': true},
];

/// تقارير بشكل `ClubReports::build` (من ردود حقيقية).
Json reportJson(String key, {int page = 1, int lastPage = 1}) => switch (key) {
  'daily_cash' => {
    'report': 'daily_cash',
    'title': 'الصندوق اليومي',
    'subtitle': 'من 2026-11-01 إلى 2026-11-10 · كل الفروع',
    'from': '2026-11-01',
    'to': '2026-11-10',
    'summary': {'الداخل': r'$191.50', 'الخارج': r'$293.62', 'الصافي': r'-$102.12', 'أيام العمل': 2},
    'data': {
      'days': [
        {'date': '2026-11-07', 'transactions': 3, 'in_usd': 33, 'out_usd': 34.62, 'net_usd': -1.62},
        {'date': '2026-11-08', 'transactions': 5, 'in_usd': 158.5, 'out_usd': 0, 'net_usd': 158.5},
      ],
    },
    'sections': [
      {
        'title': 'الأيام',
        'columns': ['اليوم', 'الحركات', 'داخل', 'خارج', 'الصافي', 'صافي نقد \$', 'صافي نقد ل.س'],
        'numeric': [1, 2, 3, 4, 5, 6],
        'rows': [
          ['2026-11-07', 3, r'$33.00', r'$34.62', r'-$1.62', '33.00', '-450,000'],
          ['2026-11-08', 5, r'$158.50', r'$0.00', r'$158.50', '158.50', '0'],
        ],
      },
    ],
  },
  'debts' => {
    'report': 'debts',
    'title': 'الديون',
    'subtitle': 'حتى 2026-11-10 · كل الفروع',
    'from': '2026-11-01',
    'to': '2026-11-10',
    'summary': {'إجمالي الديون': r'$20.00', 'بالليرة': '290,000 ل.س', 'الاشتراكات': 1, 'اللاعبون': 1},
    'data': {
      'total_due_usd': 20,
      'items': const [],
      'pagination': {'current_page': page, 'per_page': 50, 'total': 60, 'last_page': lastPage, 'from': 1, 'to': 50},
    },
    'sections': [
      {
        'title': 'الديون',
        'columns': ['اللاعب', 'الهاتف', 'الخطة', 'الصافي', 'المدفوع', 'المتبقي', 'ينتهي'],
        'numeric': [3, 4, 5],
        'rows': [
          ['عمر الخطيب', '+963944100001', 'تدريب خاص شهري', r'$100.00', r'$80.00', r'$20.00', '2026-11-30'],
        ],
      },
    ],
  },
  _ => {
    'report': 'financial_summary',
    'title': 'الأرباح والخسائر',
    'subtitle': 'من 2026-11-01 إلى 2026-11-10 · كل الفروع',
    'from': '2026-11-01',
    'to': '2026-11-10',
    'summary': {'إيرادات الاشتراكات': r'$165.50', 'صافي الربح': r'-$77.12'},
    'data': {'net_profit_usd': -77.12},
    'sections': [
      {
        'title': 'المصاريف حسب التصنيف',
        'columns': ['التصنيف', 'بالدولار'],
        'numeric': [1],
        'rows': [
          ['كهرباء ومولدة', r'$34.62'],
        ],
      },
      {'title': 'الإيرادات الأخرى حسب التصنيف', 'columns': ['التصنيف', 'بالدولار'], 'numeric': [1], 'rows': const []},
    ],
  },
};

class FakeReportsRepository implements ReportsRepository {
  ApiResult<ReportCatalog> catalogResult = ApiSuccess(
    ReportCatalog(reports: [for (final j in catalogRows()) ReportInfo.fromJson(j)], formats: const ['json', 'pdf', 'xlsx']),
  );
  ApiResult<ReportResult>? reportResult;

  final queries = <ReportQuery>[];
  final exports = <({ReportQuery query, String format})>[];

  @override
  Future<ApiResult<ReportCatalog>> catalog() async => catalogResult;

  @override
  Future<ApiResult<ReportResult>> report(ReportQuery query) async {
    queries.add(query);
    return reportResult ?? ApiSuccess(ReportResult.fromJson(reportJson(query.key, page: query.page, lastPage: 2)));
  }

  /// بلا ملف حقيقي بالاختبار: الفشل يظهر برسالة فقط.
  @override
  Future<ApiResult<FileBlob>> export(ReportQuery query, String format) async {
    exports.add((query: query, format: format));
    return const ApiFailure(Failure(type: FailureType.network, message: 'تعذّر التنزيل.'));
  }
}
