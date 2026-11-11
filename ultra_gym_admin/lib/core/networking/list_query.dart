import 'package:equatable/equatable.dart';

import '../utils/json_x.dart';

enum SortDir { asc, desc }

/// معاملات أي قائمة: الصفحة، البحث، الترتيب، والفلاتر. أي تغيير غير الصفحة يعيد للصفحة الأولى.
class ListQuery extends Equatable {
  const ListQuery({
    this.page = 1,
    this.perPage = 15,
    this.search = '',
    this.sortBy,
    this.sortDir,
    this.filters = const {},
  });

  final int page, perPage;
  final String search;
  final String? sortBy;
  final SortDir? sortDir;
  final Map<String, Object> filters;

  bool get hasFilters => search.trim().isNotEmpty || filters.isNotEmpty;

  Object? filter(String key) => filters[key];

  ListQuery withPage(int value) => _copy(page: value);
  ListQuery withPerPage(int value) => _copy(perPage: value.clamp(1, 100), page: 1);
  ListQuery withSearch(String value) => _copy(search: value, page: 1);
  ListQuery withSort(String by, SortDir dir) => _copy(sortBy: by, sortDir: dir, page: 1);

  /// قيمة فارغة (null أو نص فارغ أو قائمة فارغة) تزيل الفلتر.
  ListQuery withFilter(String key, Object? value) {
    final next = {...filters};
    final empty = value == null || (value is String && value.isEmpty) || (value is Iterable && value.isEmpty);
    empty ? next.remove(key) : next[key] = value;
    return _copy(filters: next, page: 1);
  }

  /// مسح البحث والفلاتر مع إبقاء حجم الصفحة والترتيب.
  ListQuery cleared() => ListQuery(perPage: perPage, sortBy: sortBy, sortDir: sortDir);

  /// معاملات الطلب كما يتوقعها الخادم.
  Json toParams() => {
    'page': page,
    'per_page': perPage,
    if (search.trim().isNotEmpty) 'search': search.trim(),
    if (sortBy != null) 'sort_by': sortBy,
    if (sortDir != null) 'sort_dir': sortDir!.name,
    for (final e in filters.entries) e.key: _param(e.value),
  };

  static Object _param(Object v) => switch (v) {
    final DateTime d => '${d.year.toString().padLeft(4, '0')}-${_two(d.month)}-${_two(d.day)}',
    final bool b => b ? 1 : 0,
    final Iterable<Object?> list => list.map((e) => e.toString()).toList(),
    _ => v,
  };

  static String _two(int n) => n.toString().padLeft(2, '0');

  ListQuery _copy({
    int? page,
    int? perPage,
    String? search,
    String? sortBy,
    SortDir? sortDir,
    Map<String, Object>? filters,
  }) => ListQuery(
    page: page ?? this.page,
    perPage: perPage ?? this.perPage,
    search: search ?? this.search,
    sortBy: sortBy ?? this.sortBy,
    sortDir: sortDir ?? this.sortDir,
    filters: filters ?? this.filters,
  );

  @override
  List<Object?> get props => [page, perPage, search, sortBy, sortDir, filters];
}
