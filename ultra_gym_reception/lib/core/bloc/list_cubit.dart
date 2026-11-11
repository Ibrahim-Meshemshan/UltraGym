import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../error/failure.dart';
import '../networking/api_result.dart';
import '../networking/list_query.dart';
import '../networking/paged.dart';
import 'slice.dart';

typedef PageFetcher<T> = Future<ApiResult<Paged<T>>> Function(ListQuery query);

/// حالة قائمة موبايل بتمرير مقسّم.
class ListState<T> extends Equatable {
  ListState({Slice<Paged<T>>? slice, this.query = const ListQuery(), this.loadingMore = false, this.moreFailure})
      : slice = slice ?? Slice<Paged<T>>();

  final Slice<Paged<T>> slice;
  final ListQuery query;
  final bool loadingMore;

  /// فشل تحميل الصفحة التالية فقط (الصفحات السابقة تبقى).
  final Failure? moreFailure;

  bool get canLoadMore => (slice.data?.hasMore ?? false) && !loadingMore;

  ListState<T> copyWith({Slice<Paged<T>>? slice, ListQuery? query, bool? loadingMore, Failure? Function()? moreFailure}) =>
      ListState(
        slice: slice ?? this.slice,
        query: query ?? this.query,
        loadingMore: loadingMore ?? this.loadingMore,
        moreFailure: moreFailure == null ? this.moreFailure : moreFailure(),
      );

  @override
  List<Object?> get props => [slice, query, loadingMore, moreFailure];
}

/// قائمة موبايل: الصفحة الأولى، `more()` "عرض المزيد"، `filter()` و `search()` يعيدان من الأول.
class ListCubit<T> extends Cubit<ListState<T>> {
  ListCubit(this._fetch, {ListQuery query = const ListQuery()}) : super(ListState<T>(query: query));

  final PageFetcher<T> _fetch;

  Future<void> load() async {
    final q = state.query.withPage(1);
    emit(state.copyWith(slice: state.slice.toLoading(), query: q, loadingMore: false, moreFailure: () => null));
    final r = await _fetch(q);
    if (isClosed) return;
    emit(state.copyWith(slice: state.slice.fromResult(r)));
  }

  /// تحديث صامت للصفحة الأولى (السحب للتحديث).
  Future<void> refresh() async {
    final r = await _fetch(state.query.withPage(1));
    if (isClosed) return;
    switch (r) {
      case ApiSuccess<Paged<T>>(:final data, :final cachedAt):
        emit(state.copyWith(slice: state.slice.toSuccess(data, cachedAt: cachedAt), moreFailure: () => null));
      case ApiFailure<Paged<T>>(:final failure):
        if (!state.slice.hasData) emit(state.copyWith(slice: state.slice.toFailure(failure)));
    }
  }

  Future<void> more() async {
    final current = state.slice.data;
    if (current == null || !state.canLoadMore) return;
    emit(state.copyWith(loadingMore: true, moreFailure: () => null));
    final r = await _fetch(state.query.withPage(current.pagination.currentPage + 1));
    if (isClosed) return;
    switch (r) {
      case ApiSuccess<Paged<T>>(:final data):
        emit(state.copyWith(slice: state.slice.toSuccess(current.append(data)), loadingMore: false));
      case ApiFailure<Paged<T>>(:final failure):
        emit(state.copyWith(loadingMore: false, moreFailure: () => failure));
    }
  }

  Future<void> filter(String key, Object? value) => query(state.query.withFilter(key, value));

  Future<void> search(String text) => query(state.query.withSearch(text));

  Future<void> clearFilters() => query(state.query.cleared());

  Future<void> query(ListQuery next) {
    emit(state.copyWith(query: next));
    return load();
  }

  /// تعديل محلي على العناصر (بعد حفظ ناجح مثلاً).
  void patchItems(List<T> Function(List<T> items) transform) =>
      emit(state.copyWith(slice: state.slice.mapData((p) => p.copyWithItems(transform(p.items)))));
}
