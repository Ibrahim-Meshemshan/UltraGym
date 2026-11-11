import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../utils/formatters.dart';
import 'filter_controls.dart';

/// حبة فترة ("الفترة: 2026-11-01 → 2026-11-09 ▾") تفتح منتقي فترة. null = بلا فترة (الخادم يطبّق افتراضيه)،
/// و `emptyLabel` يقول ما هو (مثلاً "آخر 31 يوماً"). زر × بالحبة يمسح الفترة.
class FilterDateRange extends StatelessWidget {
  const FilterDateRange({
    super.key,
    required this.from,
    required this.to,
    required this.onChanged,
    this.label = 'الفترة',
    this.emptyLabel = 'الكل',
    this.firstDate,
  });

  final DateTime? from, to;
  final String label, emptyLabel;
  final DateTime? firstDate;

  /// (null, null) = مسح الفترة.
  final void Function(DateTime? from, DateTime? to) onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final active = from != null || to != null;
    final text = active ? '${Formatters.date(from ?? to)} → ${Formatters.date(to ?? from)}' : emptyLabel;
    return FilterPill(
      active: active,
      semanticsLabel: '$label: $text',
      onTap: () => _pick(context),
      children: [
        Text('$label:'),
        Text(text, textDirection: active ? TextDirection.ltr : null),
        if (active)
          Tooltip(
            message: 'مسح الفترة',
            child: InkResponse(
              onTap: () => onChanged(null, null),
              radius: AppSize.iconSm,
              child: Icon(Icons.close_rounded, size: AppSize.iconSm, color: c.inkMuted),
            ),
          )
        else
          Icon(Icons.keyboard_arrow_down_rounded, size: AppSize.iconSm, color: c.inkMuted),
      ],
    );
  }

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final first = firstDate ?? DateTime(now.year - 5);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: first,
      lastDate: today,
      initialDateRange: from == null ? null : DateTimeRange(start: from!, end: to ?? from!),
      helpText: 'اختر الفترة',
      saveText: 'تطبيق',
    );
    if (picked != null) onChanged(picked.start, picked.end);
  }
}
