import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../domain/models/reports_models.dart';
import 'report_bars.dart';

/// عارض أي تقرير: العنوان والفترة، بطاقات الملخص (نصوص الخادم كما هي)، الرسم إن وُجد، ثم جدول لكل قسم،
/// وصفحات التقارير المقسّمة (الديون والمنتهية).
class ReportBody extends StatelessWidget {
  const ReportBody({super.key, required this.report, required this.onPage, required this.canExport});

  final ReportResult report;
  final ValueChanged<int> onPage;
  final bool canExport;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final r = report;
    final chart = ReportTexts.chart(r);
    final pag = r.pagination;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.s4,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(header: true, child: Text(r.title, style: UType.h2(color: c.ink))),
            Text(r.subtitle, style: UType.label(color: c.inkMuted)),
          ],
        ),
        if (r.summary.isNotEmpty)
          ResponsiveGrid(
            minItemWidth: AppSize.reportSummaryMin,
            maxColumns: 5,
            spacing: AppSpace.s3,
            children: [for (final s in r.summary) _SummaryTile(s.label, s.value)],
          ),
        if (chart != null && chart.bars.isNotEmpty)
          ReportBars(
            title: chart.title,
            bars: chart.bars,
            format: r.key == 'daily_cash' ? Formatters.usd : Formatters.number,
          ),
        for (final s in r.sections) _SectionCard(s),
        if (pag != null && pag.lastPage > 1) PaginationBar(pagination: pag, onPage: onPage, noun: 'اشتراكاً'),
        if (canExport)
          Text(
            'في PDF يُعرض أول 2000 صف من كل قسم؛ للبيانات الكاملة صدّر Excel.',
            style: UType.caption(color: c.inkMuted),
          ),
      ],
    );
  }
}

/// بطاقة ملخص: التسمية فوق القيمة (`.stat`). القيمة السالبة بلون الخطر.
class _SummaryTile extends StatelessWidget {
  const _SummaryTile(this.label, this.value);

  final String label, value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return CutCard(
      padding: const EdgeInsets.all(AppSpace.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpace.s1,
        children: [
          Text(label, style: UType.label(color: c.inkMuted), maxLines: 2, overflow: TextOverflow.ellipsis),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: LtrText(value, style: UType.h2(color: value.startsWith('-') ? c.dangerInk : c.ink)),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard(this.section);

  final ReportSection section;

  static String _text(Object? v) => switch (v) {
    null => '—',
    final num n => Formatters.number(n),
    _ => '$v',
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = section;
    return CutCard(
      padding: const EdgeInsets.all(AppSpace.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.s3,
        children: [
          Semantics(header: true, child: Text(s.title, style: UType.h3(color: c.ink))),
          if (s.rows.isEmpty)
            Text('لا بيانات بهذه الفترة.', style: UType.label(color: c.inkMuted))
          else
            AppDataTable<List<Object?>>(
              minWidth: s.columns.length * AppSize.reportColMin,
              rows: s.rows,
              columns: [
                for (var i = 0; i < s.columns.length; i++)
                  TableCol(
                    s.columns[i],
                    flex: s.numeric.contains(i) ? 2 : 3,
                    cell: (context, row) {
                      final v = _text(i < row.length ? row[i] : null);
                      if (!s.numeric.contains(i)) return Text(v, style: UType.body(color: c.ink));
                      return Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: LtrText(v, style: UType.body(color: v.startsWith('-') ? c.dangerInk : c.ink)),
                      );
                    },
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
