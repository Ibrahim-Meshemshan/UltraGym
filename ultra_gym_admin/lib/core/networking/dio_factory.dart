import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';

/// Dio الوحيد بالتطبيق. ترتيب الـ interceptors يحدده `injection.dart`:
/// موبايل: الكاش ← فحص الاتصال ← التوكن. الداشبورد: التوكن فقط.
abstract final class DioFactory {
  static Dio create({List<Interceptor> interceptors = const []}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        headers: {'Accept': 'application/json'},
        listFormat: ListFormat.multiCompatible,
        responseType: ResponseType.json,
      ),
    );
    dio.interceptors.addAll([...interceptors, if (kDebugMode) const _ApiLog()]);
    return dio;
  }
}

/// سطر واحد لكل طلب بالـ debug: `[API] GET /path -> 200`.
class _ApiLog extends Interceptor {
  const _ApiLog();

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    final o = response.requestOptions;
    final cached = response.extra['fromCache'] == true ? ' (cache)' : '';
    debugPrint('[API] ${o.method} ${o.path} -> ${response.statusCode}$cached');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final o = err.requestOptions;
    debugPrint('[API] ${o.method} ${o.path} -> ${err.response?.statusCode ?? err.type.name}');
    handler.next(err);
  }
}
