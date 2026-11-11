import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../domain/models/dashboard_models.dart';

/// الصناديق: وردية لكل فرع. المفتوح برقم ورديته ووقت فتحه ورصيده المتوقع (للمالك)، والمغلق بزر "فتح الصندوق".
class CashBoxesCard extends StatelessWidget {
  const CashBoxesCard({super.key, required this.boxes});

  final List<CashBox> boxes;

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'الصناديق',
    action: 'كل الورديات',
    onAction: () => context.go(Routes.cashSessions),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < boxes.length; i++) ...[
          if (i > 0) Divider(height: AppSpace.s6, color: context.colors.line),
          _Box(box: boxes[i]),
        ],
      ],
    ),
  );
}

class _Box extends StatelessWidget {
  const _Box({required this.box});

  final CashBox box;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final b = box;
    final spec = Labels.cashSession(b.isOpen ? 'open' : 'closed');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                b.branchName,
                style: UType.label(color: c.ink),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            AppSpace.gap2,
            StatusBadge(spec.text, tone: spec.tone),
          ],
        ),
        AppSpace.gap1,
        Text(_info(b), style: UType.caption(color: c.inkMuted)),
        if (b.hasBalance) ...[
          AppSpace.gap3,
          Row(
            children: [
              Expanded(
                child: _Amount(label: 'المتوقع بالدولار', value: Formatters.usd(b.expectedUsd)),
              ),
              AppSpace.gap2,
              Expanded(
                child: _Amount(label: 'المتوقع بالليرة', value: Formatters.syp(b.expectedSyp)),
              ),
            ],
          ),
        ],
        if (!b.isOpen) ...[
          AppSpace.gap3,
          UGButton(label: 'فتح الصندوق', kind: UButtonKind.secondary, onPressed: () => context.go(Routes.cashSessions)),
        ],
      ],
    );
  }

  /// "وردية #2 · فُتحت 09:00" لوردية اليوم، وبالتاريخ لوردية أقدم.
  static String _info(CashBox b) {
    if (!b.isOpen) return 'لا وردية مفتوحة بهذا الفرع';
    final at = b.openedAt;
    final sameDay =
        at != null && Formatters.date(at, fromUtc: true) == Formatters.date(sl<ServerClock>().now(), fromUtc: true);
    final when = at == null ? null : (sameDay ? Formatters.time(at) : Formatters.dateTime(at));
    return [
      if (b.sessionId != null) 'وردية ${Formatters.ltr('#${b.sessionId}')}',
      if (when != null) 'فُتحت ${Formatters.ltr(when)}',
    ].join(' · ');
  }
}

class _Amount extends StatelessWidget {
  const _Amount({required this.label, required this.value});

  final String label, value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.s3, vertical: AppSpace.s2),
      decoration: BoxDecoration(color: c.bg, borderRadius: AppRadius.smAll),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: UType.caption(color: c.inkMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: LtrText(value, style: UType.label(color: c.ink)),
          ),
        ],
      ),
    );
  }
}
