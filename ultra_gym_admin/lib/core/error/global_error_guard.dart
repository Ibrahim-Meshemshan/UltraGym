import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../widgets/app_snackbar.dart';

/// شبكة أمان لأي خطأ غير ملتقط: يُسجَّل، والمستخدم يرى رسالة عربية بدل شاشة رمادية.
abstract final class GlobalErrorGuard {
  static const _message = 'حدث خطأ غير متوقع. أعد المحاولة.';

  static void install() {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      if (kReleaseMode) AppSnackbar.show(_message);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('[GlobalErrorGuard] $error\n$stack');
      AppSnackbar.show(_message);
      return true;
    };
  }
}

/// تظهر إن فشل التشغيل نفسه، بدل شاشة بدء معلّقة.
class StartupFailureApp extends StatelessWidget {
  const StartupFailureApp({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(body: Center(child: Text('تعذّر تشغيل التطبيق. أغلقه وافتحه من جديد.'))),
    ),
  );
}
