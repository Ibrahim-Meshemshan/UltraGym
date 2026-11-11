import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../members/presentation/widgets/member_cells.dart';
import '../../domain/models/attendance_models.dart';

/// بطاقة نتيجة الدخول: خضراء مقبول، عنبرية بالسماح، زرقاء مكرر ("مسجّل منذ…")، حمراء مرفوض بالسبب.
/// النص رسالة الخادم كما هي، والاشتراك والدين من بطاقة العضو بالرد.
class CheckInResultCard extends StatelessWidget {
  const CheckInResultCard(this.r, {super.key});

  final CheckInResult r;

  static (UTone, IconData) lookOf(CheckInResult r) => switch (r.kind) {
    CheckInKind.accepted when r.inGrace => (UTone.warning, Icons.hourglass_bottom_rounded),
    CheckInKind.accepted => (UTone.success, Icons.check_rounded),
    CheckInKind.duplicate => (UTone.info, Icons.history_rounded),
    CheckInKind.rejected => (UTone.danger, Icons.block_rounded),
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (tone, icon) = lookOf(r);
    final (soft, ink) = tone.colors(c);
    final m = r.membership;
    final ids = [r.memberCode, r.phone].nonNulls.join(' · ');
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpace.s4),
        decoration: BoxDecoration(color: soft, borderRadius: AppRadius.cardAll),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpace.s3,
          children: [
            Row(
              children: [
                IconSlab(icon, tone: tone, size: AppSize.control),
                AppSpace.gap3,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.playerName, style: UType.h3(color: c.ink)),
                      if (ids.isNotEmpty) LtrText(ids, style: UType.caption(color: c.inkMuted)),
                    ],
                  ),
                ),
              ],
            ),
            Text(r.message, style: UType.bodyLg(color: ink).weight(600)),
            if (m != null)
              Wrap(
                spacing: AppSpace.s2,
                runSpacing: AppSpace.s1,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('${m.planName} · ${membershipDetail(m)}', style: UType.body(color: c.ink)),
                  StatusBadge(m.statusLabel, tone: Labels.membershipStatus(m.status).tone),
                ],
              ),
            if (r.sessionConsumed) Text('استُهلكت جلسة من اشتراكه.', style: UType.label(color: c.inkMuted)),
            if (m != null && m.dueUsd > 0)
              Text(
                'عليه دين ${Formatters.ltr(Formatters.usd(m.dueUsd))} بهذا الاشتراك.',
                style: UType.label(color: c.warningInk).weight(600),
              ),
          ],
        ),
      ),
    );
  }
}

/// الفعل التالي بعد النتيجة: بيع اشتراك لمن لا اشتراك له أو انتهى، فتح الاشتراك (فك تجميد، تجديد، سداد)،
/// أو ملف العضو (موقوف، جنس غير محدد، خارج وقت قسمه).
({String label, IconData icon, String route})? checkInFollowUp(CheckInResult r) {
  final m = r.membership;
  final open = m == null ? null : Routes.child(Routes.memberships, m.id);
  final sell = (label: 'بيع اشتراك', icon: Icons.add_card_rounded, route: Routes.sellTo(r.playerId));
  final membership = open == null ? sell : (label: 'فتح الاشتراك', icon: Icons.open_in_new_rounded, route: open);
  return switch (r.kind) {
    CheckInKind.rejected => switch (r.code) {
      'NO_MEMBERSHIP' || 'EXPIRED' => sell,
      'FROZEN' || 'UPCOMING' || 'NO_SESSIONS' || 'BRANCH_NOT_ALLOWED' => membership,
      _ => (label: 'ملف العضو', icon: Icons.person_rounded, route: Routes.child(Routes.members, r.playerId)),
    },
    _ when m != null && m.dueUsd > 0 => (label: 'سداد الدين', icon: Icons.payments_rounded, route: open!),
    _ when r.inGrace => sell,
    _ => null,
  };
}
