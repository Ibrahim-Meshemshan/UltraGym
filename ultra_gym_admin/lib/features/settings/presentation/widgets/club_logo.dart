import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../members/presentation/widgets/member_cells.dart';
import '../../data/repo/settings_repository.dart';
import '../../domain/models/settings_models.dart';
import '../bloc/settings_cubits.dart';

/// شعار النادي (يظهر بالقائمة الجانبية وتطبيق العضو والإيصالات): تغيير (png/jpg/webp حتى 2MB) أو إزالة.
/// يُحفظ فوراً لا مع "حفظ الإعدادات"، ثم تُحدَّث الجلسة ليتغير الشعار بالقائمة.
class ClubLogo extends StatelessWidget {
  const ClubLogo(this.club, {super.key});

  final ClubProfile club;

  static Future<void> _refresh(BuildContext context) async {
    context.read<AuthBloc>().add(const AuthRefreshed());
    await context.read<ClubCubit>().refresh();
  }

  Future<void> _change(BuildContext context) async {
    final picked = await FilePick.image(maxBytes: 2 * 1024 * 1024);
    if (picked == null || !context.mounted) return;
    if (picked.error case final error?) return AppSnackbar.show(error);
    final r = await sl<SettingsRepository>().uploadLogo(picked.form('logo'));
    if (!context.mounted) return;
    switch (r) {
      case ApiSuccess(:final message):
        AppSnackbar.show(message ?? 'تم تحديث الشعار.');
        await _refresh(context);
      case ApiFailure(:final failure):
        AppSnackbar.show(failure.message);
    }
  }

  Future<void> _remove(BuildContext context) async {
    final ok = await FormDialog.confirm<void>(
      context,
      title: 'إزالة الشعار',
      message: 'يعود شعار UltraGym مكانه بالقائمة وتطبيق العضو.',
      confirmLabel: 'إزالة',
      successMessage: 'أُزيل الشعار.',
      onConfirm: sl<SettingsRepository>().deleteLogo,
    );
    if (ok != null && context.mounted) await _refresh(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fallback = Center(
      child: Text(initials(club.name), style: UType.h2(color: c.primaryInk).weight(700)),
    );
    return Wrap(
      spacing: AppSpace.s4,
      runSpacing: AppSpace.s3,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ClipRRect(
          borderRadius: AppRadius.cardAll,
          child: Container(
            width: AppSize.profileAvatar,
            height: AppSize.profileAvatar,
            color: c.primarySoft,
            child: switch (club.logoUrl) {
              final url? => Image.network(
                url,
                fit: BoxFit.cover,
                semanticLabel: 'شعار ${club.name}',
                errorBuilder: (_, _, _) => fallback,
              ),
              null => ExcludeSemantics(child: fallback),
            },
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpace.s2,
          children: [
            Text('الشعار', style: UType.label(color: c.ink).weight(600)),
            Text('PNG أو JPG أو WEBP حتى 2MB.', style: UType.caption(color: c.inkMuted)),
            Wrap(
              spacing: AppSpace.s2,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _change(context),
                  icon: const Icon(Icons.upload_rounded),
                  label: Text(club.logoUrl == null ? 'رفع شعار' : 'تغيير الشعار'),
                ),
                if (club.logoUrl != null) TextButton(onPressed: () => _remove(context), child: const Text('إزالة')),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
