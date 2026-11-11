import 'package:get_it/get_it.dart';

import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repo/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/login_cubit.dart';

/// تسجيل الميزات: المستودع `registerLazySingleton<XRepository>(() => XRemoteDataSource(sl()))`،
/// وحالة الجلسة المشتركة lazySingleton، و Bloc الشاشة `registerFactory`.
void registerFeatures(GetIt sl) {
  sl
    // الدخول والجلسة
    ..registerLazySingleton<AuthRepository>(() => AuthRemoteDataSource(sl(), sl()))
    ..registerLazySingleton<AuthBloc>(() => AuthBloc(sl(), sl()))
    ..registerFactory<LoginCubit>(() => LoginCubit(sl()));
}
