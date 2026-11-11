import 'package:flutter/material.dart';
import 'package:ultragym_design/ultragym_design.dart';

import '../../bloc/list_cubit.dart';
import '../../networking/paged.dart';
import '../../responsive/responsive.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../shimmers.dart';
import '../slice_view.dart';
import 'app_data_table.dart';
import 'pagination_bar.dart';

/// جدول مقسّم لصفحات = بطاقة فيها الفلاتر (`header`) + `SliceView` + `AppDataTable` + `PaginationBar`.
/// كامل على الكمبيوتر، تمرير أفقي على التابلت، وبطاقات (`mobileItem`) على الموبايل.
/// فارغ بلا فلاتر = `empty` (دعوة)، ومع فلاتر = "لا نتائج" بزر مسح.
class PagedTable<T> extends StatelessWidget {
  const PagedTable({
    super.key,
    required this.state,
    required this.columns,
    required this.onPage,
    required this.onRetry,
    required this.empty,
    this.header,
    this.mobileItem,
    this.onRowTap,
    this.onClearFilters,
    this.noun = 'عنصراً',
    this.minWidth = AppSize.tableMin,
  });

  final ListState<T> state;
  final List<TableCol<T>> columns;
  final ValueChanged<int> onPage;
  final VoidCallback onRetry;
  final Widget empty;
  final Widget? header;
  final Widget Function(BuildContext context, T row)? mobileItem;
  final ValueChanged<T>? onRowTap;
  final VoidCallback? onClearFilters;
  final String noun;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    final filtered = state.query.hasFilters;
    return CutCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null) header!,
          SliceView<Paged<T>>(
            slice: state.slice,
            loading: TableShimmer(rows: 6, columns: context.isMobile ? 2 : columns.length.clamp(2, 6), framed: false),
            onRetry: onRetry,
            frame: (child) => Padding(padding: const EdgeInsets.all(AppSpace.s5), child: child),
            isEmpty: (p) => p.isEmpty,
            empty: Padding(
              padding: const EdgeInsets.all(AppSpace.s5),
              child: filtered ? NoResults(onClear: onClearFilters) : empty,
            ),
            builder: (context, page) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (context.isMobile && mobileItem != null)
                  for (final row in page.items)
                    _MobileRow(onTap: onRowTap == null ? null : () => onRowTap!(row), child: mobileItem!(context, row))
                else
                  AppDataTable<T>(columns: columns, rows: page.items, onRowTap: onRowTap, minWidth: minWidth),
                PaginationBar(pagination: page.pagination, onPage: onPage, noun: noun),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "لا نتائج" مع فلاتر: اقتراح مسحها بدل حالة فارغة عامة.
class NoResults extends StatelessWidget {
  const NoResults({super.key, this.onClear});

  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) => EmptyState(
    icon: Icons.search_off_rounded,
    title: 'لا نتائج مطابقة',
    message: 'جرّب كلمة بحث أخرى أو امسح الفلاتر لعرض الكل.',
    actionLabel: onClear == null ? null : 'مسح الفلاتر',
    onAction: onClear,
  );
}

class _MobileRow extends StatelessWidget {
  const _MobileRow({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border(top: BorderSide(color: context.colors.line)),
    ),
    child: InkWell(
      onTap: onTap,
      child: Padding(padding: const EdgeInsets.all(AppSpace.s4), child: child),
    ),
  );
}
