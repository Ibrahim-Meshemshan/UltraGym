import 'package:flutter/material.dart';

/// مفتاح عام لعرض الرسائل من أي مكان (مربوط بـ MaterialApp).
final appMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// رسائل النجاح والتنبيه القصيرة. النجاح بصيغة الماضي: "تم الحفظ."
abstract final class AppSnackbar {
  static void show(String message) {
    appMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
