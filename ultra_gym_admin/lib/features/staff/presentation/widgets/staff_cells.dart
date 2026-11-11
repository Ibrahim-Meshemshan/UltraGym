import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../members/presentation/widgets/member_cells.dart';

/// الحروف + الاسم + سطر ثانٍ (المسمى أو المعرّف) لصفوف الموظفين والحسابات.
class PersonCell extends StatelessWidget {
  const PersonCell(this.name, {super.key, this.sub, this.subLtr = false, this.tag});

  final String name;
  final String? sub;
  final bool subLtr;

  /// شارة صغيرة بجانب الاسم ("حسابك"، "مالك النادي").
  final String? tag;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = UType.caption(color: c.inkMuted);
    return Row(
      children: [
        MemberAvatar(name),
        AppSpace.gap3,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpace.s2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(name, style: UType.body(color: c.ink).weight(600)),
                  if (tag case final t?) StatusBadge(t, tone: UTone.accent, dot: false),
                ],
              ),
              if (sub case final s?)
                subLtr ? LtrText(s, style: style) : Text(s, style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}

/// نص خافت بخلية؛ `ltr` للأرقام والهواتف والمعرّفات: سطر واحد يصغر إن ضاق العمود.
class MutedCell extends StatelessWidget {
  const MutedCell(this.text, {super.key, this.ltr = false});

  final String text;
  final bool ltr;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = UType.body(color: ltr ? c.ink : c.inkMuted);
    return ltr
        ? Align(
            alignment: AlignmentDirectional.centerStart,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: LtrText(text, style: style),
            ),
          )
        : Text(text, style: style, maxLines: 2, overflow: TextOverflow.ellipsis);
  }
}

/// شارة بخلية الجدول (لا تتمدد بعرض العمود).
class BadgeCell extends StatelessWidget {
  const BadgeCell(this.badge, {super.key});

  final ({String label, UTone tone}) badge;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: StatusBadge(badge.label, tone: badge.tone),
  );
}

/// بطاقة صف بالموبايل: الهوية والشارة والقائمة، ثم أسطر "العنوان: القيمة".
class StaffMobileCard extends StatelessWidget {
  const StaffMobileCard({super.key, required this.person, required this.badge, this.lines = const [], this.menu});

  final Widget person;
  final ({String label, UTone tone}) badge;
  final List<({String label, String value, bool ltr})> lines;
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
            Expanded(child: person),
            StatusBadge(badge.label, tone: badge.tone),
            ?menu,
          ],
        ),
        for (final l in lines)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: AppSize.avatar + AppSpace.s3),
            child: Wrap(
              spacing: AppSpace.s2,
              children: [
                Text(l.label, style: UType.caption(color: c.inkMuted)),
                l.ltr
                    ? LtrText(l.value, style: UType.caption(color: c.ink))
                    : Text(l.value, style: UType.caption(color: c.ink)),
              ],
            ),
          ),
      ],
    );
  }
}

/// سطر الشرح أعلى التبويب مع أزراره (تلتف تحته إن ضاق العرض).
class TabIntro extends StatelessWidget {
  const TabIntro({super.key, required this.text, this.actions = const []});

  final String text;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpace.s3,
    runSpacing: AppSpace.s3,
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSize.staffIntroMax),
        child: Text(text, style: UType.label(color: context.colors.inkMuted)),
      ),
      Wrap(spacing: AppSpace.s2, runSpacing: AppSpace.s2, children: actions),
    ],
  );
}
