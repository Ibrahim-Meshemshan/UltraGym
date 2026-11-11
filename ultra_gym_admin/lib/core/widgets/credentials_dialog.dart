import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ultragym_design/ultragym_design.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import '../utils/launcher.dart';
import 'app_snackbar.dart';
import 'on_init.dart';

/// سطر بنافذة بيانات الدخول: عنوان + قيمة LTR قابلة للنسخ.
typedef CredentialLine = ({String label, String value});

/// بيانات دخول تُعرض مرة واحدة (كلمة سر مؤقتة لعضو أو موظف): نسخ لكل سطر، "نسخ الكل"، وإرسال بواتساب
/// برسالة الخادم الجاهزة (`whatsapp_message`). لا تُحفظ بأي مكان بعد الإغلاق.
abstract final class CredentialsDialog {
  static Future<void> show(
    BuildContext context, {
    required String title,
    required List<CredentialLine> lines,
    String? note,
    String? validUntil,
    String? whatsappPhone,
    String? whatsappText,
  }) => showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _CredentialsBody(
      title: title,
      lines: lines,
      note: note,
      validUntil: validUntil,
      whatsappPhone: whatsappPhone,
      whatsappText: whatsappText,
    ),
  );
}

class _CredentialsBody extends StatelessWidget {
  const _CredentialsBody({
    required this.title,
    required this.lines,
    this.note,
    this.validUntil,
    this.whatsappPhone,
    this.whatsappText,
  });

  final String title;
  final List<CredentialLine> lines;

  /// تاريخ انتهاء كلمة السر المؤقتة (`2026-11-16`): سطر مستقل بقيمة LTR فلا ينكسر التاريخ بين سطرين.
  final String? note, validUntil, whatsappPhone, whatsappText;

  static Future<void> _copy(String text, String done) async {
    await Clipboard.setData(ClipboardData(text: text));
    AppSnackbar.show(done);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final phone = whatsappPhone;
    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpace.s4),
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(AppRadius.hero))),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSize.dialog),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpace.s6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const IconSlab(Icons.key_rounded, size: AppSize.control, tone: UTone.success),
                  AppSpace.gap3,
                  Expanded(
                    child: Text(title, style: UType.h2(color: c.ink)),
                  ),
                ],
              ),
              if (note != null) ...[AppSpace.gap3, Text(note!, style: UType.body(color: c.inkMuted))],
              AppSpace.gap5,
              for (final l in lines) _Line(line: l, onCopy: () => _copy(l.value, 'تم نسخ ${l.label}.')),
              if (validUntil case final until?)
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: AppSize.iconSm, color: c.inkMuted),
                    AppSpace.gap2,
                    Text('كلمة السر صالحة حتى ', style: UType.label(color: c.inkMuted)),
                    LtrText(until, style: UType.label(color: c.ink).weight(600)),
                  ],
                ),
              AppSpace.gap6,
              Wrap(
                alignment: WrapAlignment.end,
                spacing: AppSpace.s2,
                runSpacing: AppSpace.s2,
                children: [
                  UGButton(label: 'تم', kind: UButtonKind.ghost, onPressed: () => Navigator.of(context).pop()),
                  UGButton(
                    label: 'نسخ الكل',
                    icon: Icons.copy_rounded,
                    kind: UButtonKind.secondary,
                    onPressed: () => _copy(
                      whatsappText ?? [for (final l in lines) '${l.label}: ${l.value}'].join('\n'),
                      'تم نسخ بيانات الدخول.',
                    ),
                  ),
                  if (phone != null)
                    UGButton(
                      label: 'إرسال بواتساب',
                      icon: Icons.send_rounded,
                      onPressed: () => Launcher.whatsapp(phone, text: whatsappText),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.line, required this.onCopy});

  final CredentialLine line;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpace.s2),
      padding: const EdgeInsetsDirectional.only(start: AppSpace.s4, end: AppSpace.s1),
      decoration: BoxDecoration(color: c.surfaceAlt, borderRadius: AppRadius.fieldAll),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.s2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(line.label, style: UType.caption(color: c.inkMuted)),
                  LtrText(line.value, style: UType.h3(color: c.ink)),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'نسخ ${line.label}',
            onPressed: onCopy,
            icon: Icon(Icons.copy_rounded, size: AppSize.iconSm, color: c.inkMuted),
          ),
        ],
      ),
    );
  }
}
