import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../domain/models/support_models.dart';

/// مرفقات رسالة الدعم داخل `AppFormCubit` (القيمة `attachments` = `List<PickedUpload>`): "إرفاق ملف" حتى 5 ملفات
/// بامتدادات الخادم و 5MB لكل ملف، وشريحة لكل ملف بزر حذف. الإرسال يقرؤها بـ `AttachmentsField.of(form)`.
class AttachmentsField extends StatelessWidget {
  const AttachmentsField({super.key});

  static const name = 'attachments';

  static List<PickedUpload> of(AppFormCubit form) => switch (form.value(name)) {
    final List<PickedUpload> files => files,
    _ => const [],
  };

  Future<void> _add(AppFormCubit form) async {
    final picked = await FilePick.pick(
      extensions: SupportTexts.attachmentExtensions,
      maxBytes: SupportTexts.maxAttachmentBytes,
    );
    if (picked == null || form.isClosed) return;
    if (picked.error case final e?) return AppSnackbar.show(e);
    form.set(name, [...of(form), picked]);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final form = context.read<AppFormCubit>();
    return BlocBuilder<AppFormCubit, AppFormState>(
      buildWhen: (a, b) => a.values[name] != b.values[name] || a.submitting != b.submitting,
      builder: (context, state) {
        final files = of(form);
        return Wrap(
          spacing: AppSpace.s2,
          runSpacing: AppSpace.s2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final (i, f) in files.indexed)
              InputChip(
                avatar: Icon(Icons.attach_file_rounded, size: AppSize.iconSm, color: c.inkMuted),
                label: Text('${f.name} · ${SupportTexts.size((f.size / 1024).ceil())}', style: UType.caption(color: c.ink)),
                deleteButtonTooltipMessage: 'إزالة المرفق',
                onDeleted: state.submitting ? null : () => form.set(name, [...files]..removeAt(i)),
              ),
            if (files.length < SupportTexts.maxAttachments)
              UGButton(
                label: 'إرفاق ملف',
                icon: Icons.attach_file_rounded,
                kind: UButtonKind.secondary,
                onPressed: state.submitting ? null : () => _add(form),
              ),
            Text('حتى 5 ملفات، 5MB لكل ملف.', style: UType.caption(color: c.inkFaint)),
          ],
        );
      },
    );
  }
}
