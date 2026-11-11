import 'package:equatable/equatable.dart';

import '../error/failure.dart';
import '../networking/api_result.dart';

enum LoadStatus { initial, loading, success, failure }

/// وحدة الحالة: بيانات قسم واحد مع حالة تحميله. البيانات السابقة تبقى أثناء إعادة التحميل والخطأ.
class Slice<T> extends Equatable {
  const Slice({this.status = LoadStatus.initial, this.data, this.failure, this.cachedAt});

  final LoadStatus status;
  final T? data;
  final Failure? failure;

  /// غير فارغ إن كانت البيانات من الكاش دون اتصال.
  final DateTime? cachedAt;

  bool get isInitial => status == LoadStatus.initial;
  bool get isLoading => status == LoadStatus.loading;
  bool get isSuccess => status == LoadStatus.success;
  bool get isFailure => status == LoadStatus.failure;
  bool get hasData => data != null;

  /// أول تحميل: هياكل رمادية.
  bool get isFirstLoad => (isLoading || isInitial) && data == null;

  /// إعادة تحميل: المحتوى يبقى ظاهراً مع شريط تقدّم رفيع.
  bool get isRefreshing => isLoading && data != null;

  Slice<T> toLoading() => Slice(status: LoadStatus.loading, data: data, cachedAt: cachedAt);

  Slice<T> toSuccess(T value, {DateTime? cachedAt}) => Slice(status: LoadStatus.success, data: value, cachedAt: cachedAt);

  Slice<T> toFailure(Failure f) => Slice(status: LoadStatus.failure, data: data, failure: f, cachedAt: cachedAt);

  Slice<T> fromResult(ApiResult<T> result) => switch (result) {
        ApiSuccess<T>(:final data, :final cachedAt) => toSuccess(data, cachedAt: cachedAt),
        ApiFailure<T>(:final failure) => toFailure(failure),
      };

  /// تعديل محلي على البيانات (بعد حفظ ناجح مثلاً) دون طلب جديد.
  Slice<T> mapData(T Function(T data) transform) {
    final d = data;
    return d == null ? this : Slice(status: status, data: transform(d), failure: failure, cachedAt: cachedAt);
  }

  @override
  List<Object?> get props => [status, data, failure, cachedAt];
}
