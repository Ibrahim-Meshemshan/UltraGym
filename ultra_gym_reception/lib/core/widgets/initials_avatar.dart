import 'package:flutter/material.dart';
import 'package:ultragym_design/ultragym_design.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// صورة بديلة بالأحرف الأولى من الاسم (أول حرف من أول كلمتين): "أحمد الخطيب" ← "أخ".
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar(this.name, {super.key, required this.size, this.tone = UTone.primary, this.large = false});

  final String name;
  final double size;
  final UTone tone;

  /// بطاقة النتيجة: خط Changa كبير وزاوية بطاقة بدل الدائرة.
  final bool large;

  static String initialsOf(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).take(2);
    // "العلي" ← "ع" لا "ا".
    return words.map((w) => (w.length > 2 && w.startsWith('ال') ? w.substring(2) : w).characters.first).join();
  }

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = tone.colors(context.colors);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, borderRadius: large ? AppRadius.cardAll : AppRadius.fullAll),
      child: Text(
        initialsOf(name),
        style: large ? UType.stat(color: fg) : UType.caption(color: fg).weight(600),
      ),
    );
  }
}
