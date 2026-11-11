import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../domain/models/member_models.dart';

/// سطر التفاصيل تحت اسم الخطة، من حقول الخادم كما هي (لا حساب للحالة أو الأيام).
String membershipDetail(CurrentMembership? m) {
  if (m == null) return 'لم يشترك بعد';
  String day(DateTime? d) => d == null ? '—' : Formatters.dayMonth(d);
  return switch (m.status) {
    'frozen' => 'مجمّد حتى ${day(m.frozenUntil)}',
    'upcoming' => 'يبدأ ${day(m.startsOn)}',
    'grace' => 'انتهى ${day(m.endsOn)}',
    'expired' => 'انتهى ${day(m.endsOn)}',
    'cancelled' => 'ملغى',
    _ when m.isSessions && m.sessionsRemaining != null => _sessionsLeft(m.sessionsRemaining!),
    _ => switch (m.daysRemaining) {
      null => 'حتى ${day(m.endsOn)}',
      0 => 'ينتهي اليوم',
      final n => 'حتى ${day(m.endsOn)} · باقي ${Formatters.days(n)}',
    },
  };
}

String _sessionsLeft(int n) =>
    n == 0 ? 'انتهت الجلسات' : 'بقيت ${Formatters.count(n, 'جلسة', 'جلستان', 'جلسات', many: 'جلسة')}';

/// أول حرف من أول كلمتين ("أ خ").
String initials(String name) =>
    name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).take(2).map((w) => w.characters.first).join(' ');

/// العضو: صورة الحروف + الاسم (+ "حساب موقوف") + المعرّف LTR.
class MemberIdentity extends StatelessWidget {
  const MemberIdentity(this.member, {super.key});

  final MemberRow member;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        MemberAvatar(member.name),
        AppSpace.gap3,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpace.s2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(member.name, style: UType.body(color: c.ink).weight(600)),
                  if (member.isSuspended) const StatusBadge('حساب موقوف', tone: UTone.danger, dot: false),
                ],
              ),
              if (member.memberCode case final code?) LtrText(code, style: UType.caption(color: c.inkMuted)),
            ],
          ),
        ),
      ],
    );
  }
}

class MemberAvatar extends StatelessWidget {
  const MemberAvatar(this.name, {super.key});

  final String name;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ExcludeSemantics(
      child: CircleAvatar(
        radius: AppSize.avatar / 2,
        backgroundColor: c.primarySoft,
        child: Text(initials(name), style: UType.label(color: c.primaryInk).weight(600)),
      ),
    );
  }
}

/// الاشتراك الحالي: اسم الخطة وتحته التفاصيل.
class MembershipCell extends StatelessWidget {
  const MembershipCell(this.membership, {super.key});

  final CurrentMembership? membership;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          membership?.planName ?? '—',
          style: UType.body(color: c.ink),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(membershipDetail(membership), style: UType.caption(color: c.inkMuted)),
      ],
    );
  }
}

/// شارة حالة الاشتراك: نص الخادم ولون `Labels`. بلا اشتراك = "بلا اشتراك" محايدة.
class MembershipBadge extends StatelessWidget {
  const MembershipBadge(this.membership, {super.key});

  final CurrentMembership? membership;

  @override
  Widget build(BuildContext context) {
    final m = membership;
    if (m == null) return const StatusBadge('بلا اشتراك');
    return StatusBadge(m.statusLabel, tone: Labels.membershipStatus(m.status).tone);
  }
}

/// فترة الاشتراك: البداية والنهاية بسطرين (بسطر واحد ينكسر التاريخان عند الشرطة بالعمود الضيق).
class MembershipPeriod extends StatelessWidget {
  const MembershipPeriod(this.m, {super.key});

  final CurrentMembership m;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        LtrText(Formatters.date(m.startsOn), style: UType.label(color: c.ink)),
        LtrText(Formatters.date(m.endsOn), style: UType.caption(color: c.inkMuted)),
      ],
    );
  }
}

/// الدين: عنبري إن وُجد، و "—" خافتة إن لا.
class DueText extends StatelessWidget {
  const DueText(this.dueUsd, {super.key});

  final double dueUsd;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return dueUsd > 0
        ? LtrText(Formatters.usd(dueUsd), style: UType.body(color: c.warningInk).weight(600))
        : Text('—', style: UType.body(color: c.inkFaint));
  }
}

/// بطاقة العضو بالموبايل: الهوية والحالة بسطر، والخطة والدين تحته.
class MemberMobileCard extends StatelessWidget {
  const MemberMobileCard(this.member, {super.key, this.menu});

  final MemberRow member;
  final Widget? menu;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.s2,
      children: [
        Row(
          children: [
            Expanded(child: MemberIdentity(member)),
            MembershipBadge(member.membership),
            ?menu,
          ],
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: AppSize.avatar + AppSpace.s3),
          child: Row(
            children: [
              Expanded(child: MembershipCell(member.membership)),
              if (member.hasDebt) ...[AppSpace.gap2, DueText(member.dueUsd)],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: AppSize.avatar + AppSpace.s3),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: LtrText(member.phone, style: UType.caption(color: c.inkMuted)),
          ),
        ),
      ],
    );
  }
}
