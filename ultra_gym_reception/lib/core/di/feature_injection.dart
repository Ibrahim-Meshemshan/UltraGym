import 'package:get_it/get_it.dart';

import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repo/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/login_cubit.dart';
import '../../features/station/data/datasources/station_remote_datasource.dart';
import '../../features/station/data/repo/station_repository.dart';
import '../../features/station/presentation/bloc/active_branch_cubit.dart';
import '../../features/station/presentation/bloc/station_bloc.dart';
import '../../features/station/presentation/widgets/qr_scan_dialog.dart';

/// تسجيل الميزات: المستودع `registerLazySingleton<XRepository>(() => XRemoteDataSource(sl()))`،
/// وحالة الجلسة المشتركة lazySingleton، و Bloc الشاشة `registerFactory`.
void registerFeatures(GetIt sl) {
  sl
    // الدخول والجلسة
    ..registerLazySingleton<AuthRepository>(() => AuthRemoteDataSource(sl(), sl()))
    ..registerLazySingleton<AuthBloc>(() => AuthBloc(sl(), sl()))
    ..registerFactory<LoginCubit>(() => LoginCubit(sl()))
    // محطة الدخول: فرع المحطة يعيش طوال الجلسة، والكاميرا خلف واجهة للاختبارات.
    ..registerLazySingleton<StationRepository>(() => StationRemoteDataSource(sl()))
    ..registerLazySingleton<ActiveBranchCubit>(() => ActiveBranchCubit(sl(), sl()))
    ..registerLazySingleton<QrScanner>(() => const CameraQrScanner())
    ..registerFactory<StationBloc>(() => StationBloc(sl()));
}
