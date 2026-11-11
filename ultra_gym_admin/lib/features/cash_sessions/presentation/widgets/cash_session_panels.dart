import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../domain/models/cash_session_models.dart';

/// لوحة عملة واحدة (`CashSessions.html`): الافتتاحي، الداخل، الخارج، المتوقع بالدرج؛ وللمغلقة الجرد والفرق.
/// كل عملة تُحسب وحدها لأن الدرج فيه الدولار والليرة فعلياً.
class CashCurrencyPanel extends StatelessWidget {
  const CashCurrencyPanel({super.key, required this.session, required this.usd});

  final CashSession session;
  final bool usd;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = session;
    final t = s.totals;
    String money(num? v) => usd ? Formatters.usd(v) : Formatters.syp(v);
    final difference = usd ? s.differenceUsd : s.differenceSyp;
    return _Panel(
      title: usd ? 'دولار · USD' : 'ليرة · SYP',
      children: [
        _Line('الافتتاحي', money(usd ? s.openingUsd : s.openingSyp)),
        if (t != null) ...[
          _signed('الداخل', usd ? t.inUsd : t.inSyp, sign: '+', color: c.successInk, money: money),
          _signed('الخارج', usd ? t.outUsd : t.outSyp, sign: '−', color: c.dangerInk, money: money),
        ],
        _Line(
          s.isOpen ? 'المتوقع بالدرج الآن' : 'المتوقع',
          money(usd ? s.expectedUsdNow : s.expectedSypNow),
          strong: true,
        ),
        if (!s.isOpen) ...[
          _Line('الجرد', money(usd ? s.closingUsd : s.closingSyp)),
          Row(
            children: [
              Expanded(
                child: Text('الفرق', style: UType.label(color: c.inkMuted)),
              ),
              CashDifferenceBadge(difference, usd: usd),
            ],
          ),
        ],
      ],
    );
  }

  /// الداخل والخارج بإشارتهما ولونهما؛ الصفر بلا إشارة ولا لون.
  static Widget _signed(
    String label,
    double v, {
    required String sign,
    required Color color,
    required String Function(num?) money,
  }) => v == 0 ? _Line(label, money(0)) : _Line(label, '$sign${money(v)}', color: color);
}

/// "حسب النوع": كل نوع حركة بعملته وعدده، الداخل بالأخضر والخارج بالأحمر.
class CashBreakdownPanel extends StatelessWidget {
  const CashBreakdownPanel({super.key, required this.lines});

  final List<CashBreakdownLine> lines;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _Panel(
      title: 'حسب النوع',
      children: [
        if (lines.isEmpty) Text('لا حركات بهذه الوردية بعد.', style: UType.label(color: c.inkMuted)),
        for (final l in lines)
          _Line(
            '${l.label} · ${l.count}',
            '${l.isIn ? '+' : '−'}${Formatters.money(l.total, l.currency)}',
            color: l.isIn ? c.successInk : c.dangerInk,
          ),
      ],
    );
  }
}

/// فرق الجرد كشارة: "مطابق" / "عجز −$3.00" / "زيادة +5,000 ل.س". `compact` (أعمدة الجدول): المبلغ بإشارته
/// فقط، ويصغر إن ضاق العمود.
class CashDifferenceBadge extends StatelessWidget {
  const CashDifferenceBadge(this.value, {super.key, required this.usd, this.compact = false});

  final double? value;
  final bool usd, compact;

  @override
  Widget build(BuildContext context) {
    final v = value;
    final word = CashSessionLabels.difference(v);
    if (v == null || v == 0) return StatusBadge(word, tone: Labels.difference(v));
    final amount = Formatters.ltr('${v < 0 ? '−' : '+'}${usd ? Formatters.usd(v.abs()) : Formatters.syp(v.abs())}');
    final badge = StatusBadge(compact ? amount : '$word $amount', tone: Labels.difference(v));
    if (!compact) return badge;
    return Semantics(
      label: '$word $amount',
      child: FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart, child: badge),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpace.s4),
      decoration: BoxDecoration(color: c.surfaceAlt, borderRadius: AppRadius.fieldAll),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.s2,
        children: [
          Text(title, style: UType.label(color: c.ink).weight(600)),
          ...children,
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value, {this.color, this.strong = false});

  final String label, value;
  final Color? color;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final labelStyle = strong ? UType.label(color: c.ink).weight(600) : UType.label(color: c.inkMuted);
    final valueStyle = UType.body(color: color ?? c.ink).weight(strong ? 700 : 500);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label, style: labelStyle)),
        AppSpace.gap2,
        LtrText(value, style: valueStyle),
      ],
    );
  }
}
