import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../bloc/branch_scope_cubit.dart';

/// حالة الصندوق بالشريط العلوي (`Dashboard.html`: "الصندوق: 1 من 2 مفتوح").
/// من `cash_session_open` لكل فرع (لا حساب محلي). مفتوح = فولت (مباشر)، مغلق = تحذير. الضغط يفتح الصندوق.
class CashStatusBadge extends StatelessWidget {
  const CashStatusBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<BranchScopeCubit>().state;
    if (!s.branches.hasData || s.active.isEmpty) return const SizedBox.shrink();
    final (text, tone) = label(s);
    return Tooltip(
      message: 'الصندوق والورديات',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () => context.go(Routes.cashSessions),
          customBorder: const StadiumBorder(),
          child: StatusBadge(text, tone: tone),
        ),
      ),
    );
  }

  /// النص واللون حسب الفرع المختار أو كل الفروع.
  static (String, UTone) label(BranchScope s) {
    final one = s.selected;
    if (one != null) return one.cashSessionOpen ? ('الصندوق مفتوح', UTone.accent) : ('الصندوق مغلق', UTone.warning);
    final open = s.openCashCount;
    if (open == 0) return ('الصندوق مغلق بكل الفروع', UTone.warning);
    return ('الصندوق: $open من ${s.active.length} مفتوح', UTone.accent);
  }
}
