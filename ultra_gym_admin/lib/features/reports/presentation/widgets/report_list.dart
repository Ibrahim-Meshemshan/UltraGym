import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../domain/models/reports_models.dart';

/// "التقارير المتاحة لك" (`.rep`): الاسم والوصف، المحدد بخلفية الفعل وشريط جانبي، وغير المشمول بالباقة بشارة.
class ReportList extends StatelessWidget {
  const ReportList({super.key, required this.reports, required this.selected, required this.onSelect});

  final List<ReportInfo> reports;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return CutCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.s2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.s4, vertical: AppSpace.s2),
            child: Text('التقارير المتاحة لك', style: UType.label(color: c.inkMuted).weight(600)),
          ),
          for (final r in reports) _Tile(r, selected: r.key == selected, onTap: () => onSelect(r.key)),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile(this.report, {required this.selected, required this.onTap});

  final ReportInfo report;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? c.primarySoft : c.surface,
        child: InkWell(
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: BorderDirectional(
                top: BorderSide(color: c.line),
                start: BorderSide(color: selected ? c.primary : c.surface, width: AppSpace.s1),
              ),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppSize.minTap),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.s4, vertical: AppSpace.s3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpace.s1,
                  children: [
                    Text(report.label, style: UType.body(color: c.ink).weight(600)),
                    Text(ReportTexts.description(report.key), style: UType.caption(color: c.inkMuted)),
                    if (!report.available) const StatusBadge('ليس ضمن باقتك', tone: UTone.neutral),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// على الشاشات الضيقة: حبة "التقرير: …" بدل القائمة الجانبية.
class ReportPicker extends StatelessWidget {
  const ReportPicker({super.key, required this.reports, required this.selected, required this.onSelect});

  final List<ReportInfo> reports;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) => FilterMenu<String>(
    label: 'التقرير',
    showAll: false,
    value: selected,
    options: [for (final r in reports) (value: r.key, label: r.label)],
    onChanged: (v) {
      if (v != null) onSelect(v);
    },
  );
}
