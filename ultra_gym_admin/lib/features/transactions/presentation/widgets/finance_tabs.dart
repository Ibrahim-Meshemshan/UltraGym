import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';

/// تبويبات قسم "الصندوق والحركات" (`أقسام المالية` بالنموذج): الورديات، دفتر الحركات، سعر الصرف، التصنيفات.
/// تمرير أفقي إن ضاق العرض.
class FinanceTabs extends StatelessWidget {
  const FinanceTabs({super.key, required this.selected});

  /// 0 الورديات، 1 دفتر الحركات، 2 سعر الصرف، 3 التصنيفات.
  final int selected;

  static const _routes = [Routes.cashSessions, Routes.transactions, Routes.exchangeRate, Routes.financeCategories];

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      // آخر تبويبين: يبدأ التمرير من النهاية فيبقى المحدد ظاهراً على الموبايل.
      reverse: selected > 1,
      child: AppTabs(
        tabs: const [
          (label: 'الورديات', count: null),
          (label: 'دفتر الحركات', count: null),
          (label: 'سعر الصرف', count: null),
          (label: 'التصنيفات', count: null),
        ],
        selected: selected,
        onSelect: (i) {
          if (i != selected) context.go(_routes[i]);
        },
      ),
    ),
  );
}
