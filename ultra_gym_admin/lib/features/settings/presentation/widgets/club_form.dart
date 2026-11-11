import 'dart:convert';

import '../../../../core/core.dart';
import '../../data/repo/settings_repository.dart';
import '../../domain/models/settings_models.dart';

/// نموذج تبويب النادي: حقول التواصل (`PATCH club`) والإعدادات (`PATCH club/settings`) بنموذج واحد.
/// أسماء الحقول = مفاتيح الخادم، فيظهر 422 تحت حقله. الحفظ يرسل الطلب الذي تغيّر جسمه فقط.
abstract final class ClubForm {
  static const contact = ['contact_phone', 'contact_email', 'city', 'address'];

  static const ints = [
    'membership_grace_days',
    'duplicate_check_in_minutes',
    'default_max_freezes',
    'default_max_freeze_days',
  ];

  /// أقصى قيمة لكل حقل عددي كما بقواعد الخادم.
  static const maxOf = {
    'membership_grace_days': 30,
    'duplicate_check_in_minutes': 1440,
    'default_max_freezes': 20,
    'default_max_freeze_days': 365,
  };

  static const disabled = 'disabled_notifications';

  static Json initial(ClubProfile c) {
    final s = c.settings;
    return {
      'contact_phone': c.contactPhone ?? '',
      'contact_email': c.contactEmail ?? '',
      'city': c.city ?? '',
      'address': c.address ?? '',
      'timezone': s.timezone,
      'week_start_day': s.weekStartDay,
      'weekend_days': [...s.weekendDays],
      'business_day_ends_at_hour': s.businessDayEndsAt,
      'membership_grace_days': '${s.graceDays}',
      'duplicate_check_in_minutes': '${s.duplicateCheckInMinutes}',
      'default_max_freezes': '${s.defaultMaxFreezes}',
      'default_max_freeze_days': '${s.defaultMaxFreezeDays}',
      'allow_partial_payment': s.allowPartialPayment,
      'expiry_reminders_enabled': s.expiryReminders,
      'receipt_footer': s.receiptFooter ?? '',
      'day_pass_enabled': s.dayPassEnabled,
      'day_pass_price_usd': s.dayPassPriceUsd == null ? '' : Formatters.number(s.dayPassPriceUsd).replaceAll(',', ''),
      'player_workouts_enabled': s.playerWorkoutsEnabled,
      disabled: [...s.disabledNotifications],
    };
  }

  static String? _text(Object? v) => '${v ?? ''}'.trim().isEmpty ? null : '${v ?? ''}'.trim();

  /// `PATCH club`: الفارغ null (يمسحه الخادم).
  static Json clubBody(Object? Function(String key) v) => {for (final k in contact) k: _text(v(k))};

  /// `PATCH club/settings` بكل الحقول.
  static Json settingsBody(Object? Function(String key) v) => {
    'timezone': v('timezone'),
    'week_start_day': v('week_start_day'),
    'weekend_days': [
      for (final d in const ['saturday', 'sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday'])
        if ((v('weekend_days') as List<dynamic>? ?? const []).contains(d)) d,
    ],
    'business_day_ends_at_hour': v('business_day_ends_at_hour'),
    for (final k in ints) k: int.tryParse('${v(k) ?? ''}'.trim()),
    'allow_partial_payment': v('allow_partial_payment') == true,
    'expiry_reminders_enabled': v('expiry_reminders_enabled') == true,
    'receipt_footer': _text(v('receipt_footer')),
    'day_pass_enabled': v('day_pass_enabled') == true,
    'day_pass_price_usd': num.tryParse('${v('day_pass_price_usd') ?? ''}'.replaceAll(',', '').trim()),
    'player_workouts_enabled': v('player_workouts_enabled') == true,
    disabled: [...?(v(disabled) as List<dynamic>?)?.whereType<String>()]..sort(),
  };

  /// الجسمان يُبنيان بنفس ترتيب المفاتيح، وقيمهما أرقام ونصوص وقوائم.
  static bool _same(Json a, Json b) => jsonEncode(a) == jsonEncode(b);

  /// يرسل ما تغيّر فقط: التواصل ثم الإعدادات. بلا تغيير = نجاح برسالة واضحة دون طلب.
  /// تغيّر المنطقة الزمنية أو الإعدادات ← `onSaved` (تحديث الجلسة).
  static Future<ApiResult<void>> save(SettingsRepository repo, AppFormCubit f, ClubProfile club) async {
    if (((f.value('weekend_days') as List<dynamic>?) ?? const []).length > 3) {
      return const ApiFailure(
        Failure(
          type: FailureType.validation,
          message: 'تحقق من الحقول المحددة.',
          errors: {
            'weekend_days': ['اختر 3 أيام عطلة على الأكثر.'],
          },
        ),
      );
    }
    final before = initial(club);
    final club0 = clubBody((k) => before[k]), clubNow = clubBody(f.value);
    final settings0 = settingsBody((k) => before[k]), settingsNow = settingsBody(f.value);
    final clubChanged = !_same(club0, clubNow), settingsChanged = !_same(settings0, settingsNow);
    if (!clubChanged && !settingsChanged) return const ApiSuccess(null, message: 'لا تغييرات للحفظ.');
    if (clubChanged) {
      final r = await repo.updateClub(clubNow);
      if (r case ApiFailure(:final failure)) return ApiFailure(failure);
    }
    if (settingsChanged) {
      final r = await repo.updateSettings(settingsNow);
      if (r case ApiFailure(:final failure)) return ApiFailure(failure);
    }
    return const ApiSuccess(null, message: 'تم حفظ الإعدادات.');
  }
}
