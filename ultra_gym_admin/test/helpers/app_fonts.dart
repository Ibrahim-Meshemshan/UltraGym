import 'dart:io';

import 'package:flutter/services.dart';

/// يحمّل خطّي الهوية (Readex Pro و Changa) من حزمة `ultragym_design` لاختبارات الويدجت.
/// بدونهما يرسم `flutter_test` كل حرف مربعاً بعرض حجمه (ضعف العربي الحقيقي تقريباً)، فتلتف النصوص
/// وتفيض حيث لا تفيض بالمتصفح، وتختلف قرارات العرض (حبة البحث مثلاً). مرة واحدة لكل ملف اختبار.
Future<void> loadAppFonts() => _loaded ??= _load();

Future<void>? _loaded;

Future<void> _load() async {
  const dir = 'packages/ultragym_design/assets/fonts';
  for (final (family, file) in [
    ('ReadexPro', 'ReadexPro-VariableFont_wght.ttf'),
    ('Changa', 'Changa-VariableFont_wght.ttf'),
  ]) {
    final bytes = await File('$dir/$file').readAsBytes();
    await (FontLoader('packages/ultragym_design/$family')..addFont(Future.value(ByteData.sublistView(bytes)))).load();
  }
}
