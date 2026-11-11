import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../domain/models/cash_session_models.dart';
import 'cash_session_panels.dart';

/// بطاقة وردية (`CashSessions.html`): الرقم والحالة ومن فتحها، الأفعال، ثم لوحتا العملتين و "حسب النوع".
/// نفسها للوردية المفتوحة بالصفحة الرئيسية ولصفحة التفاصيل (المغلقة تعرض الجرد والفرق).
class CashSessionCard extends StatelessWidget {
  const CashSessionCard({
    super.key,
    required this.session,
    this.showBranch = false,
    this.onReport,
    this.onRecord,
    this.onClose,
  });

  final CashSession session;

  /// اسم الفرع بالعنوان (أكثر من صندوق بالصفحة، أو صفحة التفاصيل).
  final bool showBranch;

  /// `onRecord`: "مصروف أو إيراد" بصندوق هذه الوردية (المفتوحة فقط).
  final VoidCallback? onReport, onRecord, onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = session;
    final actions = Wrap(
      spacing: AppSpace.s2,
      runSpacing: AppSpace.s2,
      children: [
        if (onReport != null)
          UGButton(
            label: 'تقرير الوردية',
            icon: Icons.download_rounded,
            kind: UButtonKind.secondary,
            onPressed: onReport,
          ),
        if (s.isOpen && onRecord != null)
          UGButton(
            label: 'مصروف أو إيراد',
            icon: Icons.add_card_rounded,
            kind: UButtonKind.secondary,
            onPressed: onRecord,
          ),
        if (s.isOpen && onClose != null)
          UGButton(label: 'إغلاق الوردية بالجرد', icon: Icons.lock_rounded, onPressed: onClose),
      ],
    );
    return CutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.s4,
        children: [
          LayoutBuilder(
            builder: (context, box) => box.maxWidth >= AppSize.splitMin
                ? Row(
                    spacing: AppSpace.s4,
                    children: [
                      Expanded(child: _Title(s, showBranch: showBranch)),
                      actions,
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: AppSpace.s3,
                    children: [
                      _Title(s, showBranch: showBranch),
                      actions,
                    ],
                  ),
          ),
          ResponsiveGrid(
            maxColumns: 3,
            children: [
              CashCurrencyPanel(session: s, usd: true),
              CashCurrencyPanel(session: s, usd: false),
              CashBreakdownPanel(lines: s.breakdown),
            ],
          ),
          if (s.notes case final notes?) Text('ملاحظات: $notes', style: UType.label(color: c.inkMuted)),
          if (s.isOpen)
            Text(
              'كل عملة تُحسب وحدها لأن الدرج فيه دولار وليرة فعلياً. وردية واحدة مفتوحة لكل فرع.',
              style: UType.caption(color: c.inkMuted),
            ),
        ],
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.s, {required this.showBranch});

  final CashSession s;
  final bool showBranch;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = CashSessionLabels.status(s.status);
    final muted = UType.label(color: c.inkMuted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpace.s1,
      children: [
        Wrap(
          spacing: AppSpace.s2,
          runSpacing: AppSpace.s1,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Semantics(
              header: true,
              child: Text(
                'الوردية ${Formatters.ltr('#${s.id}')}${showBranch && s.branchName != null ? ' · ${s.branchName}' : ''}',
                style: UType.h3(color: c.ink),
              ),
            ),
            StatusBadge(l.text, tone: l.tone),
          ],
        ),
        Text(
          [
            if (s.openedBy != null) 'فتحها ${s.openedBy} ${Formatters.ltr(Formatters.dateTime(s.openedAt))}',
            if (s.businessDate != null) 'يوم العمل ${Formatters.ltr(Formatters.date(s.businessDate))}',
            if (s.breakdown.isNotEmpty)
              Formatters.count(s.transactionsCount, 'حركة واحدة', 'حركتان', 'حركات', many: 'حركة'),
          ].join(' · '),
          style: muted,
        ),
        if (!s.isOpen && s.closedAt != null)
          Text('أغلقها ${s.closedBy ?? '—'} ${Formatters.ltr(Formatters.dateTime(s.closedAt))}', style: muted),
      ],
    );
  }
}
