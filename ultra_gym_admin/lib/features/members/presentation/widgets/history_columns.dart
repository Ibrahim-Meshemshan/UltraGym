import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../domain/models/member_profile_models.dart';
import 'member_cells.dart';

/// أعمدة جداول سجل العضو وبطاقاتها بالموبايل. الحالات والمبالغ والأيام من الخادم كما هي.
abstract final class HistoryColumns {
  static final memberships = <TableCol<MembershipItem>>[
    TableCol('الخطة', flex: 4, cell: (_, m) => MembershipCell(m)),
    TableCol('الفترة', flex: 2, cell: (_, m) => MembershipPeriod(m)),
    TableCol(
      'الصافي',
      cell: (c, m) => LtrText(Formatters.usd(m.netUsd), style: UType.body(color: c.colors.ink)),
    ),
    TableCol('المتبقي', cell: (_, m) => DueText(m.dueUsd)),
    TableCol('الحالة', cell: (_, m) => StatusBadge(m.statusLabel, tone: Labels.membershipStatus(m.status).tone)),
  ];

  static final attendance = <TableCol<AttendanceEntry>>[
    TableCol('الوقت', flex: 3, cell: (c, a) => _ltr(c, Formatters.dateTime(a.checkedInAt))),
    TableCol(
      'الفرع',
      flex: 3,
      cell: (c, a) => Text(a.branchName ?? '—', style: UType.body(color: c.colors.ink)),
    ),
    TableCol('الطريقة', cell: (c, a) => _muted(c, a.methodLabel)),
    TableCol('النتيجة', flex: 3, cell: (_, a) => AttendanceResult(a)),
  ];

  static final payments = <TableCol<PaymentEntry>>[
    TableCol('التاريخ', cell: (c, p) => _ltr(c, Formatters.date(p.businessDate))),
    TableCol('النوع', flex: 3, cell: (c, p) => _PaymentType(p)),
    TableCol('المبلغ', cell: (_, p) => _Amount(p)),
    TableCol('الإيصال', flex: 3, cell: (c, p) => _muted(c, p.receiptNumber ?? '—', ltr: true)),
  ];

  static Widget membershipMobile(BuildContext context, MembershipItem m) => _MobileRow(
    main: MembershipCell(m),
    trailing: StatusBadge(m.statusLabel, tone: Labels.membershipStatus(m.status).tone),
    below: m.dueUsd > 0 ? DueText(m.dueUsd) : null,
  );

  static Widget attendanceMobile(BuildContext context, AttendanceEntry a) => _MobileRow(
    main: _ltr(context, Formatters.dateTime(a.checkedInAt)),
    trailing: AttendanceResult(a),
    below: _muted(context, '${a.branchName ?? '—'} · ${a.methodLabel}'),
  );

  static Widget paymentMobile(BuildContext context, PaymentEntry p) => _MobileRow(
    main: _PaymentType(p),
    trailing: _Amount(p),
    below: _muted(context, '${Formatters.date(p.businessDate)}  ${p.receiptNumber ?? ''}', ltr: true),
  );

  static Widget _ltr(BuildContext c, String v) => LtrText(v, style: UType.body(color: c.colors.ink));

  static Widget _muted(BuildContext c, String v, {bool ltr = false}) {
    final style = UType.label(color: c.colors.inkMuted);
    return ltr ? LtrText(v, style: style) : Text(v, style: style);
  }
}

/// نتيجة الدخول: الشارة (مقبول / بالسماح / مرفوض) وسبب الرفض من الخادم تحتها.
class AttendanceResult extends StatelessWidget {
  const AttendanceResult(this.a, {super.key});

  final AttendanceEntry a;

  @override
  Widget build(BuildContext context) {
    final look = Labels.attendance(a.status, inGrace: a.inGrace);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpace.s1,
      children: [
        StatusBadge(look.text, tone: look.tone),
        if (a.rejectionMessage case final m? when m.isNotEmpty)
          Text(m, style: UType.caption(color: context.colors.inkMuted)),
      ],
    );
  }
}

class _PaymentType extends StatelessWidget {
  const _PaymentType(this.p);

  final PaymentEntry p;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpace.s2,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Text(p.typeLabel, style: UType.body(color: context.colors.ink)),
      if (p.isReversed) StatusBadge(Labels.direction(p.direction, reversed: true).text),
    ],
  );
}

/// المبلغ بعملته: الوارد أخضر، الصادر أحمر بإشارة سالبة، والمعكوس مشطوب.
class _Amount extends StatelessWidget {
  const _Amount(this.p);

  final PaymentEntry p;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = '${p.isOut ? '-' : ''}${Formatters.money(p.amount, p.currency)}';
    final color = p.isReversed ? c.inkFaint : (p.isOut ? c.dangerInk : c.successInk);
    return LtrText(
      text,
      style: UType.body(
        color: color,
      ).weight(600).copyWith(decoration: p.isReversed ? TextDecoration.lineThrough : null),
    );
  }
}

class _MobileRow extends StatelessWidget {
  const _MobileRow({required this.main, required this.trailing, this.below});

  final Widget main, trailing;
  final Widget? below;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: AppSpace.s1,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpace.s2,
        children: [
          Expanded(child: main),
          trailing,
        ],
      ),
      ?below,
    ],
  );
}
