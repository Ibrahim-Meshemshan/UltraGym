import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ultragym_design/ultragym_design.dart';

import '../../bloc/app_form_cubit.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../utils/formatters.dart';
import 'form_fields.dart';

/// خيار بقائمة: القيمة التي تُرسل للخادم + النص المعروض.
typedef FormOption<T> = ({T value, String label});

/// قائمة منسدلة مربوطة بالنموذج. الخيارات من الخادم تُجلب بـ LoadCubit ثم تُمرر هنا.
class FormDropdown<T> extends StatelessWidget {
  const FormDropdown(this.name, {super.key, required this.label, required this.options, this.required = false, this.hint});

  final String name, label;
  final List<FormOption<T>> options;
  final bool required;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final form = context.read<AppFormCubit>();
    form.validator(name, required ? (_) => form.value(name) == null ? 'اختر $label.' : null : null);
    return BlocSelector<AppFormCubit, AppFormState, (Object?, String?, bool)>(
      selector: (s) => (s.values[name], s.errorOf(name), s.submitting),
      builder: (context, sel) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        FieldLabel(label, required: required),
        DropdownButtonFormField<T>(
          value: options.any((o) => o.value == sel.$1) ? sel.$1 as T : null,
          isExpanded: true,
          hint: hint == null ? null : Text(hint!),
          decoration: InputDecoration(errorText: sel.$2),
          items: [for (final o in options) DropdownMenuItem(value: o.value, child: Text(o.label))],
          onChanged: sel.$3 ? null : (v) => form.set(name, v),
        ),
      ]),
    );
  }
}

/// منتقي تاريخ (يُرسل `2026-10-07`).
class FormDate extends StatelessWidget {
  const FormDate(this.name, {super.key, required this.label, this.required = false, this.firstDate, this.lastDate});

  final String name, label;
  final bool required;
  final DateTime? firstDate, lastDate;

  @override
  Widget build(BuildContext context) {
    final form = context.read<AppFormCubit>();
    form.validator(name, required ? (_) => form.value(name) == null ? 'اختر التاريخ.' : null : null);
    return BlocSelector<AppFormCubit, AppFormState, (Object?, String?, bool)>(
      selector: (s) => (s.values[name], s.errorOf(name), s.submitting),
      builder: (context, sel) {
        final value = sel.$1 is DateTime ? sel.$1! as DateTime : null;
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          FieldLabel(label, required: required),
          InkWell(
            borderRadius: AppRadius.fieldAll,
            onTap: sel.$3
                ? null
                : () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: value ?? now,
                      firstDate: firstDate ?? DateTime(now.year - 5),
                      lastDate: lastDate ?? DateTime(now.year + 5),
                    );
                    if (picked != null) form.set(name, picked);
                  },
            child: InputDecorator(
              decoration: InputDecoration(errorText: sel.$2, suffixIcon: const Icon(Icons.calendar_today_rounded)),
              child: Text(
                value == null ? 'اختر التاريخ' : Formatters.date(value),
                textDirection: value == null ? null : TextDirection.ltr,
                style: UType.body(color: value == null ? context.colors.inkFaint : context.colors.ink),
              ),
            ),
          ),
        ]);
      },
    );
  }
}

/// اختيار متعدد برقائق (الأيام، الفروع...). القيمة قائمة.
class FormChips<T> extends StatelessWidget {
  const FormChips(this.name, {super.key, required this.label, required this.options, this.required = false});

  final String name, label;
  final List<FormOption<T>> options;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final form = context.read<AppFormCubit>();
    List<T> current() => [...?(form.value(name) as List<dynamic>?)?.whereType<T>()];
    form.validator(name, required ? (_) => current().isEmpty ? 'اختر عنصراً واحداً على الأقل.' : null : null);
    return BlocSelector<AppFormCubit, AppFormState, (Object?, String?, bool)>(
      selector: (s) => (s.values[name], s.errorOf(name), s.submitting),
      builder: (context, sel) {
        final selected = current();
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          FieldLabel(label, required: required),
          Wrap(spacing: AppSpace.s2, runSpacing: AppSpace.s2, children: [
            for (final o in options)
              FilterChip(
                label: Text(o.label),
                selected: selected.contains(o.value),
                onSelected: sel.$3
                    ? null
                    : (on) => form.set(name, on ? [...selected, o.value] : (selected..remove(o.value))),
              ),
          ]),
          if (sel.$2 != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: AppSpace.s1),
              child: Text(sel.$2!, style: UType.caption(color: context.colors.dangerInk)),
            ),
        ]);
      },
    );
  }
}
