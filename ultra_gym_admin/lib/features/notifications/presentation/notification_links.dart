import 'package:flutter/material.dart';

import '../../../core/core.dart';
import '../domain/models/notification_models.dart';

/// أين يفتح الإشعار وبأي أيقونة ونغمة (خريطة `screen` ← الشاشة بتوثيق الباك اند).
/// الأقسام غير المبنية تفتح `PendingSection` حتى تُبنى، والقسم الممنوع يعيده الحارس للرئيسية.
abstract final class NotificationLinks {
  /// null = لا شيء يُفتح (`screen = none` أو شاشة لا تخص هذه اللوحة).
  static String? route(AppNotification n) {
    String at(String base, String key) => switch (n.ref(key)) {
      final id? => Routes.child(base, id),
      null => base,
    };
    return switch (n.screen) {
      'membership' => at(Routes.memberships, 'membership_id'),
      'memberships' => Routes.memberships,
      'player' => at(Routes.members, 'player_id'),
      // الحركات والإيصالات: دفتر الحركات بقسم "الصندوق والحركات"
      'payment' || 'transaction' => Routes.transactions,
      'cash_session' => at(Routes.cashSessions, 'cash_session_id'),
      'day_pass' => at(Routes.dayPasses, 'day_pass_id'),
      'reception_sync' || 'reception_devices' => Routes.receptionDevices,
      'billing_invoice' => switch (n.ref('invoice_id')) {
        final id? => Routes.billingInvoice(id),
        null => Routes.billing,
      },
      'support_ticket' => switch (n.ref('ticket_id')) {
        final id? => Routes.supportTicket(id),
        null => Routes.billingSupport,
      },
      'billing' => Routes.billing,
      _ => null,
    };
  }

  /// أيقونة الإشعار ونغمتها حسب نوعه (`SystemStates.html`: دفعة خضراء، صندوق عنبري، عكس أحمر...).
  static (IconData, UTone) look(AppNotification n) => switch (n.type) {
    'club_new_member' => (Icons.person_add_alt_rounded, UTone.accent),
    'club_membership_sold' ||
    'club_debt_payment' ||
    'club_income' ||
    'club_day_pass_sold' ||
    'billing_payment' => (Icons.payments_rounded, UTone.success),
    'club_membership_frozen' => (Icons.ac_unit_rounded, UTone.info),
    'club_membership_cancelled' => (Icons.block_rounded, UTone.neutral),
    'club_expense' => (Icons.north_east_rounded, UTone.danger),
    'club_reversal' => (Icons.undo_rounded, UTone.danger),
    'club_cash_closed' => (Icons.point_of_sale_rounded, UTone.info),
    'club_cash_left_open' => (Icons.point_of_sale_rounded, UTone.warning),
    'club_daily_summary' => (Icons.bar_chart_rounded, UTone.info),
    'club_sync_rejected' => (Icons.sync_problem_rounded, UTone.danger),
    'club_device_registered' => (Icons.devices_rounded, UTone.info),
    'billing_invoice' => (Icons.receipt_long_rounded, UTone.info),
    'billing_overdue' || 'subscription_locked' || 'tenant_suspended' => (Icons.lock_clock_rounded, UTone.danger),
    'subscription_expiring' ||
    'subscription_grace' ||
    'subscription_expired' ||
    'plan_limit' => (Icons.warning_amber_rounded, UTone.warning),
    'tenant_activated' => (Icons.verified_rounded, UTone.success),
    'support_ticket' => (Icons.support_agent_rounded, UTone.info),
    _ => (Icons.notifications_rounded, UTone.neutral),
  };
}
