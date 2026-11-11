import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:ultragym_design/ultragym_design.dart';

import '../theme/app_tokens.dart';

/// نقاط التجاوب: موبايل < 600 ≤ تابلت < 1024 ≤ كمبيوتر.
abstract final class Breakpoints {
  static const mobile = UBreakpoints.mobile;
  static const tablet = UBreakpoints.tablet;
  static const desktop = UBreakpoints.desktop;
}

extension ResponsiveX on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;

  bool get isMobile => screenWidth < Breakpoints.mobile;
  bool get isTablet => screenWidth >= Breakpoints.mobile && screenWidth < Breakpoints.tablet;
  bool get isDesktop => screenWidth >= Breakpoints.tablet;

  T responsive<T>({required T mobile, T? tablet, T? desktop}) {
    if (isDesktop) return desktop ?? tablet ?? mobile;
    if (isTablet) return tablet ?? mobile;
    return mobile;
  }

  /// هوامش الصفحة: 16 موبايل، 24 غير ذلك.
  EdgeInsets get pagePadding => EdgeInsets.all(isMobile ? AppSpace.s4 : AppSpace.s6);

  double get cardPadding => isMobile ? AppSpace.s4 : AppSpace.s5;

  /// ارتفاع عناصر التحكم: أكبر باللمس.
  double get controlHeight => isMobile ? AppSize.controlLg : AppSize.control;
}

/// شبكة بطاقات: الأعمدة = العرض ÷ `minItemWidth` (بحد `maxColumns`)، بفراغ 12.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minItemWidth = AppSize.gridItem,
    this.maxColumns = 4,
    this.spacing = AppSpace.s3,
  });

  final List<Widget> children;
  final double minItemWidth, spacing;
  final int maxColumns;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final cols = math.max(1, math.min(maxColumns, (box.maxWidth + spacing) ~/ (minItemWidth + spacing)));
      final w = (box.maxWidth - spacing * (cols - 1)) / cols;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [for (final c in children) SizedBox(width: w, child: c)],
      );
    },
  );
}
