import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../members/presentation/widgets/member_cells.dart';
import '../../domain/models/membership_detail_models.dart';
import 'membership_actions.dart';
import 'renew_dialog.dart';

/// رأس الاشتراك (`MembershipDetail.html`): الخطة والحالة، العضو والفرع، الأفعال، ثم مربعات الحقائق.
class MembershipHeader extends StatelessWidget {
  const MembershipHeader(this.detail, {super.key});

  final MembershipDetail detail;

  @override
  Widget build(BuildContext context) {
    final d = detail;
    final m = d.membership;
    final c = context.colors;
    final muted = UType.label(color: c.inkMuted);
    final identity = Row(
      spacing: AppSpace.s4,
      children: [
        MemberAvatar(m.playerName),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpace.s1,
            children: [
              Wrap(
                spacing: AppSpace.s2,
                runSpacing: AppSpace.s1,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(m.planName, style: UType.h2(color: c.ink)),
                  MembershipBadge(m),
                ],
              ),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  InkWell(
                    onTap: () => context.go(Routes.child(Routes.members, m.playerId)),
                    child: Text(m.playerName, style: muted.copyWith(color: c.primaryInk).weight(600)),
                  ),
                  if (m.branchName case final b?) Text(' · بيع من $b', style: muted),
                ],
              ),
            ],
          ),
        ),
      ],
    );
    return CutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.s5,
        children: [
          LayoutBuilder(
            builder: (context, box) => box.maxWidth >= AppSize.splitMin
                ? Row(
                    spacing: AppSpace.s4,
                    children: [
                      Expanded(child: identity),
                      Flexible(child: _Actions(d)),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: AppSpace.s4,
                    children: [identity, _Actions(d)],
                  ),
          ),
          _Facts(d),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions(this.d);

  final MembershipDetail d;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final owner = context.select<AuthBloc, bool>((b) => b.state.session?.isClubOwner ?? false);
    final active = !d.isCancelled;
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: AppSpace.s2,
      runSpacing: AppSpace.s2,
      children: [
        if (d.hasDebt)
          UGButton(
            label: 'سداد الدين ${Formatters.ltr(Formatters.usd(d.membership.dueUsd))}',
            icon: Icons.payments_rounded,
            onPressed: () => payDebt(context, d),
          ),
        if (active)
          UGButton(
            label: 'تجديد',
            icon: Icons.autorenew_rounded,
            kind: UButtonKind.secondary,
            onPressed: () => renewMembership(context, d),
          ),
        if (d.canFreeze)
          UGButton(
            label: 'تجميد',
            icon: Icons.ac_unit_rounded,
            kind: UButtonKind.secondary,
            onPressed: () => freezeMembership(context, d),
          ),
        if (d.isFrozen)
          UGButton(
            label: 'فك التجميد',
            icon: Icons.wb_sunny_outlined,
            kind: UButtonKind.secondary,
            onPressed: () => unfreezeMembership(context, d),
          ),
        if (d.canConsumeSession)
          UGButton(
            label: 'تسجيل جلسة',
            icon: Icons.fitness_center_rounded,
            kind: UButtonKind.secondary,
            onPressed: () => consumeSession(context, d),
          ),
        UGButton(
          label: 'الفاتورة',
          icon: Icons.download_rounded,
          kind: UButtonKind.secondary,
          onPressed: () => openInvoice(d.id),
        ),
        if (owner && active)
          OutlinedButton.icon(
            onPressed: () => cancelMembership(context, d),
            icon: const Icon(Icons.cancel_outlined, size: AppSize.iconSm),
            label: const Text('إلغاء الاشتراك'),
            style: OutlinedButton.styleFrom(
              foregroundColor: c.dangerInk,
              side: BorderSide(color: c.dangerSoft),
              minimumSize: const Size(0, AppSize.control),
              shape: const RoundedRectangleBorder(borderRadius: AppRadius.smAll),
              textStyle: UType.label().weight(500),
            ),
          ),
      ],
    );
  }
}

/// مربعات الحقائق (`.kv`): المدة، المتبقي، الجلسات، رصيد التجميد، المدرب، العمولة (للمالك)، الكوبون.
class _Facts extends StatelessWidget {
  const _Facts(this.d);

  final MembershipDetail d;

  @override
  Widget build(BuildContext context) {
    final m = d.membership;
    final f = d.freezes;
    final owner = context.select<AuthBloc, bool>((b) => b.state.session?.isClubOwner ?? false);
    return Wrap(
      spacing: AppSpace.s3,
      runSpacing: AppSpace.s3,
      children: [
        _Fact('المدة', child: MembershipPeriod(m)),
        _Fact('المتبقي', text: membershipDetail(m)),
        if (m.isSessions && m.sessionsTotal != null)
          _Fact('الجلسات', ltr: '${d.sessionsUsed} / ${m.sessionsTotal}', note: 'مستخدمة من الكل'),
        _Fact(
          'رصيد التجميد',
          text: f.maxFreezes == 0 ? 'غير مسموح بالخطة' : 'استُخدم ${f.used} من ${f.maxFreezes}',
          note: f.maxFreezes == 0 ? null : '${f.daysUsed} من ${f.maxDays} يوماً',
        ),
        if (m.trainerName case final t?) _Fact('المدرب', text: t),
        if (owner && m.trainerName != null && d.commissionUsd != null)
          _Fact('عمولة المدرب', ltr: Formatters.usd(d.commissionUsd!)),
        if (d.couponCode case final code?) _Fact('الكوبون', ltr: code),
        if (d.createdAt case final at?) _Fact('تاريخ البيع', ltr: Formatters.date(at, fromUtc: true)),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.label, {this.text, this.ltr, this.note, this.child});

  final String label;
  final String? text, ltr, note;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = UType.body(color: c.ink).weight(600);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: AppSize.figure),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.s4, vertical: AppSpace.s3),
        decoration: BoxDecoration(color: c.surfaceAlt, borderRadius: AppRadius.fieldAll),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpace.s1,
          children: [
            Text(label, style: UType.caption(color: c.inkMuted)),
            ?child,
            if (text != null) Text(text!, style: style),
            if (ltr != null) LtrText(ltr!, style: style),
            if (note != null) Text(note!, style: UType.caption(color: c.inkMuted)),
          ],
        ),
      ),
    );
  }
}

/// تنبيه الإلغاء: التاريخ والسبب كما من الخادم.
class CancelledNotice extends StatelessWidget {
  const CancelledNotice(this.detail, {super.key});

  final MembershipDetail detail;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ink = c.inkMuted;
    return Container(
      padding: const EdgeInsets.all(AppSpace.s4),
      decoration: BoxDecoration(color: c.surfaceAlt, borderRadius: AppRadius.fieldAll),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpace.s3,
        children: [
          Icon(Icons.cancel_outlined, color: ink, size: AppSize.icon),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpace.s2,
                  children: [
                    Text('الاشتراك ملغى', style: UType.body(color: c.ink).weight(600)),
                    if (detail.cancelledAt case final at?)
                      LtrText(Formatters.date(at, fromUtc: true), style: UType.caption(color: ink)),
                  ],
                ),
                Text(detail.cancellationReason ?? 'لا يُحسب ديناً ولا يدخل به العضو.', style: UType.label(color: ink)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
