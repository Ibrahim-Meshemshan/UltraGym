import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// شريطا النظام شفافان، وأيقوناتهما حسب الثيم.
abstract final class SystemUi {
  static SystemUiOverlayStyle styleFor(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
      statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      statusBarBrightness: dark ? Brightness.dark : Brightness.light,
      systemNavigationBarIconBrightness: dark ? Brightness.light : Brightness.dark,
    );
  }
}
