import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../networking/auth_interceptor.dart';
import '../storage/cache_store.dart';
import '../storage/session_storage.dart';
import 'connection_cubit.dart';

/// كاش القراءة على مستوى HTTP: كل شاشة تعمل دون اتصال تلقائياً دون كود بالميزة.
/// 1) يخزّن GET بـ JSON فقط (لا `extra[skip]` ولا `as=base64`). 2) المفتاح FNV-1a لـ `token | uri`.
/// 3) متصلاً: `If-None-Match` بالـ ETag، و 304 = النسخة المحفوظة. 4) دون اتصال: آخر نسخة كرد 200
/// مع `extra[fromCache]` و `extra[cachedAt]`. الكتابة يرفضها `ConnectivityInterceptor`.
class OfflineCacheInterceptor extends Interceptor {
  OfflineCacheInterceptor(this._store, this._session, this._connection);

  final CacheStore _store;
  final SessionStorage _session;
  final ConnectionCubit _connection;

  static const _entryKey = '_cacheEntry';
  static const _keyKey = '_cacheKey';

  bool _cacheable(RequestOptions o) =>
      o.method == 'GET' &&
      o.extra[RequestFlags.skipCache] != true &&
      o.responseType == ResponseType.json &&
      o.queryParameters['as'] != 'base64';

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (!_cacheable(options)) return handler.next(options);
    final key = fnv1a('${_session.token ?? ''}|${options.uri}');
    final entry = await _store.read(key);
    options.extra[_keyKey] = key;
    if (entry != null) {
      if (_connection.isOffline) return handler.resolve(_cached(options, entry, offline: true));
      options.extra[_entryKey] = entry;
      if (entry.etag != null) options.headers['If-None-Match'] = entry.etag;
      options.connectTimeout = AppConfig.cachedConnectTimeout;
    }
    handler.next(options);
  }

  @override
  Future<void> onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) async {
    final key = response.requestOptions.extra[_keyKey] as String?;
    if (key != null && response.statusCode == 200 && response.data is Map) {
      await _store.write(key, CacheEntry(data: response.data, etag: response.headers.value('etag'), savedAt: DateTime.now().toUtc()));
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final entry = err.requestOptions.extra[_entryKey] as CacheEntry?;
    if (entry != null) {
      if (err.response?.statusCode == 304) return handler.resolve(_cached(err.requestOptions, entry, offline: false));
      final network = err.response == null && err.type != DioExceptionType.cancel;
      if (network) {
        _connection.recheck();
        return handler.resolve(_cached(err.requestOptions, entry, offline: true));
      }
    }
    handler.next(err);
  }

  Response<dynamic> _cached(RequestOptions o, CacheEntry entry, {required bool offline}) => Response<dynamic>(
        requestOptions: o,
        statusCode: 200,
        data: entry.data,
        extra: {if (offline) 'fromCache': true, if (offline) 'cachedAt': entry.savedAt},
      );
}
