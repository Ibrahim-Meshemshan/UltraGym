import '../error/failure.dart';
import '../utils/json_x.dart';

/// نتيجة أي طلب: نجاح ببيانات، أو فشل بـ `Failure`. لا استثناء يصل للواجهة.
sealed class ApiResult<T> {
  const ApiResult();

  T? get dataOrNull => switch (this) {
        ApiSuccess<T>(:final data) => data,
        ApiFailure<T>() => null,
      };

  Failure? get failureOrNull => switch (this) {
        ApiSuccess<T>() => null,
        ApiFailure<T>(:final failure) => failure,
      };

  bool get isSuccess => this is ApiSuccess<T>;

  R when<R>({required R Function(T data) success, required R Function(Failure failure) failure}) => switch (this) {
        ApiSuccess<T>(:final data) => success(data),
        ApiFailure<T>(failure: final f) => failure(f),
      };

  ApiResult<R> map<R>(R Function(T data) transform) => switch (this) {
        final ApiSuccess<T> s =>
          ApiSuccess<R>(transform(s.data), message: s.message, meta: s.meta, cachedAt: s.cachedAt),
        ApiFailure<T>(:final failure) => ApiFailure<R>(failure),
      };
}

final class ApiSuccess<T> extends ApiResult<T> {
  const ApiSuccess(this.data, {this.message, this.meta = const {}, this.cachedAt});

  final T data;

  /// رسالة الخادم العربية (مثل "تم تسجيل الدفعة") لعرضها بـ AppSnackbar.
  final String? message;
  final Json meta;

  /// غير فارغ إن جاء الرد من الكاش دون اتصال: "آخر تحديث قبل...".
  final DateTime? cachedAt;

  bool get fromCache => cachedAt != null;
}

final class ApiFailure<T> extends ApiResult<T> {
  const ApiFailure(this.failure);

  final Failure failure;
}
