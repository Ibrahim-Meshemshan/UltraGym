import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../domain/models/member_models.dart';
import '../../domain/models/member_profile_models.dart';
import 'member_cells.dart';
import 'profile_actions.dart';

/// رأس الملف (`MemberProfile.html`): الصورة، الاسم والشارات، سطر التعريف، والأفعال.
/// المؤرشف بلا أفعال: الخادم لا يقبل العمليات عليه حتى يُسترجع.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader(this.profile, {super.key});

  final MemberProfile profile;

  @override
  Widget build(BuildContext context) {
    final p = profile;
    final c = context.colors;
    final identity = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpace.s1,
      children: [
        Wrap(
          spacing: AppSpace.s2,
          runSpacing: AppSpace.s1,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(p.name, style: UType.h2(color: c.ink)),
            MembershipBadge(p.membership),
            if (p.isSuspended) const StatusBadge('حساب موقوف', tone: UTone.danger),
            if (p.isArchived) const StatusBadge('مؤرشف'),
            if (p.hasDebt) StatusBadge('عليه ${Formatters.ltr(Formatters.usd(p.dueUsd))}', tone: UTone.warning),
          ],
        ),
        _MetaLine(p),
      ],
    );
    final top = Row(
      spacing: AppSpace.s5,
      children: [
        ProfilePhoto(p, canChange: !p.isArchived),
        Expanded(child: identity),
      ],
    );
    return CutCard(
      child: LayoutBuilder(
        builder: (context, box) => box.maxWidth >= AppSize.splitMin
            ? Row(
                spacing: AppSpace.s4,
                children: [
                  Expanded(child: top),
                  if (!p.isArchived) _Actions(p),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpace.s4,
                children: [top, if (!p.isArchived) _Actions(p)],
              ),
      ),
    );
  }
}

/// المعرّف · الموبايل · الجنس · الفرع · عضو منذ.
class _MetaLine extends StatelessWidget {
  const _MetaLine(this.p);

  final MemberProfile p;

  @override
  Widget build(BuildContext context) {
    final style = UType.label(color: context.colors.inkMuted);
    final gender = MemberFilters.genders.where((g) => g.value == p.gender).firstOrNull?.label;
    final parts = <Widget>[
      if (p.memberCode case final code?) LtrText(code, style: style),
      LtrText(p.phone, style: style),
      if (gender != null) Text(gender, style: style),
      if (p.branchName case final b?) Text(b, style: style),
      if (p.joinedAt case final d?)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('عضو منذ ', style: style),
            LtrText(Formatters.date(d, fromUtc: true), style: style),
          ],
        ),
    ];
    return Wrap(
      runSpacing: AppSpace.s1,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < parts.length; i++) ...[if (i > 0) Text(' · ', style: style), parts[i]],
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions(this.p);

  final MemberProfile p;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Wrap(
      spacing: AppSpace.s2,
      runSpacing: AppSpace.s2,
      children: [
        UGButton(
          label: 'بيع اشتراك',
          icon: Icons.add_card_rounded,
          onPressed: () => context.go(Routes.sellTo(p.id)),
        ),
        UGButton(
          label: 'كلمة سر جديدة',
          icon: Icons.key_rounded,
          kind: UButtonKind.secondary,
          onPressed: () => resetMemberPassword(context, p),
        ),
        if (p.isSuspended)
          UGButton(
            label: 'تفعيل',
            icon: Icons.check_circle_outline_rounded,
            kind: UButtonKind.secondary,
            onPressed: () => activateMember(context, p),
          )
        else
          OutlinedButton.icon(
            onPressed: () => suspendMember(context, p),
            icon: const Icon(Icons.block_rounded, size: AppSize.iconSm),
            label: const Text('إيقاف'),
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

/// صورة العضو 72 (أو حروف اسمه)، وزر تغييرها بالزاوية. الرابط مؤقت (30 دقيقة) فلا يُخزَّن.
class ProfilePhoto extends StatelessWidget {
  const ProfilePhoto(this.p, {super.key, this.canChange = true});

  final MemberProfile p;
  final bool canChange;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fallback = Center(
      child: Text(initials(p.name), style: UType.h1(color: c.primaryInk).weight(700)),
    );
    final photo = ClipRRect(
      borderRadius: AppRadius.cardAll,
      child: Container(
        width: AppSize.profileAvatar,
        height: AppSize.profileAvatar,
        color: c.primarySoft,
        child: switch (p.photoUrl) {
          final url? => Image.network(
            url,
            fit: BoxFit.cover,
            semanticLabel: 'صورة ${p.name}',
            errorBuilder: (_, _, _) => fallback,
          ),
          null => ExcludeSemantics(child: fallback),
        },
      ),
    );
    if (!canChange) return photo;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        photo,
        PositionedDirectional(
          bottom: -AppSpace.s1,
          end: -AppSpace.s1,
          child: Material(
            color: c.surface,
            shape: CircleBorder(side: BorderSide(color: c.line)),
            child: IconButton(
              tooltip: p.photoUrl == null ? 'إضافة صورة' : 'تغيير الصورة',
              visualDensity: VisualDensity.compact,
              iconSize: AppSize.iconSm,
              onPressed: () => changeMemberPhoto(context),
              icon: Icon(Icons.photo_camera_outlined, color: c.inkMuted),
            ),
          ),
        ),
      ],
    );
  }
}

/// تنبيه أعلى الملف: الحساب موقوف (السبب والتاريخ) أو العضو بالأرشيف.
class ProfileNotice extends StatelessWidget {
  const ProfileNotice(this.profile, {super.key});

  final MemberProfile profile;

  @override
  Widget build(BuildContext context) {
    final p = profile;
    final c = context.colors;
    final (icon, title, body, bg, ink) = p.isArchived
        ? (
            Icons.inventory_2_outlined,
            'العضو بالأرشيف',
            'لا يدخل النادي ولا تُسجَّل عليه عمليات. المالك يسترجعه من تبويب الأرشيف بقائمة الأعضاء.',
            c.surfaceAlt,
            c.inkMuted,
          )
        : (
            Icons.block_rounded,
            'الحساب موقوف',
            p.suspensionReason ?? 'يُرفض دخوله للنادي حتى تعيد تفعيله.',
            c.dangerSoft,
            c.dangerInk,
          );
    return Container(
      padding: const EdgeInsets.all(AppSpace.s4),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.fieldAll),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpace.s3,
        children: [
          Icon(icon, color: ink, size: AppSize.icon),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpace.s2,
                  children: [
                    Text(title, style: UType.body(color: ink).weight(600)),
                    if (!p.isArchived && p.suspendedAt != null)
                      LtrText(Formatters.date(p.suspendedAt, fromUtc: true), style: UType.caption(color: ink)),
                  ],
                ),
                Text(body, style: UType.label(color: ink)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
