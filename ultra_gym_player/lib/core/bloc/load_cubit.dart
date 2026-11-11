import 'package:flutter_bloc/flutter_bloc.dart';

import '../networking/api_result.dart';
import 'slice.dart';

/// قسم يقرأ قيمة واحدة: `load()` بهياكل، `refresh()` صامت، `patch()` تعديل محلي بعد الحفظ.
class LoadCubit<T> extends Cubit<Slice<T>> {
  LoadCubit(this._fetch) : super(Slice<T>());

  final Future<ApiResult<T>> Function() _fetch;

  Future<void> load() async {
    emit(state.toLoading());
    final r = await _fetch();
    if (isClosed) return;
    emit(state.fromResult(r));
  }

  /// تحديث صامت: لا هياكل، والخطأ مع وجود بيانات لا يمحوها.
  Future<void> refresh() async {
    final r = await _fetch();
    if (isClosed) return;
    switch (r) {
      case ApiSuccess<T>(:final data, :final cachedAt):
        emit(state.toSuccess(data, cachedAt: cachedAt));
      case ApiFailure<T>(:final failure):
        emit(state.hasData ? state : state.toFailure(failure));
    }
  }

  void patch(T Function(T data) transform) => emit(state.mapData(transform));
}
