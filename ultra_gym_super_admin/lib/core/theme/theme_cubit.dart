import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// وضع الثيم: يتبع الجهاز حتى يختار المستخدم، ويُحفظ اختياره.
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit(this._prefs) : super(_read(_prefs));

  final SharedPreferences _prefs;
  static const _key = 'theme_mode';

  static ThemeMode _read(SharedPreferences prefs) =>
      ThemeMode.values.asNameMap()[prefs.getString(_key)] ?? ThemeMode.system;

  Future<void> select(ThemeMode mode) async {
    emit(mode);
    await _prefs.setString(_key, mode.name);
  }
}
