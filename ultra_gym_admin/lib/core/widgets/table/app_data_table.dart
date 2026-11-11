import 'package:flutter/material.dart';
import 'package:ultragym_design/ultragym_design.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';

/// عمود بالجدول: عنوان + ويدجت الخلية. `width` عرض ثابت، وإلا يتمدد بـ `flex`.
class TableCol<T> {
  const TableCol(this.label, {required this.cell, this.flex = 2, this.width});

  final String label;
  final Widget Function(BuildContext context, T row) cell;
  final int flex;
  final double? width;
}

/// جدول البيانات (`.tbl` بالنموذج): رأس رمادي، صفوف بحد علوي، وضغط الصف يفتح العنصر.
/// أضيق من `minWidth` (التابلت) ← تمرير أفقي بدل ضغط الأعمدة.
class AppDataTable<T> extends StatelessWidget {
  const AppDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.onRowTap,
    this.minWidth = AppSize.tableMin,
  });

  final List<TableCol<T>> columns;
  final List<T> rows;
  final ValueChanged<T>? onRowTap;
  final double minWidth;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final table = _table(context);
      if (box.maxWidth >= minWidth) return table;
      return Scrollbar(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(width: minWidth, child: table),
        ),
      );
    },
  );

  Widget _table(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: c.surfaceAlt,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.s5, vertical: AppSpace.s2),
          child: _cells([
            for (final col in columns)
              Text(
                col.label,
                style: UType.label(color: c.inkMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ]),
        ),
        for (final row in rows) _Row(onTap: onRowTap == null ? null : () => onRowTap!(row), child: _row(context, row)),
      ],
    );
  }

  Widget _row(BuildContext context, T row) => _cells([for (final col in columns) col.cell(context, row)]);

  Widget _cells(List<Widget> cells) => Row(
    children: [
      for (var i = 0; i < columns.length; i++) ...[
        if (i > 0) AppSpace.gap4,
        if (columns[i].width case final w?)
          SizedBox(width: w, child: cells[i])
        else
          Expanded(flex: columns[i].flex, child: cells[i]),
      ],
    ],
  );
}

class _Row extends StatelessWidget {
  const _Row({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          hoverColor: c.bg,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSize.tableRow),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.s5, vertical: AppSpace.s3),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
