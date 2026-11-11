import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'core/core.dart';
import 'core/router/app_router.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

/// جذر التطبيق: الثيمان، العربية، RTL، حصر تكبير الخط، والمفتاح العام للرسائل.
class App extends StatelessWidget {
  const App({super.key});

  static final GoRouter _router = buildRouter(sl<AuthBloc>());

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider.value(value: sl<ThemeCubit>()), BlocProvider.value(value: sl<AuthBloc>())],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, mode) => MaterialApp.router(
          title: AppConfig.appTitle,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          scaffoldMessengerKey: appMessengerKey,
          routerConfig: _router,
          builder: (context, child) => MediaQuery.withClampedTextScaling(
            minScaleFactor: AppConfig.minTextScale,
            maxScaleFactor: AppConfig.maxTextScale,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
