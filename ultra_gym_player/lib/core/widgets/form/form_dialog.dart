import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ultragym_design/ultragym_design.dart';

import '../../bloc/app_form_cubit.dart';
import '../../networking/api_result.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../utils/json_x.dart';
import '../app_snackbar.dart';
import 'form_error_banner.dart';

/// نافذة كل تعديل وتأكيد بالمشروع. ترجع `ApiSuccess` عند النجاح، و null عند الإلغاء.
/// بعدها: `if (done != null && context.mounted) bloc.add(const XRequested(silent: true));`
abstract final class FormDialog {
  static Future<ApiSuccess<R>?> show<R>(
    BuildContext context, {
    required String title,
    required Future<ApiResult<R>> Function(AppFormCubit form) onSubmit,
    Widget Function(AppFormCubit form)? fields,
    IconData? icon,
    String? message,
    Json initial = const {},
    String submitLabel = 'حفظ',
    String? successMessage,
    bool danger = false,
  }) =>
      showDialog<ApiSuccess<R>>(
        context: context,
        builder: (_) => BlocProvider(
          create: (_) => AppFormCubit(initial: initial),
          child: _FormDialogBody<R>(
            title: title,
            icon: icon,
            message: message,
            fields: fields,
            onSubmit: onSubmit,
            submitLabel: submitLabel,
            successMessage: successMessage,
            danger: danger,
          ),
        ),
      );

  /// تأكيد (حذف، إيقاف، عكس، خروج من كل الأجهزة): نفس النافذة بلا حقول.
  static Future<ApiSuccess<R>?> confirm<R>(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required Future<ApiResult<R>> Function() onConfirm,
    IconData icon = Icons.warning_amber_rounded,
    bool danger = true,
    String? successMessage,
  }) =>
      show<R>(
        context,
        title: title,
        message: message,
        icon: icon,
        submitLabel: confirmLabel,
        danger: danger,
        successMessage: successMessage,
        onSubmit: (_) => onConfirm(),
      );
}

class _FormDialogBody<R> extends StatelessWidget {
  const _FormDialogBody({
    required this.title,
    required this.onSubmit,
    required this.submitLabel,
    required this.danger,
    this.icon,
    this.message,
    this.fields,
    this.successMessage,
  });

  final String title, submitLabel;
  final IconData? icon;
  final String? message, successMessage;
  final Widget Function(AppFormCubit form)? fields;
  final Future<ApiResult<R>> Function(AppFormCubit form) onSubmit;
  final bool danger;

  Future<void> _submit(BuildContext context) async {
    final form = context.read<AppFormCubit>();
    final nav = Navigator.of(context);
    final r = await form.submit(onSubmit);
    if (r is ApiSuccess<R>) {
      final msg = successMessage ?? r.message;
      if (msg != null && msg.isNotEmpty) AppSnackbar.show(msg);
      nav.pop(r);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final form = context.read<AppFormCubit>();
    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpace.s4),
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(AppRadius.hero))),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.s6),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              if (icon != null) ...[
                Container(
                  width: AppSize.control,
                  height: AppSize.control,
                  decoration: BoxDecoration(color: danger ? c.dangerSoft : c.primarySoft, borderRadius: AppRadius.smAll),
                  child: Icon(icon, color: danger ? c.dangerInk : c.primaryInk),
                ),
                AppSpace.gap3,
              ],
              Expanded(child: Text(title, style: UType.h2(color: c.ink))),
            ]),
            if (message != null) ...[AppSpace.gap3, Text(message!, style: UType.body(color: c.inkMuted))],
            const FormErrorBanner(),
            if (fields != null) ...[AppSpace.gap5, Flexible(child: SingleChildScrollView(child: fields!(form)))],
            AppSpace.gap6,
            BlocSelector<AppFormCubit, AppFormState, bool>(
              selector: (s) => s.submitting,
              builder: (context, submitting) => Wrap(
                alignment: WrapAlignment.end,
                spacing: AppSpace.s2,
                runSpacing: AppSpace.s2,
                children: [
                  UGButton(
                    label: 'إلغاء',
                    kind: UButtonKind.ghost,
                    onPressed: submitting ? null : () => Navigator.of(context).pop(),
                  ),
                  UGButton(
                    label: submitting ? 'جارٍ التنفيذ…' : submitLabel,
                    kind: danger ? UButtonKind.danger : UButtonKind.primary,
                    onPressed: submitting ? null : () => _submit(context),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

