import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../../core/layout/app_top_bar.dart';
import '../bloc/unread_count_cubit.dart';
import 'notifications_panel.dart';

/// الجرس بالشريط العلوي: عدّاد غير المقروء (فولت) ويفتح قائمة الإشعارات تحته.
/// يحتاج `UnreadCountCubit` أعلاه (يقدّمه `AppShell`).
class NotificationsButton extends StatelessWidget {
  const NotificationsButton({super.key});

  @override
  Widget build(BuildContext context) {
    final count = context.watch<UnreadCountCubit>().state;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Builder(
          builder: (anchor) => TopBarIconButton(
            icon: count > 0 ? Icons.notifications_rounded : Icons.notifications_none_rounded,
            tooltip: count > 0 ? 'الإشعارات، $count غير مقروءة' : 'الإشعارات',
            onPressed: () => _showPanel(anchor),
          ),
        ),
        if (count > 0)
          PositionedDirectional(
            top: -AppSpace.s1,
            end: -AppSpace.s1,
            child: IgnorePointer(child: _CountBadge(count)),
          ),
      ],
    );
  }

  /// قائمة عائمة تحت الجرس (بلا تعتيم)، تُغلق بالضغط خارجها أو Esc أو بعد فتح إشعار.
  static Future<void> _showPanel(BuildContext anchor) {
    final box = anchor.findRenderObject()! as RenderBox;
    final bell = box.localToGlobal(Offset.zero) & box.size;
    final rtl = Directionality.of(anchor) == TextDirection.rtl;
    final count = anchor.read<UnreadCountCubit>();
    return showDialog<void>(
      context: anchor,
      barrierColor: Colors.transparent,
      barrierLabel: 'إغلاق الإشعارات',
      builder: (context) {
        final c = context.colors;
        final screen = MediaQuery.sizeOf(context);
        final width = math.min(AppSize.panel, screen.width - AppSpace.s4 * 2);
        final top = bell.bottom + AppSpace.s2;
        // RTL: الجرس بطرف النهاية (يسار) فتمتد القائمة لليمين من حافته، كما بالنموذج.
        final left = (rtl ? bell.left : bell.right - width).clamp(AppSpace.s4, screen.width - width - AppSpace.s4);
        return Stack(
          children: [
            Positioned(
              top: top,
              left: left,
              width: width,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: screen.height - top - AppSpace.s4),
                child: Material(
                  color: c.surface,
                  elevation: AppSize.floatingElevation,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.cardAll,
                    side: BorderSide(color: c.line),
                  ),
                  child: BlocProvider.value(value: count, child: const NotificationsPanel()),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge(this.count);

  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      constraints: const BoxConstraints(minWidth: AppSize.iconSm, minHeight: AppSize.iconSm),
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.s1),
      alignment: Alignment.center,
      decoration: ShapeDecoration(color: c.accent, shape: const StadiumBorder()),
      child: LtrText(count > 99 ? '99+' : '$count', style: UType.caption(color: c.onAccent).weight(600)),
    );
  }
}
