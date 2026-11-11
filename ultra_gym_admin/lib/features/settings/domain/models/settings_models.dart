import '../../../../core/core.dart';

/// إعدادات التشغيل كما بـ `settings` في `GET club-admin/club` (`ClubSettings::payload`).
class ClubSettings extends Equatable {
  const ClubSettings({
    this.timezone = 'Asia/Damascus',
    this.weekStartDay = 'saturday',
    this.weekendDays = const ['friday'],
    this.businessDayEndsAt = 2,
    this.graceDays = 0,
    this.defaultMaxFreezes = 0,
    this.defaultMaxFreezeDays = 0,
    this.duplicateCheckInMinutes = 0,
    this.allowPartialPayment = true,
    this.receiptFooter,
    this.expiryReminders = true,
    this.disabledNotifications = const [],
    this.dayPassEnabled = false,
    this.dayPassPriceUsd,
    this.playerWorkoutsEnabled = false,
  });

  factory ClubSettings.fromJson(Json j) => ClubSettings(
    timezone: j.str('timezone', 'Asia/Damascus'),
    weekStartDay: j.str('week_start_day', 'saturday'),
    weekendDays: j.strList('weekend_days'),
    businessDayEndsAt: j.intv('business_day_ends_at_hour', 2),
    graceDays: j.intv('membership_grace_days'),
    defaultMaxFreezes: j.intv('default_max_freezes'),
    defaultMaxFreezeDays: j.intv('default_max_freeze_days'),
    duplicateCheckInMinutes: j.intv('duplicate_check_in_minutes'),
    allowPartialPayment: j.flag('allow_partial_payment', true),
    receiptFooter: j.strOrNull('receipt_footer'),
    expiryReminders: j.flag('expiry_reminders_enabled', true),
    disabledNotifications: j.strList('disabled_notifications'),
    dayPassEnabled: j.flag('day_pass_enabled'),
    dayPassPriceUsd: j.dblOrNull('day_pass_price_usd'),
    playerWorkoutsEnabled: j.flag('player_workouts_enabled'),
  );

  final String timezone, weekStartDay;
  final List<String> weekendDays;

  /// ساعة نهاية يوم العمل (0–6): ما قبلها يُحسب على اليوم السابق.
  final int businessDayEndsAt;
  final int graceDays, defaultMaxFreezes, defaultMaxFreezeDays, duplicateCheckInMinutes;
  final bool allowPartialPayment, expiryReminders, dayPassEnabled, playerWorkoutsEnabled;
  final String? receiptFooter;
  final List<String> disabledNotifications;
  final double? dayPassPriceUsd;

  @override
  List<Object?> get props => [
    timezone,
    weekStartDay,
    weekendDays,
    businessDayEndsAt,
    graceDays,
    defaultMaxFreezes,
    defaultMaxFreezeDays,
    duplicateCheckInMinutes,
    allowPartialPayment,
    receiptFooter,
    expiryReminders,
    disabledNotifications,
    dayPassEnabled,
    dayPassPriceUsd,
    playerWorkoutsEnabled,
  ];
}

/// ملف النادي (`GET club-admin/club`): الاسم والشعار من المنصة، والتواصل والإعدادات يعدّلها المالك.
class ClubProfile extends Equatable {
  const ClubProfile({
    required this.id,
    required this.name,
    this.logoUrl,
    this.contactEmail,
    this.contactPhone,
    this.city,
    this.address,
    this.settings = const ClubSettings(),
    this.branchesUsed = 0,
    this.branchesLimit,
  });

  factory ClubProfile.fromJson(Json j) {
    final branches = j.obj('usage').obj('branches');
    return ClubProfile(
      id: j.intv('id'),
      name: j.str('name', '—'),
      logoUrl: j.strOrNull('logo_url'),
      contactEmail: j.strOrNull('contact_email'),
      contactPhone: j.strOrNull('contact_phone'),
      city: j.strOrNull('city'),
      address: j.strOrNull('address'),
      settings: ClubSettings.fromJson(j.obj('settings')),
      branchesUsed: branches.intv('used'),
      branchesLimit: branches.intOrNull('limit'),
    );
  }

