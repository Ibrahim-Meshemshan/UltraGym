import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../domain/models/notification_models.dart';
import '../notification_links.dart';

/// سطر إشعار (`SystemStates.html` `.ni`): أيقونة بنغمة النوع، العنوان، النص، والوقت نسبياً.
/// غير المقروء بخلفية برتقالية هادئة.
class NotificationTile extends StatelessWidget {
  const NotificationTile({super.key, required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final n = notification;
    final (icon, tone) = NotificationLinks.look(n);
    final (bg, fg) = tone.colors(c);
    return Material(
      color: n.isRead ? Colors.transparent : c.primarySoft,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: c.line)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.s4, vertical: AppSpace.s3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: AppSize.controlSm,
                height: AppSize.controlSm,
                decoration: BoxDecoration(color: bg, borderRadius: AppRadius.smAll),
                child: Icon(icon, size: AppSize.iconSm, color: fg),
              ),
              AppSpace.gap3,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(n.title, style: UType.label(color: c.ink).weight(600)),
                    if (n.body.isNotEmpty) ...[AppSpace.gap1, Text(n.body, style: UType.caption(color: c.inkMuted))],
                    AppSpace.gap1,
                    Text(
                      Formatters.relative(n.createdAt, now: sl<ServerClock>().now()),
                      style: UType.caption(color: c.inkFaint),
                    ),
                  ],
                ),
              ),
              if (!n.isRead) ...[
                AppSpace.gap2,
                Semantics(
                  label: 'غير مقروء',
                  child: Container(
                    width: AppSpace.s2,
                    height: AppSpace.s2,
                    margin: const EdgeInsets.only(top: AppSpace.s2),
                    decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
