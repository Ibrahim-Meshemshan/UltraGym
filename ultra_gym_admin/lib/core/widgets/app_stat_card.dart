import 'package:flutter/material.dart';
import 'package:ultragym_design/ultragym_design.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// بطاقة الإحصاء: نفس `StatCard` بالحزمة (أيقونة مائلة، رقم يعدّ، سطر تحته) مع `decimals`،
/// لأن المبالغ تُعرض بخانتين (`$20.00`) و `StatCard` يقرّب للعدد الصحيح.
class AppStatCard extends StatelessWidget {
  const AppStatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.prefix = '',
    this.decimals = 0,
    this.note,
    this.noteTone,
    this.onTap,
  });

  final IconData icon;
  final String label, prefix;
  final double value;
  final int decimals;

  /// السطر تحت الرقم ("مجمّدة 1 · بالسماح 1"). بلا `noteTone` يكون باهتاً.
  final String? note;
  final UTone? noteTone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: onTap != null,
      label: label,
      child: CutCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpace.s4),
        child: const SizedBox.shrink(),
        builder: (context, hover, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: UType.label(color: c.inkMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconSlab(icon, size: AppSize.controlSm, active: hover),
              ],
            ),
            AppSpace.gap2,
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: CountUp(
                value,
                prefix: prefix,
                decimals: decimals,
                style: UType.stat(color: c.ink),
              ),
            ),
            if (note != null) ...[
              AppSpace.gap1,
              Text(
                note!,
                style: UType.caption(color: noteTone?.colors(c).$2 ?? c.inkMuted),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
