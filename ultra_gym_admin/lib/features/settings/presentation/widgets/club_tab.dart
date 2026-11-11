import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../data/repo/settings_repository.dart';
import '../../domain/models/settings_models.dart';
import '../bloc/settings_cubits.dart';
import 'club_form.dart';
import 'club_logo.dart';
import 'club_notifications_card.dart';
import 'club_settings_cards.dart';

/// تبويب النادي (`ClubSettings.html`): نموذج واحد للتواصل والإعدادات والإشعارات، و "حفظ الإعدادات" يرسل المتغيّر فقط.
/// النموذج يُبنى من جديد مع كل نسخة من النادي (بعد الحفظ) ومع "إلغاء" (عدّاد).
class ClubTab extends StatelessWidget {
  const ClubTab({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => ValueCubit<int>(0),
    child: BlocBuilder<ClubCubit, Slice<ClubProfile>>(
      builder: (context, slice) => SliceView<ClubProfile>(
        slice: slice,
        loading: const DetailsShimmer(lines: 10),
        onRetry: context.read<ClubCubit>().load,
        builder: (context, club) {
          final version = context.watch<ValueCubit<int>>().state;
          return BlocProvider(
            key: ValueKey((club, version)),
            create: (_) => AppFormCubit(initial: ClubForm.initial(club)),
            child: _ClubForm(club),
          );
        },
      ),
    ),
  );
}

class _ClubForm extends StatelessWidget {
  const _ClubForm(this.club);

  final ClubProfile club;

  Future<void> _save(BuildContext context) async {
    final form = context.read<AppFormCubit>();
    final timezone = form.value('timezone');
    final r = await form.submit((f) => ClubForm.save(sl<SettingsRepository>(), f, club));
    if (r is! ApiSuccess<void> || !context.mounted) return;
    AppSnackbar.show(r.message ?? 'تم الحفظ.');
    if (timezone != club.settings.timezone) context.read<AuthBloc>().add(const AuthRefreshed());
    await context.read<ClubCubit>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.select<AppFormCubit, bool>((f) => f.state.submitting);
    return Align(
      alignment: AlignmentDirectional.topStart,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSize.settingsMax),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpace.s5,
          children: [
            ClubContactCard(club: club, logo: ClubLogo(club)),
            ClubOperationsCard(timezone: club.settings.timezone),
            const ClubMembershipsCard(),
            const ClubExtrasCard(),
            const ClubNotificationsCard(),
            const FormErrorBanner(),
            Wrap(
              spacing: AppSpace.s3,
              runSpacing: AppSpace.s2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                UGButton(
                  label: busy ? 'جارٍ الحفظ…' : 'حفظ الإعدادات',
                  icon: Icons.check_rounded,
                  onPressed: busy ? null : () => _save(context),
                ),
                TextButton(
                  onPressed: busy ? null : () => context.read<ValueCubit<int>>().update((v) => v + 1),
                  child: const Text('إلغاء التغييرات'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
