import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// يحرّك كل `ShimmerBox` بداخله. مع "تقليل الحركة" تبقى الهياكل ثابتة.
class AppShimmer extends StatelessWidget {
  const AppShimmer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      label: 'جارٍ التحميل',
      child: Shimmer.fromColors(
        baseColor: c.surfaceAlt,
        highlightColor: c.surface,
        enabled: !AppMotion.reduced(context),
        child: child,
      ),
    );
  }
}

/// مستطيل هيكلي بلون `surfaceAlt`.
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({super.key, this.width, this.height = AppSpace.s4, this.radius = AppRadius.xs});

  /// دائرة (صورة عضو، أيقونة).
  const ShimmerBox.circle({super.key, double size = AppSpace.s10})
      : width = size,
        height = size,
        radius = AppRadius.full;

  final double? width;
  final double height, radius;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: context.colors.surfaceAlt, borderRadius: BorderRadius.circular(radius)),
      );
}

/// بطاقة هيكلية: حدّ فقط بلا تعبئة.
class ShimmerCard extends StatelessWidget {
  const ShimmerCard({super.key, required this.child, this.padding = AppSpace.s5});

  final Widget child;
  final double padding;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(border: Border.all(color: context.colors.line), borderRadius: AppRadius.cardAll),
        child: child,
      );
}
