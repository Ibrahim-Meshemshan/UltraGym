import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/core.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

/// التهيئة: شبكة الأخطاء ← edge-to-edge ← عمودي فقط ← الحقن ← (الإشعارات لاحقاً) ← runApp.
/// أي فشل = شاشة خطأ تشغيل واضحة.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GlobalErrorGuard.install();
  try {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    await configureDependencies();
    sl<AuthBloc>().add(const AuthStarted());
    // TODO(push): PushService.init() عند تفعيل Firebase (لا يوقف التشغيل إن فشل).
    runApp(const App());
  } catch (e, s) {
    debugPrint('[startup] $e\n$s');
    runApp(const StartupFailureApp());
  }
}
