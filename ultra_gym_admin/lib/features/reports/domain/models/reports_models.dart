import '../../../../core/core.dart';

/// تقرير بقائمة `GET reports` (الخادم يخفي المالية عمّن لا يرى المالية).
class ReportInfo extends Equatable {
  const ReportInfo({
    required this.key,
    required this.label,
    required this.isFinancial,
    required this.available,
    required this.usesPeriod,
  });

  factory ReportInfo.fromJson(Json json) => ReportInfo(
    key: json.str('key'),
    label: json.str('label'),
    isFinancial: json.flag('is_financial'),
    available: json.flag('available', true),
    usesPeriod: json.flag('uses_period', true),
  );

  final String key, label;
  final bool isFinancial, available, usesPeriod;

  /// مقارنة الفروع والمدربون للنادي كله (الخادم يتجاهل الفرع).
  bool get usesBranch => key != 'branches' && key != 'trainers';

  @override
  List<Object?> get props => [key, label, isFinancial, available, usesPeriod];
}

/// التقارير المتاحة + الصيغ (`meta.formats`: `json` وحدها = التصدير غير متاح بالباقة).
class ReportCatalog extends Equatable {
  const ReportCatalog({required this.reports, required this.formats});

  final List<ReportInfo> reports;
  final List<String> formats;

  bool get canExport => formats.contains('pdf') || formats.contains('xlsx');

  @override
  List<Object?> get props => [reports, formats];
}

/// جدول بالتقرير: الأعمدة والصفوف كما هي، و `numeric` أرقام الأعمدة الرقمية (تُحاذى للطرف و LTR).
class ReportSection extends Equatable {
  const ReportSection({required this.title, required this.columns, required this.numeric, required this.rows});

  factory ReportSection.fromJson(Json json) => ReportSection(
    title: json.str('title'),
    columns: json.strList('columns'),
    numeric: json.intList('numeric').toSet(),
    rows: [
      for (final r in json['rows'] is List ? json['rows'] as List : const [])
        if (r is List) List<Object?>.of(r),
    ],
  );

  final String title;
  final List<String> columns;
  final Set<int> numeric;
  final List<List<Object?>> rows;

  @override
  List<Object?> get props => [title, columns, numeric, rows];
}

/// تقرير مبني (`GET reports/{key}`): العنوان والفترة، الملخص (نص جاهز لكل بطاقة بترتيب الخادم)، الجداول،
/// و `data` للرسوم، و `pagination` للتقارير المقسّمة (الديون والمنتهية).
class ReportResult extends Equatable {
  const ReportResult({
    required this.key,
    required this.title,
    required this.subtitle,
    this.from,
    this.to,
    required this.summary,
    required this.sections,
    required this.data,
    this.pagination,
  });

  factory ReportResult.fromJson(Json json) {
    final data = json.obj('data');
    final pag = data.objOrNull('pagination');
    return ReportResult(
      key: json.str('report'),
      title: json.str('title'),
      subtitle: json.str('subtitle'),
      from: json.day('from'),
      to: json.day('to'),
      summary: [for (final e in json.obj('summary').entries) (label: e.key, value: '${e.value ?? '—'}')],
      sections: [for (final s in json['sections'] is List ? json['sections'] as List : const []) ReportSection.fromJson(asJson(s))],
      data: data,
      pagination: pag == null ? null : Pagination.fromJson(pag),
    );
  }

  final String key, title, subtitle;
  final DateTime? from, to;
  final List<({String label, String value})> summary;
  final List<ReportSection> sections;
  final Json data;
  final Pagination? pagination;

  @override
  List<Object?> get props => [key, title, subtitle, from, to, summary, sections, data, pagination];
}

/// ما يُطلب: التقرير، الفترة (null = الخادم: من أول الشهر حتى اليوم)، الفرع، والصفحة.
class ReportQuery extends Equatable {
  const ReportQuery({required this.key, this.from, this.to, this.branchId, this.page = 1});

  final String key;
  final DateTime? from, to;
  final int? branchId;
  final int page;

  Json params({String? format}) => {
    'from': ?(from == null ? null : Formatters.date(from)),
    'to': ?(to == null ? null : Formatters.date(to)),
    'branch_id': ?branchId,
    if (format == null) ...{'page': page, 'per_page': 50} else 'format': format,
  };

  ReportQuery copyWith({String? key, (DateTime?, DateTime?)? period, (int?,)? branch, int? page}) => ReportQuery(
    key: key ?? this.key,
    from: period == null ? from : period.$1,
    to: period == null ? to : period.$2,
    branchId: branch == null ? branchId : branch.$1,
    page: page ?? 1,
  );

  @override
  List<Object?> get props => [key, from, to, branchId, page];
}

/// نصوص التقارير.
abstract final class ReportTexts {
  /// سطر الوصف تحت اسم التقرير (`Reports.html`).
  static String description(String key) => switch (key) {
    'financial_summary' => 'الإيراد والمصروف وحركة النقد',
    'daily_cash' => 'داخل وخارج وصافي كل يوم',
    'memberships' => 'حسب الخطة: عدد وتجديد وخصم',
    'attendance' => 'حسب اليوم وحسب الساعة',
    'debts' => 'كل اشتراك عليه مبلغ متبقٍّ',
    'expiring' => 'للمتابعة والتجديد',
    'trainers' => 'العملاء والعمولة لكل مدرب',
    'branches' => 'الإيراد والاشتراكات والحضور',
    _ => '',
  };

  /// رسم التقرير من `data` (إن كان له رسم): العنوان والقيم بترتيب الأيام.
  static ({String title, List<({String label, num value})> bars})? chart(ReportResult r) {
    List<({String label, num value})> days(String key, String field) => [
      for (final d in r.data[key] is List ? r.data[key] as List : const [])
        if (d is Map) (label: _dayLabel('${d['date'] ?? ''}'), value: asJson(d).dbl(field)),
    ];
    return switch (r.key) {
      'daily_cash' => (title: 'الصافي اليومي', bars: days('days', 'net_usd')),
      'attendance' => (title: 'الدخول المقبول حسب اليوم', bars: days('by_day', 'accepted')),
      _ => null,
    };
  }

  /// `2026-11-07` ← `11-07`.
  static String _dayLabel(String date) => date.length >= 10 ? date.substring(5, 10) : date;
}
