import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ultragym_design/ultragym_design.dart';

import '../../features/auth/domain/models/auth_models.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../theme/app_palette.dart';
import '../theme/app_tokens.dart';
import '../utils/formatters.dart';
import '../widgets/on_init.dart';

/// شريط جلسة الدعم (`SystemStates.html`): ثابت أعلى كل الصفحات طوال الجلسة ولا يُخفى.
/// ألوانه زرقاء داكنة بالثيمين كما بالنموذج (من `AppPalette.dark`).
class SupportBanner extends StatelessWidget {
  const SupportBanner({super.key, required this.session});

  final Session session;

  @override
  Widget build(BuildContext context) {
    const p = AppPalette.dark;
    final bg = p.roles.infoSoft;
    final fg = p.ink;
    final hint = p.roles.infoInk;
    final ends = session.expiresAt;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        color: bg,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.s6, vertical: AppSpace.s2),
        child: Wrap(
          spacing: AppSpace.s3,
          runSpacing: AppSpace.s1,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('جلسة دعم من فريق UltraGym', style: UType.label(color: fg).weight(600)),
            if (ends != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('تنتهي الساعة ', style: UType.label(color: fg)),
                  LtrText(Formatters.time(ends), style: UType.label(color: fg).weight(600)),
                ],
              ),
            Text('تغيير كلمة السر والموبايل والجلسات مقفل', style: UType.caption(color: hint)),
            TextButton(
              onPressed: () => context.read<AuthBloc>().add(const AuthLogoutRequested()),
              style: TextButton.styleFrom(foregroundColor: fg, minimumSize: const Size(0, AppSize.controlSm)),
              child: const Text('إنهاء الجلسة'),
            ),
          ],
        ),
      ),
    );
  }
}
