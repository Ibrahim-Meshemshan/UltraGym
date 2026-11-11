import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../domain/models/training_models.dart';

/// جدول القياسات (الأحدث أولاً): التاريخ، الحقول التسعة (الوحدات بسطر تحته: رأس العمود لا يتسعها)، المؤشر، الملاحظة،
/// وللمالك تعديل وحذف.
/// لا عمود "سجّله": الخادم لا يرسل من سجّل القياس.
class MeasurementsTable extends StatelessWidget {
  const MeasurementsTable({super.key, required this.items, this.onEdit, this.onDelete});

  final List<BodyMeasurement> items;
  final ValueChanged<BodyMeasurement>? onEdit, onDelete;

  static String short(MeasureField f) => switch (f) {
    MeasureField.weight => 'الوزن',
    MeasureField.bodyFat => 'الدهون',
    MeasureField.muscle => 'العضل',
    MeasureField.waist => 'الخصر',
    MeasureField.height => 'الطول',
    MeasureField.chest => 'الصدر',
    MeasureField.hips => 'الورك',
    MeasureField.arm => 'الذراع',
    MeasureField.thigh => 'الفخذ',
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget num(double? v) => Align(
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        v == null ? '—' : Formatters.number(v),
        textDirection: TextDirection.ltr,
        style: UType.body(color: v == null ? c.inkFaint : c.ink),
      ),
    );
    return AppDataTable<BodyMeasurement>(
      minWidth: AppSize.measurementsTableMin,
      rows: items,
      columns: [
        TableCol(
          'التاريخ',
          width: AppSize.ledgerDateCol,
          cell: (_, m) => Text(
            Formatters.date(m.measuredOn),
            textDirection: TextDirection.ltr,
            style: UType.body(color: c.ink),
          ),
        ),
        for (final f in MeasureField.values) TableCol(short(f), flex: 1, cell: (_, m) => num(m[f])),
        TableCol('المؤشر', flex: 1, cell: (_, m) => num(m.bmi)),
        TableCol(
          'ملاحظات',
          cell: (_, m) => Text(
            m.notes ?? '—',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: UType.caption(color: m.notes == null ? c.inkFaint : c.inkMuted),
          ),
        ),
        if (onEdit != null && onDelete != null)
          TableCol(
            '',
            width: AppSize.measureActionsCol,
            cell: (_, m) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(tooltip: 'تعديل القياس', onPressed: () => onEdit!(m), icon: const Icon(Icons.edit_outlined)),
                IconButton(
                  tooltip: 'حذف القياس',
                  color: c.dangerInk,
                  onPressed: () => onDelete!(m),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
