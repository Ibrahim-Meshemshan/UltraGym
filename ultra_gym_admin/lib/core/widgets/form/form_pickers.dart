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
  const FormDropdown(
    this.name, {
    super.key,
    required this.label,
    required this.options,
    this.required = false,
    this.hint,
  });

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
      builder: (context, sel) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FieldLabel(label, required: required),
          DropdownButtonFormField<T>(
            value: options.any((o) => o.value == sel.$1) ? sel.$1 as T : null,
            isExpanded: true,
            hint: hint == null ? null : Text(hint!),
            decoration: InputDecoration(errorText: sel.$2),
            items: [for (final o in options) DropdownMenuItem(value: o.value, child: Text(o.label))],
            onChanged: sel.$3 ? null : (v) => form.set(name, v),
          ),
        ],
      ),
    );
  }
}

/// منتقي تاريخ (يُرسل `2026-10-07`).
class FormDate extends StatelessWidget {
  const FormDate(
    this.name, {
    super.key,
    required this.label,
    this.required = false,
    this.firstDate,
    this.lastDate,
    this.clearable = false,
    this.hint,
  });

  final String name, label;
  final bool required;

  /// زر × يمسح التاريخ المختار (حقل اختياري يعني فراغه شيئاً، مثل "بلا انتهاء").
  final bool clearable;

  /// النص حين لا تاريخ (افتراضياً "اختر التاريخ").
  final String? hint;
  final DateTime? firstDate, lastDate;

  @override
  Widget build(BuildContext context) {
    final form = context.read<AppFormCubit>();
    form.validator(name, required ? (_) => form.value(name) == null ? 'اختر التاريخ.' : null : null);
    return BlocSelector<AppFormCubit, AppFormState, (Object?, String?, bool)>(
      selector: (s) => (s.values[name], s.errorOf(name), s.submitting),
      builder: (context, sel) {
        final value = sel.$1 is DateTime ? sel.$1! as DateTime : null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FieldLabel(label, required: required),
            InkWell(
              borderRadius: AppRadius.fieldAll,
              onTap: sel.$3
                  ? null
                  : () async {
                      final now = DateTime.now();
                      final first = firstDate ?? DateTime(now.year - 5);
                      final last = lastDate ?? DateTime(now.year + 5);
                      // تاريخ الميلاد مثلاً: آخر يوم مسموح قبل اليوم، فلا يُفتح المنتقي على تاريخ خارج المدى.
                      final initial = value ?? (now.isAfter(last) ? last : (now.isBefore(first) ? first : now));
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: initial,
                        firstDate: first,
                        lastDate: last,
                      );
                      if (picked != null) form.set(name, picked);
                    },
              child: InputDecorator(
                decoration: InputDecoration(
                  errorText: sel.$2,
                  suffixIcon: clearable && value != null && !sel.$3
                      ? IconButton(
                          tooltip: 'مسح التاريخ',
                          onPressed: () => form.set(name, null),
                          icon: const Icon(Icons.close_rounded),
                        )
                      : const Icon(Icons.calendar_today_rounded),
                ),
                child: Text(
                  value == null ? hint ?? 'اختر التاريخ' : Formatters.date(value),
                  textDirection: value == null ? null : TextDirection.ltr,
                  style: UType.body(color: value == null ? context.colors.inkFaint : context.colors.ink),
                ),
              ),
            ),
          ],
        );
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FieldLabel(label, required: required),
            Wrap(
              spacing: AppSpace.s2,
              runSpacing: AppSpace.s2,
              children: [
                for (final o in options)
                  FilterChip(
                    label: Text(o.label),
                    selected: selected.contains(o.value),
                    onSelected: sel.$3
                        ? null
                        : (on) => form.set(name, on ? [...selected, o.value] : (selected..remove(o.value))),
                  ),
              ],
            ),
            if (sel.$2 != null)
              Padding(
                padding: const EdgeInsetsDirectional.only(top: AppSpace.s1),
                child: Text(sel.$2!, style: UType.caption(color: context.colors.dangerInk)),
              ),
          ],
        );
      },
    );
  }
}

/// اختيار واحد برقائق (الاتجاه، العملة، الحالة). المحدد يبقى بمظهره الفعّال، والضغط عليه لا يغيّر شيئاً.
/// `onChanged` بعد تغيير القيمة (مثلاً مسح حقل يعتمد عليها).
class FormChoice<T> extends StatelessWidget {
  const FormChoice(this.name, {super.key, required this.label, required this.options, this.onChanged});

  final String name, label;
  final List<FormOption<T>> options;
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) {
    final form = context.read<AppFormCubit>();
    return BlocSelector<AppFormCubit, AppFormState, (Object?, bool)>(
      selector: (s) => (s.values[name], s.submitting),
      builder: (context, sel) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FieldLabel(label),
          Semantics(
            label: label,
            container: true,
            child: Wrap(
              spacing: AppSpace.s2,
              runSpacing: AppSpace.s2,
              children: [
                for (final o in options)
                  ChoiceChip(
                    label: Text(o.label),
                    selected: sel.$1 == o.value,
                    onSelected: sel.$2
                        ? null
                        : (_) {
                            if (sel.$1 == o.value) return;
                            form.set(name, o.value);
                            onChanged?.call(o.value);
                          },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// مفتاح تشغيل/إيقاف بعنوان وشرح اختياري (تدريب شخصي، فعّالة للبيع...). القيمة `bool`.
class FormSwitch extends StatelessWidget {
  const FormSwitch(this.name, {super.key, required this.label, this.hint});

  final String name, label;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final form = context.read<AppFormCubit>();
    return BlocSelector<AppFormCubit, AppFormState, (bool, bool)>(
      selector: (s) => (s.values[name] == true, s.submitting),
      builder: (context, sel) => SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        value: sel.$1,
        onChanged: sel.$2 ? null : (v) => form.set(name, v),
        title: Text(label, style: UType.body(color: context.colors.ink)),
        subtitle: hint == null ? null : Text(hint!, style: UType.caption(color: context.colors.inkMuted)),
      ),
    );
  }
}
