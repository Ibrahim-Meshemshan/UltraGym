import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/connection_cubit.dart';
import '../network/connectivity_interceptor.dart';
import '../network/offline_cache_interceptor.dart';
import '../storage/cache_store.dart';
import '../networking/api_client.dart';
import '../networking/auth_interceptor.dart';
import '../networking/dio_factory.dart';
import '../networking/server_clock.dart';
import '../storage/session_storage.dart';
import '../storage/token_store.dart';
import '../theme/theme_cubit.dart';
import '../utils/formatters.dart';
import 'feature_injection.dart';

/// المتغير الوحيد للحقن بالمشروع.
final sl = GetIt.instance;

/// تسجيل البنية (التخزين، الشبكة، الكاش، الثيم) ثم الميزات. يُستدعى مرة قبل `runApp`.
/// ترتيب الـ interceptors: الساعة ← الكاش ← فحص الاتصال ← التوكن.
Future<void> configureDependencies() async {
  Formatters.init();
  final prefs = await SharedPreferences.getInstance();
  final clock = ServerClock();
  final events = SessionEvents();
  final cache = createCacheStore();
  final session = SessionStorage(createTokenStore(), onClear: cache.clear);
  final connection = ConnectionCubit()..start();
  await session.load();

  sl
    ..registerSingleton<SharedPreferences>(prefs)
    ..registerSingleton<SessionStorage>(session)
    ..registerSingleton<ServerClock>(clock)
    ..registerSingleton<SessionEvents>(events)
    ..registerSingleton<CacheStore>(cache)
    ..registerSingleton<ConnectionCubit>(connection)
    ..registerLazySingleton<Dio>(
      () => DioFactory.create(interceptors: [
        ServerClockInterceptor(clock),
        OfflineCacheInterceptor(cache, session, connection),
        ConnectivityInterceptor(connection),
        AuthInterceptor(session, events),
      ]),
    )
    ..registerLazySingleton<ApiClient>(() => ApiClient(sl()))
    ..registerLazySingleton<ThemeCubit>(() => ThemeCubit(sl()));

  registerFeatures(sl);
}
