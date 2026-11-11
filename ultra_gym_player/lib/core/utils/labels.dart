import 'package:flutter/material.dart';
import 'package:ultragym_design/ultragym_design.dart';

/// نص + نغمة شارة + أيقونة لقيمة ثابتة من الـ API.
typedef LabelSpec = ({String text, UTone tone, IconData icon});

/// ترجمة قيم الـ API الثابتة بمكان واحد (والمصطلحات ثابتة بكل الواجهات).
/// إن أرجع الخادم `status_label` فاعرضه هو، واستعمل `tone` من هنا فقط.
abstract final class Labels {
  static const _unknown = (text: '—', tone: UTone.neutral, icon: Icons.help_outline_rounded);

  static LabelSpec membershipStatus(String? status) => switch (status) {
        'active' => (text: 'فعّال', tone: UTone.success, icon: Icons.check_circle_rounded),
        'grace' => (text: 'بفترة السماح', tone: UTone.warning, icon: Icons.hourglass_bottom_rounded),
        'frozen' => (text: 'مجمّد', tone: UTone.info, icon: Icons.ac_unit_rounded),
        'upcoming' => (text: 'لم يبدأ', tone: UTone.info, icon: Icons.schedule_rounded),
        'expired' => (text: 'منتهٍ', tone: UTone.danger, icon: Icons.event_busy_rounded),
        'cancelled' => (text: 'ملغى', tone: UTone.neutral, icon: Icons.block_rounded),
        _ => _unknown,
      };

  static LabelSpec attendance(String? status, {bool inGrace = false}) => switch (status) {
        'accepted' when inGrace => (text: 'مقبول بالسماح', tone: UTone.warning, icon: Icons.login_rounded),
        'accepted' => (text: 'مقبول', tone: UTone.success, icon: Icons.login_rounded),
        'rejected' => (text: 'مرفوض', tone: UTone.danger, icon: Icons.do_not_disturb_on_rounded),
        _ => _unknown,
      };

  static LabelSpec direction(String? direction, {bool reversed = false}) => reversed
      ? (text: 'معكوسة', tone: UTone.neutral, icon: Icons.undo_rounded)
      : switch (direction) {
          'in' => (text: 'وارد', tone: UTone.success, icon: Icons.south_west_rounded),
          'out' => (text: 'صادر', tone: UTone.danger, icon: Icons.north_east_rounded),
          _ => _unknown,
        };

  static LabelSpec cashSession(String? status) => switch (status) {
        'open' => (text: 'مفتوح', tone: UTone.accent, icon: Icons.point_of_sale_rounded),
        'closed' => (text: 'مغلق', tone: UTone.neutral, icon: Icons.lock_rounded),
        _ => _unknown,
      };

  /// فرق الجرد: السالب نقص (خطر)، والموجب زيادة (تنبيه).
  static UTone difference(num? v) => v == null || v == 0 ? UTone.success : (v < 0 ? UTone.danger : UTone.warning);

  static LabelSpec tenantSubscription(String? status) => switch (status) {
        'trial' => (text: 'تجريبي', tone: UTone.accent, icon: Icons.science_rounded),
        'active' => (text: 'فعّال', tone: UTone.success, icon: Icons.verified_rounded),
        'grace' => (text: 'فترة سماح', tone: UTone.warning, icon: Icons.hourglass_bottom_rounded),
        'expired' => (text: 'منتهٍ (قراءة فقط)', tone: UTone.warning, icon: Icons.visibility_rounded),
        'locked' => (text: 'مقفل', tone: UTone.danger, icon: Icons.lock_rounded),
        'suspended' => (text: 'موقوف', tone: UTone.danger, icon: Icons.pause_circle_rounded),
        'cancelled' => (text: 'ملغى', tone: UTone.neutral, icon: Icons.block_rounded),
        _ => _unknown,
      };

  static LabelSpec invoice(String? status, {bool overdue = false}) => overdue
      ? (text: 'متأخرة', tone: UTone.danger, icon: Icons.warning_amber_rounded)
      : switch (status) {
          'pending' => (text: 'بانتظار الدفع', tone: UTone.info, icon: Icons.receipt_long_rounded),
          'partially_paid' => (text: 'مدفوعة جزئياً', tone: UTone.warning, icon: Icons.timelapse_rounded),
          'paid' => (text: 'مدفوعة', tone: UTone.success, icon: Icons.task_alt_rounded),
          'cancelled' => (text: 'ملغاة', tone: UTone.neutral, icon: Icons.block_rounded),
          'refunded' => (text: 'مستردة', tone: UTone.neutral, icon: Icons.undo_rounded),
          _ => _unknown,
        };

  /// مستوى تنبيهات تطبيق العضو.
  static UTone alertLevel(String? level) => switch (level) {
        'danger' => UTone.danger,
        'warning' => UTone.warning,
        _ => UTone.info,
      };

  static LabelSpec role(String? role) => switch (role) {
        'club_owner' => (text: 'مالك النادي', tone: UTone.primary, icon: Icons.workspace_premium_rounded),
        'receptionist' => (text: 'استقبال', tone: UTone.info, icon: Icons.badge_rounded),
        'player' => (text: 'عضو', tone: UTone.neutral, icon: Icons.person_rounded),
        'owner' => (text: 'مالك المنصة', tone: UTone.primary, icon: Icons.workspace_premium_rounded),
        'admin' => (text: 'مشرف', tone: UTone.info, icon: Icons.shield_rounded),
        _ => _unknown,
      };

  static String gender(String? g) => switch (g) {
        'male' => 'ذكور',
        'female' => 'إناث',
        'mixed' => 'مختلط',
        _ => '—',
      };

  static String currency(String? c) => switch (c?.toUpperCase()) {
        'USD' => 'دولار',
        'SYP' => 'ليرة سورية',
        _ => '—',
      };
}
