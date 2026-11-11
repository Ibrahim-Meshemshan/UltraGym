import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ultragym_design/ultragym_design.dart';

import '../../bloc/app_form_cubit.dart';
import '../../bloc/value_cubit.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../utils/validators.dart';

/// عمود حقول النموذج بفراغ ثابت بينها.
class FormColumn extends StatelessWidget {
  const FormColumn({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < children.length; i++) ...[if (i > 0) AppSpace.gap4, children[i]],
    ],
  );
}

/// عنوان الحقل فوقه (+ علامة الإلزام).
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.required = false});

  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpace.s2),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: text),
            if (required)
              TextSpan(
                text: ' *',
                style: UType.label(color: c.dangerInk),
              ),
          ],
        ),
        style: UType.label(color: c.inkMuted),
      ),
    );
  }
}

/// حقل نصي مربوط بـ `AppFormCubit` بالاسم المنقّط (`owner.phone`). خطأ 422 يظهر تحته.
class FormText extends StatelessWidget {
  const FormText(
    this.name, {
    super.key,
    required this.label,
    this.hint,
    this.required = false,
    this.validator,
    this.ltr = false,
    this.keyboardType,
    this.maxLines = 1,
    this.obscure = false,
    this.suffix,
    this.autofocus = false,
    this.textInputAction,
    this.onSubmitted,
  });

  final String name, label;
  final String? hint;
  final bool required, ltr, obscure, autofocus;
  final FieldValidator? validator;
  final TextInputType? keyboardType;
  final int maxLines;
  final Widget? suffix;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final form = context.read<AppFormCubit>();
    form.validator(name, validator ?? (required ? Validators.required() : null));
    return BlocSelector<AppFormCubit, AppFormState, (String?, bool)>(
      selector: (s) => (s.errorOf(name), s.submitting),
      builder: (context, sel) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FieldLabel(label, required: required),
          TextField(
            controller: form.text(name),
            enabled: !sel.$2,
            obscureText: obscure,
            autofocus: autofocus,
            maxLines: obscure ? 1 : maxLines,
            keyboardType: keyboardType ?? (ltr ? TextInputType.visiblePassword : null),
            textDirection: ltr ? TextDirection.ltr : null,
            textInputAction: textInputAction,
            onSubmitted: onSubmitted,
            style: UType.body(color: context.colors.ink),
            // حقل LTR (موبايل، معرّف): التلميح LTR أيضاً، وإلا ينقلب "0944 123 456" إلى "456 123 0944".
            decoration: InputDecoration(
              hintText: hint,
              hintTextDirection: ltr ? TextDirection.ltr : null,
              errorText: sel.$1,
              suffixIcon: suffix,
            ),
          ),
        ],
      ),
    );
  }
}

/// كلمة السر مع زر إظهار/إخفاء (حالته بـ `ToggleCubit`، بلا setState).
class FormPassword extends StatelessWidget {
  const FormPassword(
    this.name, {
    super.key,
    required this.label,
    this.required = true,
    this.validator,
    this.onSubmitted,
  });

  final String name, label;
  final bool required;
  final FieldValidator? validator;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => ToggleCubit(true),
    child: BlocBuilder<ToggleCubit, bool>(
      builder: (context, hidden) => FormText(
        name,
        label: label,
        required: required,
        validator: validator,
        ltr: true,
        obscure: hidden,
        onSubmitted: onSubmitted,
        suffix: IconButton(
          tooltip: hidden ? 'إظهار كلمة السر' : 'إخفاء كلمة السر',
          icon: Icon(hidden ? Icons.visibility_rounded : Icons.visibility_off_rounded),
          onPressed: context.read<ToggleCubit>().toggle,
        ),
      ),
    ),
  );
}
