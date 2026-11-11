import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../domain/models/check_in_models.dart';

/// بطاقة نتيجة الدخول (`Reception.html`): شريط الحكم بلونه، ثم العضو واشتراكه والدين، و "العضو التالي".
class CheckInCard extends StatelessWidget {
  const CheckInCard(this.result, {super.key, required this.onNext});

  final CheckInResult result;
  final VoidCallback onNext;

  ({UTone tone, IconData icon, String text}) get _verdict {
    final at = Formatters.time(result.record.checkedInAt);
    final session = result.sessionConsumed ? ' · خُصمت جلسة' : '';
    return switch (result.kind) {
      CheckInKind.accepted when result.inGrace => (
        tone: UTone.warning,
        icon: Icons.hourglass_bottom_rounded,
        text: 'مقبول بفترة السماح · تم تسجيل الدخول $at$session',
      ),
      CheckInKind.accepted => (
        tone: UTone.success,
        icon: Icons.check_circle_rounded,
        text: 'مقبول · تم تسجيل الدخول $at$session',
      ),
      CheckInKind.duplicate => (
        tone: UTone.neutral,
        icon: Icons.history_rounded,
        text: '${result.message} · لم يُسجَّل دخول جديد',
      ),
      CheckInKind.rejected => (tone: UTone.danger, icon: Icons.block_rounded, text: 'مرفوض · ${result.message}'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final v = _verdict;
    final (bg, fg) = v.tone.colors(c);
    final m = result.membership;
    return CutCard(
      padding: EdgeInsets.zero,
      child: Semantics(
        liveRegion: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: bg,
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.s6, vertical: AppSpace.s3),
              child: Row(
                spacing: AppSpace.s2,
                children: [
                  Icon(v.icon, color: fg, size: AppSize.iconSm),
                  Expanded(
                    child: Text(v.text, style: UType.body(color: fg).weight(600)),
                  ),
                  if (result.code case final code?) LtrText(code, style: UType.caption(color: fg)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpace.s6),
              child: LayoutBuilder(
                builder: (context, box) {
                  final avatar = InitialsAvatar(result.name, size: AppSize.resultAvatar, large: true);
                  final member = _Member(result: result, membership: m);
                  if (box.maxWidth < AppSize.scanDialog) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: AppSpace.s4,
                      children: [avatar, member],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: AppSpace.s5,
                    children: [
                      avatar,
                      Expanded(child: member),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(AppSpace.s6, 0, AppSpace.s6, AppSpace.s6),
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: UGButton(
                  label: 'العضو التالي',
                  icon: Icons.skip_next_rounded,
                  kind: UButtonKind.ghost,
                  onPressed: onNext,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Member extends StatelessWidget {
  const _Member({required this.result, required this.membership});

  final CheckInResult result;
  final MemberMembership? membership;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final m = membership;
    final ids = [result.memberCode, result.phone].nonNulls.join('  ·  ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpace.s2,
      children: [
        Wrap(
          spacing: AppSpace.s3,
          runSpacing: AppSpace.s1,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(result.name, style: UType.h2(color: c.ink)),
            if (m != null) StatusBadge(m.statusLabel, tone: Labels.membershipStatus(m.status).tone),
          ],
        ),
        if (ids.isNotEmpty) LtrText(ids, style: UType.label(color: c.inkMuted)),
        if (m == null)
          Text('لا اشتراك لهذا العضو.', style: UType.body(color: c.inkMuted))
        else
          LayoutBuilder(
            builder: (context, box) {
              final tiles = [
                _Tile(label: 'الخطة', value: m.planName),
                _Tile(label: m.remaining.label, value: m.remaining.value),
                _Tile(
                  label: 'الدين',
                  value: m.dueUsd > 0 ? Formatters.usd(m.dueUsd) : '—',
                  warn: m.dueUsd > 0,
                  ltr: true,
                ),
              ];
              if (box.maxWidth < AppSize.scanDialog) {
                return Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: AppSpace.s2, children: tiles);
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpace.s3,
                children: [for (final t in tiles) Expanded(child: t)],
              );
            },
          ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.value, this.warn = false, this.ltr = false});

  final String label, value;
  final bool warn, ltr;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = UType.body(color: warn ? c.warningInk : c.ink).weight(600);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.s4, vertical: AppSpace.s3),
      decoration: BoxDecoration(color: warn ? c.warningSoft : c.bg, borderRadius: AppRadius.fieldAll),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: UType.caption(color: c.inkMuted)),
          if (ltr) LtrText(value, style: style) else Text(value, style: style),
        ],
      ),
    );
  }
}
