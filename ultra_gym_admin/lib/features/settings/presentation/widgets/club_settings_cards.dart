import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../domain/models/settings_models.dart';
import 'club_form.dart';

/// بطاقة قسم بالإعدادات: عنوان، شرح اختياري، ثم المحتوى.
class SettingsCard extends StatelessWidget {
  const SettingsCard({super.key, required this.title, required this.children, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return CutCard(
      padding: const EdgeInsets.all(AppSpace.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.s4,
        children: [
          Wrap(
            spacing: AppSpace.s3,
            runSpacing: AppSpace.s2,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: UType.h3(color: c.ink)),
                  if (subtitle != null) Text(subtitle!, style: UType.label(color: c.inkMuted)),
                ],
              ),
              ?trailing,
            ],
          ),
          ...children,
        ],
      ),
    );
  }
}

/// حقل عدد صحيح من 0 حتى أقصى الخادم.
class _IntField extends StatelessWidget {
  const _IntField(this.name, {required this.label, this.hint});

  final String name, label;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final max = ClubForm.maxOf[name]!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.s1,
      children: [
        FormText(
          name,
          label: label,
          required: true,
          ltr: true,
          keyboardType: TextInputType.number,
          validator: (v) {
            final n = int.tryParse((v ?? '').trim());
            if (n == null) return 'اكتب عدداً صحيحاً.';
            return n < 0 || n > max ? 'من 0 حتى $max.' : null;
          },
        ),
        if (hint != null) Text(hint!, style: UType.caption(color: context.colors.inkMuted)),
      ],
    );
  }
}

/// التواصل (الاسم من المنصة).
class ClubContactCard extends StatelessWidget {
  const ClubContactCard({super.key, required this.club, required this.logo});

  final ClubProfile club;
  final Widget logo;

  @override
  Widget build(BuildContext context) => SettingsCard(
    title: 'هوية النادي',
    children: [
      logo,
      ResponsiveGrid(
        minItemWidth: AppSize.settingsFieldMin,
        maxColumns: 2,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpace.s1,
            children: [
              const FieldLabel('اسم النادي'),
              InputDecorator(decoration: const InputDecoration(), child: Text(club.name)),
              Text('تحدده المنصة.', style: UType.caption(color: context.colors.inkMuted)),
            ],
          ),
          const FormText(
            'contact_phone',
            label: 'هاتف التواصل',
            ltr: true,
            hint: '+963112223344',
            keyboardType: TextInputType.phone,
          ),
          FormText(
            'contact_email',
            label: 'البريد',
            ltr: true,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              final s = (v ?? '').trim();
              return s.isEmpty || RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s) ? null : 'اكتب بريداً صحيحاً.';
            },
          ),
          const FormText('city', label: 'المدينة'),
          const FormText('address', label: 'العنوان'),
        ],
      ),
    ],
  );
}

/// التشغيل: المنطقة الزمنية، نهاية يوم العمل، بداية الأسبوع، العطلة.
class ClubOperationsCard extends StatelessWidget {
  const ClubOperationsCard({super.key, required this.timezone});

  final String timezone;

  @override
  Widget build(BuildContext context) {
    final muted = UType.caption(color: context.colors.inkMuted);
    return SettingsCard(
      title: 'التشغيل',
      children: [
        ResponsiveGrid(
          minItemWidth: AppSize.settingsFieldMin,
          maxColumns: 2,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpace.s1,
              children: [
                FormDropdown<String>('timezone', label: 'المنطقة الزمنية', options: SettingsTexts.timezones(timezone)),
                Text('كل حسابات اليوم والأوقات بها.', style: muted),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpace.s1,
              children: [
                FormDropdown<int>(
                  'business_day_ends_at_hour',
                  label: 'نهاية يوم العمل',
                  options: [for (var h = 0; h <= 6; h++) (value: h, label: SettingsTexts.dayEnd(h))],
                ),
                Text('ما قبلها بعد منتصف الليل يُحسب على اليوم السابق.', style: muted),
              ],
            ),
            const FormDropdown<String>('week_start_day', label: 'بداية الأسبوع', options: SettingsTexts.weekStarts),
          ],
        ),
        const FormChips<String>('weekend_days', label: 'أيام العطلة (حتى 3)', options: SettingsTexts.days),
      ],
    );
  }
}

/// الاشتراكات والدخول وتذييل الإيصال.
class ClubMembershipsCard extends StatelessWidget {
  const ClubMembershipsCard({super.key});

  @override
  Widget build(BuildContext context) => const SettingsCard(
    title: 'الاشتراكات والدخول',
    children: [
      ResponsiveGrid(
        minItemWidth: AppSize.settingsFieldMin,
        maxColumns: 2,
        children: [
          _IntField('membership_grace_days', label: 'أيام السماح بعد الانتهاء', hint: 'يُقبل الدخول خلالها مع تنبيه.'),
          _IntField(
            'duplicate_check_in_minutes',
            label: 'الدخول المكرر (دقيقة)',
            hint: 'مسح ثانٍ خلالها يُعتبر الدخول نفسه.',
          ),
          _IntField('default_max_freezes', label: 'مرات التجميد الافتراضية', hint: 'لكل خطة بلا حدود خاصة.'),
          _IntField('default_max_freeze_days', label: 'أيام التجميد الافتراضية'),
        ],
      ),
      FormSwitch('allow_partial_payment', label: 'السماح بالبيع بدفعة جزئية (دين)'),
      FormSwitch('expiry_reminders_enabled', label: 'تذكير الأعضاء قبل انتهاء اشتراكاتهم وعند انتهائها'),
      FormText('receipt_footer', label: 'تذييل الإيصال', hint: 'مثلاً: شكراً لثقتكم'),
    ],
  );
}

/// الدخول اليومي وبرامج الأعضاء (ميزات يطفئها المالك).
class ClubExtrasCard extends StatelessWidget {
  const ClubExtrasCard({super.key});

  @override
  Widget build(BuildContext context) => SettingsCard(
    title: 'الدخول اليومي وبرامج الأعضاء',
    children: [
      const FormSwitch('day_pass_enabled', label: 'بيع دخول ليوم واحد', hint: 'لزائر أو عضو بلا اشتراك فعّال.'),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSize.settingsFieldMax),
        child: FormText(
          'day_pass_price_usd',
          label: r'سعر الدخول اليومي ($)',
          ltr: true,
          hint: 'فارغ = يكتبه المالك عند البيع',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (v) {
            final s = (v ?? '').replaceAll(',', '').trim();
            if (s.isEmpty) return null;
            final n = num.tryParse(s);
            return n == null || n < 0 || n > 100000 ? 'اكتب السعر بالأرقام (حتى 100000).' : null;
          },
        ),
      ),
      Text('لكل الفروع؛ وللفرع سعره الخاص من تبويب الفروع.', style: UType.caption(color: context.colors.inkMuted)),
      const FormSwitch(
        'player_workouts_enabled',
        label: 'يضيف العضو برامجه من التطبيق',
        hint: 'تظهر بالتدريب بشارة "أضافها العضو".',
      ),
    ],
  );
}
