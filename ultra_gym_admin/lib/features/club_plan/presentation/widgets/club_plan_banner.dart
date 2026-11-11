import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../bloc/club_plan_cubit.dart';

/// شريط اشتراك النادي بالمنصة أعلى كل الصفحات (`Dashboard.html`): فترة السماح (تنبيه) أو القراءة فقط (خطر).
/// للمالك رابط "اشتراك النادي". لا شيء حين يكون الاشتراك سليماً.
class ClubPlanBanner extends StatelessWidget {
  const ClubPlanBanner({super.key, required this.owner});

  final bool owner;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<ClubPlanCubit>().state;
    final c = context.colors;
    if (!s.readOnly && !s.inGrace) return const SizedBox.shrink();
    final grace = s.subscription?.graceEndsOn;
    final (bg, fg, title, note, link) = s.readOnly
        ? (
            c.dangerSoft,
            c.dangerInk,
            'اللوحة للقراءة فقط: انتهى اشتراك النادي بالمنصة.',
            'البيع والقبض والتعديل معطّلة حتى التجديد.',
            'تواصل مع UltraGym',
          )
        : (
            c.warningSoft,
            c.warningInk,
            grace == null
                ? 'انتهى اشتراك النادي بالمنصة، وأنت بفترة السماح.'
                : 'انتهى اشتراك النادي بالمنصة، وأنت بفترة السماح حتى ${Formatters.dayMonth(grace)}.',
            'بعدها تصبح اللوحة للقراءة فقط.',
            'عرض الفاتورة',
          );
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
            Text(title, style: UType.label(color: fg).weight(600)),
            Text(note, style: UType.label(color: fg)),
            if (owner)
              TextButton(
                onPressed: () => context.go(Routes.billing),
                style: TextButton.styleFrom(foregroundColor: fg, minimumSize: const Size(0, AppSize.controlSm)),
                child: Text(link),
              ),
          ],
        ),
      ),
    );
  }
}
