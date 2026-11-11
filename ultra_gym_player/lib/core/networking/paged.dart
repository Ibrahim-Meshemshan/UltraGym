import 'package:equatable/equatable.dart';

import '../utils/json_x.dart';

/// تقسيم الصفحات من `meta.pagination`.
class Pagination extends Equatable {
  const Pagination({this.currentPage = 1, this.perPage = 15, this.total = 0, this.lastPage = 1, this.from, this.to});

  factory Pagination.fromJson(Json json) => Pagination(
        currentPage: json.intv('current_page', 1),
        perPage: json.intv('per_page', 15),
        total: json.intv('total'),
        lastPage: json.intv('last_page', 1),
        from: json.intOrNull('from'),
        to: json.intOrNull('to'),
      );

  final int currentPage, perPage, total, lastPage;
  final int? from, to;

  bool get hasMore => currentPage < lastPage;

  @override
  List<Object?> get props => [currentPage, perPage, total, lastPage, from, to];
}

/// صفحة من قائمة: العناصر + التقسيم + المجاميع (`meta.summary`) + باقي `meta`.
class Paged<T> extends Equatable {
  const Paged({this.items = const [], this.pagination = const Pagination(), this.summary = const {}, this.meta = const {}});

  final List<T> items;
  final Pagination pagination;
  final Json summary;
  final Json meta;

  bool get isEmpty => items.isEmpty;
  bool get hasMore => pagination.hasMore;

  /// دمج الصفحة التالية ("عرض المزيد").
  Paged<T> append(Paged<T> next) =>
      Paged(items: [...items, ...next.items], pagination: next.pagination, summary: next.summary, meta: next.meta);

  Paged<T> copyWithItems(List<T> items) => Paged(items: items, pagination: pagination, summary: summary, meta: meta);

  @override
  List<Object?> get props => [items, pagination, summary, meta];
}
