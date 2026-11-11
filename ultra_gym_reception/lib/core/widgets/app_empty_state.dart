import 'package:flutter/material.dart';
import 'package:ultragym_design/ultragym_design.dart';

import '../theme/app_palette.dart';

/// الحالة الفارغة: `EmptyState` الحزمة نفسه (مؤقت + فاصل نبض + عنوان + زر)، لكن الزخرفتان بألوان
/// `AppPalette` لأن الحزمة ترسمهما بألوان الهوية دون معامل. دعوة وليست اعتذاراً.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.icon = Icons.add_rounded,
  });

  final String title, message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;

  /// كما بالحزمة: عرض المحتوى، المؤقت، والفاصل.
  static const _maxWidth = 420.0, _dial = 150.0, _divider = 200.0;

  @override
  Widget build(BuildContext context) {
    final c = UGColors.of(context);
    final orn = AppPalette.of(context).ornaments;
    final action = actionLabel;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxWidth),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TimerDial(size: _dial, colors: orn),
            const SizedBox(height: USpace.s5),
            Text(
              title,
              style: UType.displayMd(color: c.ink),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: USpace.s2),
            PulseDivider(width: _divider, colors: orn),
            const SizedBox(height: USpace.s2),
            Text(
              message,
              style: UType.body(color: c.inkMuted),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: USpace.s5),
              UGButton(label: action, icon: icon, onPressed: onAction ?? () {}),
            ],
          ],
        ),
      ),
    );
  }
}
