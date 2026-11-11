import 'package:flutter/material.dart';
import 'package:ultragym_design/ultragym_design.dart';

import '../../networking/paged.dart';
import '../../responsive/responsive.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../utils/formatters.dart';
import '../on_init.dart';

/// أسفل الجدول: "عرض 1–15 من 1,284 عضوًا" + أزرار الصفحات (السابقة، الأرقام مع …، التالية).
/// بالموبايل: السابقة والتالية فقط بأهداف ضغط 48.
class PaginationBar extends StatelessWidget {
  const PaginationBar({super.key, required this.pagination, required this.onPage, this.noun = 'عنصراً'});

  final Pagination pagination;
  final ValueChanged<int> onPage;

  /// اسم العنصر بعد العدد ("عضوًا").
  final String noun;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final p = pagination;
    final range = p.from == null ? '0' : '${p.from}–${p.to}';
    final mobile = context.isMobile;
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.line)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.s5, vertical: AppSpace.s3),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpace.s3,
        runSpacing: AppSpace.s2,
        children: [
          Text(
            'عرض ${Formatters.ltr(range)} من ${Formatters.ltr(Formatters.number(p.total))} $noun',
            style: UType.label(color: c.inkMuted),
          ),
          if (p.lastPage > 1)
            Semantics(
              container: true,
              label: 'الصفحات',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PageButton(
                    label: '‹',
                    tooltip: 'الصفحة السابقة',
                    big: mobile,
                    onTap: p.currentPage > 1 ? () => onPage(p.currentPage - 1) : null,
                  ),
                  if (mobile)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpace.s3),
                      child: Text(
                        'صفحة ${Formatters.ltr('${p.currentPage}')} من ${Formatters.ltr('${p.lastPage}')}',
                        style: UType.label(color: c.ink),
                      ),
                    )
                  else
                    for (final n in pageWindow(p.currentPage, p.lastPage)) ...[
                      AppSpace.gap1,
                      if (n == null)
                        SizedBox(
                          width: AppSize.pageButton,
                          child: Text(
                            '…',
                            textAlign: TextAlign.center,
                            style: UType.label(color: c.inkMuted),
                          ),
                        )
                      else
                        _PageButton(
                          label: '$n',
                          tooltip: 'الصفحة $n',
                          current: n == p.currentPage,
                          onTap: n == p.currentPage ? null : () => onPage(n),
                        ),
                    ],
                  if (!mobile) AppSpace.gap1,
                  _PageButton(
                    label: '›',
                    tooltip: 'الصفحة التالية',
                    big: mobile,
                    onTap: p.hasMore ? () => onPage(p.currentPage + 1) : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// أرقام الصفحات الظاهرة: الأولى والأخيرة وما حول الحالية، و null مكان الفجوة (…).
List<int?> pageWindow(int current, int last) {
  if (last <= 7) return [for (var i = 1; i <= last; i++) i];
  final from = (current - 1).clamp(2, last - 4);
  final to = (current + 1).clamp(5, last - 1);
  return [1, if (from > 2) null, for (var i = from; i <= to; i++) i, if (to < last - 1) null, last];
}

class _PageButton extends StatelessWidget {
  const _PageButton({required this.label, required this.tooltip, this.onTap, this.current = false, this.big = false});

  final String label, tooltip;
  final VoidCallback? onTap;
  final bool current, big;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final size = big ? AppSize.minTap : AppSize.pageButton;
    final fg = current ? c.surface : (onTap == null ? c.inkFaint : c.ink);
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        selected: current,
        label: tooltip,
        excludeSemantics: true,
        child: Material(
          color: current ? c.ink : c.surface,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.smAll,
            side: BorderSide(color: current ? c.ink : c.line),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.smAll,
            child: SizedBox(
              width: size,
              height: size,
              child: Center(
                child: LtrText(label, style: UType.label(color: fg).weight(current ? 600 : 500)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