  final int id;
  final String name;
  final String? logoUrl, contactEmail, contactPhone, city, address;
  final ClubSettings settings;

  /// استعمال حد الفروع بباقة النادي (null = بلا حد).
  final int branchesUsed;
  final int? branchesLimit;

  bool get branchLimitReached => branchesLimit != null && branchesUsed >= branchesLimit!;

  @override
  List<Object?> get props => [
    id,
    name,
    logoUrl,
    contactEmail,
    contactPhone,
    city,
    address,
    settings,
    branchesUsed,
    branchesLimit,
  ];
}

/// نوع إشعار يطفئه المالك للنادي كله (`GET club-admin/club/notification-types`).
class NotificationType extends Equatable {
  const NotificationType({required this.type, required this.label, this.description = '', this.audience = 'owners'});

  factory NotificationType.fromJson(Json j) => NotificationType(
    type: j.str('type'),
    label: j.str('label', '—'),
    description: j.str('description'),
    audience: j.str('audience', 'owners'),
  );

  final String type, label, description;

  /// `owners` / `staff` (المالك واستقبال الفرع) / `player`.
  final String audience;

  @override
  List<Object?> get props => [type, label, description, audience];
}

/// الأنواع القابلة للإطفاء، وأسماء الجماهير، وإشعارات المنصة (لا تُطفأ).
class NotificationCatalog extends Equatable {
  const NotificationCatalog({this.types = const [], this.audiences = const {}, this.platform = const []});

  factory NotificationCatalog.fromJson(Json j) => NotificationCatalog(
    types: j.list('types', NotificationType.fromJson),
    audiences: {for (final e in j.obj('audiences').entries) e.key: '${e.value}'},
    platform: [for (final p in j.list('platform_types', (p) => p.str('label'))) p],
  );

  final List<NotificationType> types;
  final Map<String, String> audiences;
  final List<String> platform;

  /// الأنواع مجمّعة بالجمهور بترتيب: المالك، المالك والاستقبال، العضو.
  List<({String audience, String label, List<NotificationType> types})> get groups => [
    for (final a in const ['owners', 'staff', 'player'])
      if (types.where((t) => t.audience == a).toList() case final list when list.isNotEmpty)
        (audience: a, label: audiences[a] ?? a, types: list),
  ];

  @override
  List<Object?> get props => [types, audiences, platform];
}

/// نصوص الإعدادات وخياراتها.
abstract final class SettingsTexts {
  /// أيام الأسبوع بمفاتيح الخادم، بترتيب يبدأ بالسبت.
  static const days = <FormOption<String>>[
    (value: 'saturday', label: 'السبت'),
    (value: 'sunday', label: 'الأحد'),
    (value: 'monday', label: 'الإثنين'),
    (value: 'tuesday', label: 'الثلاثاء'),
    (value: 'wednesday', label: 'الأربعاء'),
    (value: 'thursday', label: 'الخميس'),
    (value: 'friday', label: 'الجمعة'),
  ];

  static const weekStarts = <FormOption<String>>[
    (value: 'saturday', label: 'السبت'),
    (value: 'sunday', label: 'الأحد'),
    (value: 'monday', label: 'الإثنين'),
  ];

  /// نهاية يوم العمل 0–6.
  static String dayEnd(int h) => switch (h) {
    0 => 'منتصف الليل',
    1 || 2 || 3 || 4 => '$h فجراً',
    _ => '$h صباحاً',
  };

  /// مناطق زمنية شائعة؛ منطقة النادي الحالية تُضاف إن لم تكن بينها.
  static List<FormOption<String>> timezones(String current) => [
    for (final z in {
      'Asia/Damascus',
      'Asia/Beirut',
      'Asia/Amman',
      'Asia/Baghdad',
      'Asia/Riyadh',
      'Asia/Dubai',
      'Africa/Cairo',
      'Europe/Istanbul',
      current,
    })
      (value: z, label: z),
  ];

  static const genders = <FormOption<String>>[
    (value: 'female', label: 'إناث'),
    (value: 'male', label: 'ذكور'),
    (value: 'mixed', label: 'مختلط'),
  ];

  static String policy(String p) => p == 'time_split' ? 'أوقات منفصلة' : 'مختلط';
}
