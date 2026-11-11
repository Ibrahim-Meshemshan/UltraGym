import 'package:flutter/material.dart';
import 'package:ultragym_design/ultragym_design.dart';

import '../../theme/app_colors.dart';
import 'form_fields.dart';

/// حقل نص بمحرر مسودة (البرنامج، جدول الفرع): قيمته الأولى من المسودة وكل تعديل يذهب للـ Cubit (`onChanged`)، بلا controller.
/// المفتاح الثابت (معرّف التمرين أو اليوم) يُبقي الحقل وقيمته عند إضافة أو حذف ما قبله.
class DraftField extends StatelessWidget {
  const DraftField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.semanticsLabel,
    this.hint,
    this.error,
    this.ltr = false,
    this.enabled = true,
    this.maxLines = 1,
    this.digits = false,
  });

  final String value;
  final ValueChanged<String> onChanged;

  /// العنوان فوق الحقل؛ بدونه (أعمدة التمارين) يكفي `semanticsLabel` لقارئ الشاشة.
  final String? label, semanticsLabel, hint, error;
  final bool ltr, enabled, digits;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final field = Semantics(
      label: label == null ? semanticsLabel : null,
      textField: true,
      child: TextFormField(
        initialValue: value,
        onChanged: onChanged,
        enabled: enabled,
        maxLines: maxLines,
        keyboardType: digits ? TextInputType.number : null,
        textDirection: ltr ? TextDirection.ltr : null,
        style: UType.body(color: c.ink),
        decoration: InputDecoration(
          hintText: hint,
          hintTextDirection: ltr ? TextDirection.ltr : null,
          errorText: error,
          errorMaxLines: 2,
        ),
      ),
    );
    if (label == null) return field;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [FieldLabel(label!), field]);
  }
}
