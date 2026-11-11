import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../domain/models/quick_search_models.dart';

/// عضو بنتيجة البحث: الاسم، الموبايل والمعرّف (LTR)، الخطة والانتهاء، شارة الحالة والدين،
/// وسبب منع الدخول إن وُجد (كما أرسله الخادم).
class LookupTile extends StatelessWidget {
  const LookupTile({super.key, required this.player, required this.onTap});

  final LookupPlayer player;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final m = player.membership;
    final muted = UType.caption(color: c.inkMuted);
    final ids = [player.phone, player.memberCode].whereType<String>();
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.fieldAll,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.s3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: AppSize.controlSm / 2,
                backgroundColor: c.primarySoft,
                child: Text(_initial(player.name), style: UType.label(color: c.primaryInk).weight(600)),
              ),
              AppSpace.gap3,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      style: UType.label(color: c.ink).weight(600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (ids.isNotEmpty)
                      Wrap(
                        spacing: AppSpace.s2,
                        children: [for (final t in ids) LtrText(t, style: muted)],
                      ),
                    if (m?.planName != null)
                      Text(_plan(m!), style: muted, maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (!player.canEnter && player.rejectionMessage != null)
                      Text(player.rejectionMessage!, style: UType.caption(color: c.dangerInk)),
                  ],
                ),
              ),
              AppSpace.gap3,
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _status(m),
                  if (m != null && m.hasDebt) ...[
                    AppSpace.gap1,
                    StatusBadge('دين ${Formatters.usd(m.dueUsd)}', tone: UTone.warning),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _status(LookupMembership? m) {
    if (m == null) return const StatusBadge('بلا اشتراك');
    final spec = Labels.membershipStatus(m.status);
    return StatusBadge(m.statusLabel ?? spec.text, tone: spec.tone);
  }

  static String _plan(LookupMembership m) => [
    m.planName!,
    if (m.endsOn != null) 'حتى ${Formatters.date(m.endsOn)}',
    if (m.sessionsRemaining != null) 'الجلسات المتبقية: ${m.sessionsRemaining}',
  ].join(' · ');

  static String _initial(String name) => name.trim().isEmpty ? '؟' : String.fromCharCode(name.trim().runes.first);
}
