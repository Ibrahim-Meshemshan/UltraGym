import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../domain/models/member_models.dart';
import '../../domain/models/member_profile_models.dart';
import 'member_cells.dart';
import 'profile_actions.dart';

/// الاشتراك الحالي: الخطة، التفاصيل (من حقول الخادم)، الانتهاء أو الجلسات، والمتبقي عليه.
class CurrentMembershipCard extends StatelessWidget {
  const CurrentMembershipCard(this.profile, {super.key});

  final MemberProfile profile;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final m = profile.membership;
    return SectionCard(
      title: 'الاشتراك الحالي',
      action: m == null ? null : 'التفاصيل',
      onAction: m == null ? null : () => context.go(Routes.child(Routes.memberships, m.id)),
      child: m == null
          ? Text('لا اشتراك لهذا العضو بعد.', style: UType.body(color: c.inkMuted))
          : Wrap(
              spacing: AppSpace.s3,
              runSpacing: AppSpace.s3,
              children: [
                _Mini('الخطة', Text(m.planName, style: UType.body(color: c.ink).weight(600))),
                _Mini('الحالة', Text(membershipDetail(m), style: UType.body(color: c.ink).weight(600))),
                if (m.isSessions && m.sessionsTotal != null)
                  _Mini('الجلسات', _value(context, '${m.sessionsRemaining ?? 0} / ${m.sessionsTotal}'))
                else
                  _Mini('ينتهي', _value(context, Formatters.date(m.endsOn))),
                _Mini(
                  'المتبقي عليه',
                  _value(
                    context,
                    m.dueUsd > 0 ? Formatters.usd(m.dueUsd) : '—',
                    color: m.dueUsd > 0 ? c.dangerInk : null,
                  ),
                ),
              ],
            ),
    );
  }

  static Widget _value(BuildContext context, String v, {Color? color}) =>
      LtrText(v, style: UType.h3(color: color ?? context.colors.ink));
}

/// مربع رقم صغير (`.mini`).
class _Mini extends StatelessWidget {
  const _Mini(this.label, this.value);

  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: AppSize.figure),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.s4, vertical: AppSpace.s3),
        decoration: BoxDecoration(
          border: Border.all(color: c.line),
          borderRadius: AppRadius.fieldAll,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: UType.caption(color: c.inkMuted)),
            value,
          ],
        ),
      ),
    );
  }
}

/// البيانات + "تعديل". الفارغ "—".
class MemberDataCard extends StatelessWidget {
  const MemberDataCard(this.profile, {super.key});

  final MemberProfile profile;

  @override
  Widget build(BuildContext context) {
    final p = profile;
    final gender = MemberFilters.genders.where((g) => g.value == p.gender).firstOrNull?.label;
    return SectionCard(
      title: 'البيانات',
      action: p.isArchived ? null : 'تعديل',
      onAction: p.isArchived ? null : () => editMember(context, p),
      child: Column(
        children: [
          KvRow('الموبايل', ltr: p.phone),
          KvRow('البريد الإلكتروني', ltr: p.email),
          KvRow('تاريخ الميلاد', ltr: p.birthDate == null ? null : Formatters.date(p.birthDate)),
          KvRow('الجنس', text: gender),
          KvRow('العنوان', text: p.address),
          KvRow('للطوارئ', text: p.emergencyName, ltr: p.emergencyPhone),
          KvRow('تطبيق العضو', text: _appLine(p)),
        ],
      ),
    );
  }

  static String _appLine(MemberProfile p) => switch (p.lastLoginAt) {
    _ when p.mustChangePassword => 'بكلمة سر مؤقتة لم تُغيَّر',
    final d? => 'آخر دخول ${Formatters.relative(d, now: sl<ServerClock>().now())}',
    null => 'لم يدخل بعد',
  };
}

/// النشاط: الزيارات المقبولة ومجموع المدفوع (من الخادم).
class ActivityCard extends StatelessWidget {
  const ActivityCard(this.profile, {super.key});

  final MemberProfile profile;

  @override
  Widget build(BuildContext context) {
    final s = profile.stats;
    return SectionCard(
      title: 'النشاط',
      child: Column(
        children: [
          KvRow('زيارات هذا الشهر', ltr: Formatters.number(s.visitsThisMonth)),
          KvRow('كل الزيارات', ltr: Formatters.number(s.visitsTotal)),
          KvRow('آخر زيارة', ltr: s.lastVisitAt == null ? null : Formatters.dateTime(s.lastVisitAt)),
          KvRow('مجموع المدفوع', ltr: Formatters.usd(s.paidTotalUsd)),
        ],
      ),
    );
  }
}

/// التدريب: مدرب الاشتراك الحالي وآخر قياس، و "القياسات" تفتح تبويبها بقسم التدريب. لا يظهر إن لم يوجد أي منهما.
class TrainingCard extends StatelessWidget {
  const TrainingCard(this.profile, {super.key});

  final MemberProfile profile;

  @override
  Widget build(BuildContext context) {
    final m = profile.measurement;
    String? measure;
    if (m != null) {
      final weight = m.weightKg == null ? null : '${Formatters.number(m.weightKg)} kg';
      measure = [weight, if (m.measuredOn != null) Formatters.date(m.measuredOn)].nonNulls.join(' · ');
    }
    return SectionCard(
      title: 'التدريب',
      action: 'القياسات',
      onAction: () => context.go(Routes.measurementsOf(profile.id)),
      child: Column(
        children: [
          KvRow('المدرب', text: profile.membership?.trainerName),
          KvRow('آخر قياس', ltr: measure),
          if (m?.bodyFat case final fat?) KvRow('نسبة الدهون', ltr: '${Formatters.number(fat)}%'),
        ],
      ),
    );
  }
}

class NotesCard extends StatelessWidget {
  const NotesCard(this.notes, {super.key});

  final String notes;

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'ملاحظات',
    child: Text(notes, style: UType.body(color: context.colors.inkMuted)),
  );
}

/// سطر "عنوان ← قيمة" بخط فاصل علوي (`.kv`). `ltr` للأرقام والهواتف والتواريخ، والفارغ "—".
class KvRow extends StatelessWidget {
  const KvRow(this.label, {super.key, this.text, this.ltr});

  final String label;
  final String? text, ltr;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = UType.body(color: c.ink);
    final t = text?.trim() ?? '', l = ltr?.trim() ?? '';
    final value = switch ((t, l)) {
      ('', '') => Text('—', style: UType.body(color: c.inkFaint)),
      (_, '') => Text(t, style: style, textAlign: TextAlign.end),
      ('', _) => LtrText(l, style: style),
      _ => Wrap(
        alignment: WrapAlignment.end,
        children: [
          Text('$t · ', style: style),
          LtrText(l, style: style),
        ],
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.s2),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpace.s3,
        children: [
          Text(label, style: UType.body(color: c.inkMuted)),
          Expanded(
            child: Align(alignment: AlignmentDirectional.centerEnd, child: value),
          ),
        ],
      ),
    );
  }
}
