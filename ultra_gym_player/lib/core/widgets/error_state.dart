import 'package:flutter/material.dart';
import 'package:ultragym_design/ultragym_design.dart';

import '../error/failure.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// خطأ بلا بيانات: ماذا حدث ثم زر إعادة المحاولة. أخطاء الشبكة تعرض حالة "لا اتصال" الموحّدة.
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.failure, this.onRetry, this.compact = false});

  final Failure failure;
  final VoidCallback? onRetry;

  /// داخل بطاقة أو قسم صغير (بلا أيقونة كبيرة).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final offline = failure.isNetwork;
    final (icon, title) = switch (failure.type) {
      _ when offline => (Icons.wifi_off_rounded, 'لا يوجد اتصال'),
      FailureType.notFound => (Icons.search_off_rounded, 'غير موجود'),
      FailureType.forbidden || FailureType.branchForbidden => (Icons.lock_outline_rounded, 'لا تملك الصلاحية'),
      FailureType.featureNotAvailable => (Icons.workspace_premium_outlined, 'غير متاح بباقتك'),
      FailureType.maintenance => (Icons.construction_rounded, 'النظام تحت الصيانة'),
      _ => (Icons.error_outline_rounded, 'تعذّر التحميل'),
    };
    final canRetry = onRetry != null && failure.type != FailureType.notFound && failure.type != FailureType.forbidden;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.s6),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (!compact) ...[
              Container(
                width: AppSpace.s16,
                height: AppSpace.s16,
                decoration: BoxDecoration(color: offline ? c.infoSoft : c.dangerSoft, shape: BoxShape.circle),
                child: Icon(icon, color: offline ? c.infoInk : c.dangerInk, size: AppSpace.s8),
              ),
              AppSpace.gap4,
            ],
            Text(title, style: UType.h3(color: c.ink), textAlign: TextAlign.center),
            AppSpace.gap2,
            Text(failure.message, style: UType.body(color: c.inkMuted), textAlign: TextAlign.center),
            if (canRetry) ...[
              AppSpace.gap5,
              UGButton(label: 'إعادة المحاولة', icon: Icons.refresh_rounded, kind: UButtonKind.secondary, onPressed: onRetry),
            ],
          ]),
        ),
      ),
    );
  }
}
