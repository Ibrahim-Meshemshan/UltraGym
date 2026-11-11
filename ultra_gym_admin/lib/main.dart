import 'dart:async';

import 'package:flutter/material.dart';

import 'app.dart';
import 'core/core.dart';
import 'core/storage/impersonation.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

/// التهيئة: شبكة الأخطاء ← الحقن ← runApp. أي فشل = شاشة خطأ تشغيل واضحة.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GlobalErrorGuard.install();
  try {
    await configureDependencies();
    await Impersonation.consume(sl<SessionStorage>());
    sl<AuthBloc>().add(const AuthStarted());
    runApp(const App());
  } catch (e, s) {
    debugPrint('[startup] $e\n$s');
    runApp(const StartupFailureApp());
  }
}
