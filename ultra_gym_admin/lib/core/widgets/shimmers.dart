import 'package:flutter/material.dart';

import '../responsive/responsive.dart';
import '../theme/app_tokens.dart';
import 'app_shimmer.dart';

/// هيكل قائمة: صفوف بصورة دائرية وسطرين.
class ListShimmer extends StatelessWidget {
  const ListShimmer({super.key, this.count = 6});

  final int count;

  @override
  Widget build(BuildContext context) => AppShimmer(
    child: Column(
      children: [
        for (var i = 0; i < count; i++)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpace.s3),
            child: Row(
              children: [
                ShimmerBox.circle(),
                AppSpace.gap3,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(width: 160),
                      AppSpace.gap2,
                      ShimmerBox(width: 100, height: AppSpace.s3),
                    ],
                  ),
                ),
                ShimmerBox(width: 64, height: AppSpace.s6, radius: AppRadius.full),
              ],
            ),
          ),
      ],
    ),
  );
}

/// هيكل جدول: رأس + صفوف بارتفاع صف الجدول. `framed: false` داخل بطاقة موجودة (`PagedTable`).
class TableShimmer extends StatelessWidget {
  const TableShimmer({super.key, this.rows = 8, this.columns = 5, this.framed = true});

  final int rows, columns;
  final bool framed;

  @override
  Widget build(BuildContext context) => AppShimmer(
    child: _frame(
      Column(
        children: [
          for (var r = 0; r <= rows; r++)
            SizedBox(
              height: AppSize.tableRow,
              child: Row(
                children: [
                  for (var c = 0; c < columns; c++) ...[
                    Expanded(
                      flex: c == 0 ? 2 : 1,
                      child: ShimmerBox(height: r == 0 ? AppSpace.s3 : AppSpace.s4),
                    ),
                    if (c < columns - 1) AppSpace.gap4,
                  ],
                ],
              ),
            ),
        ],
      ),
    ),
  );

  Widget _frame(Widget child) => framed
      ? ShimmerCard(padding: AppSpace.s4, child: child)
      : Padding(padding: const EdgeInsets.all(AppSpace.s4), child: child);
}

/// هيكل بطاقات الإحصاء بالشبكة.
class StatsShimmer extends StatelessWidget {
  const StatsShimmer({super.key, this.count = 4});

  final int count;

  @override
  Widget build(BuildContext context) => AppShimmer(
    child: ResponsiveGrid(
      children: [
        for (var i = 0; i < count; i++)
          const ShimmerCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: AppSpace.s10, height: AppSpace.s10, radius: AppRadius.sm),
                AppSpace.gap4,
                ShimmerBox(width: 90, height: AppSpace.s8),
                AppSpace.gap2,
                ShimmerBox(width: 120, height: AppSpace.s3),
              ],
            ),
          ),
      ],
    ),
  );
}

/// هيكل تفاصيل: عنوان + أسطر معلومات.
class DetailsShimmer extends StatelessWidget {
  const DetailsShimmer({super.key, this.lines = 6});

  final int lines;

  @override
  Widget build(BuildContext context) => AppShimmer(
    child: ShimmerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerBox(width: 200, height: AppSpace.s6),
          AppSpace.gap5,
          for (var i = 0; i < lines; i++) ...[
            const Row(
              children: [
                ShimmerBox(width: 90),
                AppSpace.gap4,
                Expanded(child: ShimmerBox()),
              ],
            ),
            AppSpace.gap4,
          ],
        ],
      ),
    ),
  );
}
