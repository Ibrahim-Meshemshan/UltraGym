import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/core.dart';
import '../../data/repo/staff_repository.dart';
import '../../domain/models/staff_models.dart';

/// كلمات السر الجديدة بعد إعادة التعيين (فردياً أو جماعياً): تظهر مرة واحدة، نسخ وواتساب لكل حساب،
/// و "طباعة البطاقات PDF" (الخادم لا يحفظ الكلمات، فتُرسل البطاقات من هنا). المتخطاة بسببها تحتها.
abstract final class IssuedCredentialsDialog {
  static Future<void> show(BuildContext context, ResetResult result) => showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => BlocProvider(create: (_) => ToggleCubit(), child: _Body(result)),
  );
}

class _Body extends StatelessWidget {
  const _Body(this.result);

  final ResetResult result;

  Future<void> _print(BuildContext context) async {
    final busy = context.read<ToggleCubit>();
    if (busy.state) return;
    busy.toggle();
    final r = await sl<StaffRepository>().cardsPdf(result.credentials);
    if (busy.isClosed) return;
    busy.toggle();
    switch (r) {
      case ApiSuccess(:final data):
        await BlobOpener.open(data);
      case ApiFailure(:final failure):
        AppSnackbar.show(failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final creds = result.credentials;
    final printing = context.watch<ToggleCubit>().state;
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
            spacing: AppSpace.s3,
            children: [
              Row(
                children: [
                  IconSlab(
                    creds.isEmpty ? Icons.info_outline_rounded : Icons.key_rounded,
                    size: AppSize.control,
                    tone: creds.isEmpty ? UTone.warning : UTone.success,
                  ),
                  AppSpace.gap3,
                  Expanded(
                    child: Text(result.message ?? 'كلمات السر الجديدة', style: UType.h2(color: c.ink)),
                  ),
                ],
              ),
              if (creds.isNotEmpty)
                Text(
                  'تظهر الكلمات هنا مرة واحدة فقط، وانتهت جلسات هذه الحسابات. أرسلها أو اطبع البطاقات الآن.',
                  style: UType.body(color: c.inkMuted),
                ),
              for (final x in creds) _CredentialTile(x),
              if (result.skipped.isNotEmpty) ...[
                Text('لم تُعَد لهؤلاء', style: UType.label(color: c.inkMuted).weight(600)),
                for (final s in result.skipped)
                  Text('${s.name}: ${s.reason}', style: UType.caption(color: c.warningInk)),
              ],
              AppSpace.gap2,
              Wrap(
                alignment: WrapAlignment.end,
                spacing: AppSpace.s2,
                runSpacing: AppSpace.s2,
                children: [
                  UGButton(label: 'تم', kind: UButtonKind.ghost, onPressed: () => Navigator.of(context).pop()),
                  if (creds.isNotEmpty)
                    UGButton(
                      label: printing ? 'جارٍ التجهيز…' : 'طباعة البطاقات PDF',
                      icon: Icons.print_rounded,
                      onPressed: printing ? null : () => _print(context),
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

class _CredentialTile extends StatelessWidget {
  const _CredentialTile(this.x);

  final IssuedCredential x;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: x.whatsappMessage ?? '${x.memberCode}\n${x.password}'));
    AppSnackbar.show('تم نسخ بيانات دخول ${x.name}.');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final caption = UType.caption(color: c.inkMuted);
    return Container(
      padding: const EdgeInsetsDirectional.only(start: AppSpace.s4, end: AppSpace.s1, top: AppSpace.s2, bottom: AppSpace.s2),
      decoration: BoxDecoration(color: c.surfaceAlt, borderRadius: AppRadius.fieldAll),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  x.roleLabel.isEmpty ? x.name : '${x.name} · ${x.roleLabel}',
                  style: UType.label(color: c.ink).weight(600),
                ),
                Wrap(
                  spacing: AppSpace.s3,
                  children: [
                    if (x.memberCode.isNotEmpty) LtrText(x.memberCode, style: caption),
                    if (x.phone.isNotEmpty) LtrText(x.phone, style: caption),
                  ],
                ),
                LtrText(x.password, style: UType.h3(color: c.ink)),
                if (x.expiresAt case final at?)
                  Wrap(
                    children: [
                      Text('صالحة حتى ', style: caption),
                      LtrText(Formatters.date(DateTime.tryParse(at), fromUtc: true), style: caption),
                    ],
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'نسخ بيانات ${x.name}',
            onPressed: _copy,
            icon: Icon(Icons.copy_rounded, size: AppSize.iconSm, color: c.inkMuted),
          ),
          if (x.phone.isNotEmpty)
            IconButton(
              tooltip: 'إرسال لـ ${x.name} بواتساب',
              onPressed: () => Launcher.whatsapp(x.phone, text: x.whatsappMessage),
              icon: Icon(Icons.send_rounded, size: AppSize.iconSm, color: c.primaryInk),
            ),
        ],
      ),
    );
  }
}
