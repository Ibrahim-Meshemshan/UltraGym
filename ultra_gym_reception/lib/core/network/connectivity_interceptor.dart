import 'package:dio/dio.dart';

import '../error/error_handler.dart';
import '../error/failure.dart';
import 'connection_cubit.dart';

/// الكتابة تحتاج اتصالاً: يرفضها فوراً دون اتصال برسالة واضحة، وأي فشل شبكة يطلب فحصاً فورياً.
class ConnectivityInterceptor extends Interceptor {
  ConnectivityInterceptor(this._connection);

  final ConnectionCubit _connection;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.method != 'GET' && _connection.isOffline) {
      return handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: Failure(type: FailureType.offline, message: ErrorHandler.defaultMessage(FailureType.offline)),
        ),
      );
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response == null && err.type != DioExceptionType.cancel) _connection.recheck();
    handler.next(err);
  }
}
