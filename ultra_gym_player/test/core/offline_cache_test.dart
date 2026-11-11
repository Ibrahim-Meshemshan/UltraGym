import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_gym_player/core/network/connection_cubit.dart';
import 'package:ultra_gym_player/core/network/connectivity_interceptor.dart';
import 'package:ultra_gym_player/core/network/offline_cache_interceptor.dart';
import 'package:ultra_gym_player/core/networking/api_client.dart';
import 'package:ultra_gym_player/core/networking/parse.dart';
import 'package:ultra_gym_player/core/storage/cache_store_base.dart';
import 'package:ultra_gym_player/core/storage/session_storage.dart';
import 'package:ultra_gym_player/core/storage/token_store_base.dart';
import 'package:ultra_gym_player/core/error/failure.dart';

import 'fake_api.dart';

class _MemoryCache implements CacheStore {
  final map = <String, CacheEntry>{};

  @override
  Future<CacheEntry?> read(String key) async => map[key];

  @override
  Future<void> write(String key, CacheEntry entry) async => map[key] = entry;

  @override
  Future<void> clear() async => map.clear();
}

class _Conn extends ConnectionCubit {
  _Conn() : super();

  void force(ConnectionStatus s) => emit(s);

  @override
  Future<void> recheck() async {}
}

void main() {
  late FakeAdapter adapter;
  late _MemoryCache cache;
  late _Conn conn;
  late SessionStorage session;
  late ApiClient api;

  setUp(() async {
    adapter = FakeAdapter((_) => jsonBody(200, {'success': true, 'data': {'days': 21}}, headers: {'etag': ['"v1"']}));
    cache = _MemoryCache();
    conn = _Conn()..force(ConnectionStatus.online);
    session = SessionStorage(MemoryTokenStore(), onClear: cache.clear);
    await session.save('t1');
    final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:8000/api/v1'))
      ..httpClientAdapter = adapter
      ..interceptors.addAll([OfflineCacheInterceptor(cache, session, conn), ConnectivityInterceptor(conn)]);
    api = ApiClient(dio);
  });

  tearDown(() => conn.close());

  test('online response is cached, offline read is served from cache with cachedAt', () async {
    final first = await api.get('/player/home', parse: Parse.json);
    expect(first.dataOrNull!['days'], 21);
    expect(cache.map, hasLength(1));

    conn.force(ConnectionStatus.offline);
    adapter.respond = (o) => throw StateError('must not hit the network');
    final offline = await api.get('/player/home', parse: Parse.json);
    expect(offline.dataOrNull!['days'], 21);
    expect((offline as dynamic).fromCache, isTrue);
  });

  test('sends If-None-Match and serves the saved copy on 304', () async {
    await api.get('/player/home', parse: Parse.json);
    adapter.respond = (_) => jsonBody(304, const {});
    final r = await api.get('/player/home', parse: Parse.json);
    expect(adapter.last!.headers['If-None-Match'], '"v1"');
    expect(r.dataOrNull!['days'], 21);
  });

  test('network failure falls back to the cached copy', () async {
    await api.get('/player/home', parse: Parse.json);
    adapter.respond = (o) => throw DioException.connectionError(requestOptions: o, reason: 'down');
    final r = await api.get('/player/home', parse: Parse.json);
    expect(r.dataOrNull!['days'], 21);
  });

  test('writes are rejected offline with an offline Failure', () async {
    conn.force(ConnectionStatus.offline);
    final r = await api.post('/player/profile', body: const {}, parse: Parse.none);
    expect(r.failureOrNull!.type, FailureType.offline);
  });

  test('cache is per token and cleared with the session', () async {
    await api.get('/player/home', parse: Parse.json);
    await session.save('t2');
    await api.get('/player/home', parse: Parse.json);
    expect(cache.map, hasLength(2));
    await session.clear();
    expect(cache.map, isEmpty);
  });
}
