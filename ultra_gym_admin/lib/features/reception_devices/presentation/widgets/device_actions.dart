import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../data/repo/reception_devices_repository.dart';
import '../../domain/models/reception_device_models.dart';

/// إيقاف جهاز (للمالك، `ReceptionDevices.html` · نافذة الإيقاف). لا تراجع عنه من اللوحة: الجهاز الموقوف
/// لا يحمّل البيانات ولا يزامن، وتسجيله من جديد يرفضه الخادم (`DEVICE_REVOKED`).
abstract final class DeviceActions {
  static Future<bool> revoke(BuildContext context, ReceptionDevice d) async {
    final now = sl<ServerClock>().now();
    final done = await FormDialog.show<ReceptionDevice>(
      context,
      title: 'إيقاف «${d.name}»؟',
      icon: Icons.phonelink_erase_rounded,
      message:
          'لن يستطيع الجهاز تحميل البيانات ولا إرسال المزامنة بعد الإيقاف، '
          'وأي عمليات دون اتصال لم تُرسل منه ستبقى عليه.',
      submitLabel: 'إيقاف الجهاز',
      danger: true,
      fields: (_) => _SyncNote(
        d.lastSyncAt == null
            ? 'لم يزامن هذا الجهاز أي عملية بعد.'
            : 'آخر مزامنة لهذا الجهاز ${DeviceTexts.sync(d, now)}.',
      ),
      onSubmit: (_) => sl<ReceptionDevicesRepository>().revoke(d.id),
    );
    return done != null;
  }
}

class _SyncNote extends StatelessWidget {
  const _SyncNote(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.s4, vertical: AppSpace.s3),
      decoration: BoxDecoration(color: c.warningSoft, borderRadius: AppRadius.fieldAll),
      child: Text(text, style: UType.label(color: c.warningInk)),
    );
  }
}
