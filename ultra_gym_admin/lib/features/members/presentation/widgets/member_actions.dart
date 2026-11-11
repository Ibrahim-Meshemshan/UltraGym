import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../domain/models/member_models.dart';
import '../bloc/members_cubit.dart';

/// قائمة "إجراءات العضو" (⋯) بآخر الصف: فتح الملف، والأرشفة أو الاسترجاع للمالك فقط.
class MemberRowMenu extends StatelessWidget {
  const MemberRowMenu(this.member, {super.key, required this.isOwner});

  final MemberRow member;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final archived = member.isArchived;
    return MenuAnchor(
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(Icons.person_outline_rounded, size: AppSize.iconSm),
          onPressed: () => context.go(Routes.child(Routes.members, member.id)),
          child: const Text('فتح الملف'),
        ),
        if (isOwner && !archived)
          MenuItemButton(
            leadingIcon: Icon(Icons.inventory_2_outlined, size: AppSize.iconSm, color: c.dangerInk),
            onPressed: () => archiveMember(context, member),
            child: Text('أرشفة', style: UType.body(color: c.dangerInk)),
          ),
        if (isOwner && archived)
          MenuItemButton(
            leadingIcon: const Icon(Icons.restore_rounded, size: AppSize.iconSm),
            onPressed: () => restoreMember(context, member),
            child: const Text('استرجاع'),
          ),
      ],
      builder: (context, menu, _) => IconButton(
        tooltip: 'إجراءات العضو',
        onPressed: () => menu.isOpen ? menu.close() : menu.open(),
        icon: Icon(Icons.more_horiz_rounded, color: c.inkMuted),
      ),
    );
  }
}

/// أرشفة بعد تأكيد. الخادم يرفض (409) إن بقي عليه دين أو اشتراك فعّال، والرسالة تظهر بالنافذة.
Future<void> archiveMember(BuildContext context, MemberRow member) async {
  final list = context.read<MembersListCubit>();
  final done = await FormDialog.confirm<void>(
    context,
    title: 'أرشفة ${member.name}؟',
    message: 'يختفي من قائمة الأعضاء ويبقى سجله وحركاته المالية، ويمكنك استرجاعه من الأرشيف بأي وقت.',
    confirmLabel: 'أرشفة',
    icon: Icons.inventory_2_outlined,
    onConfirm: () => list.archive(member.id),
  );
  if (done != null && context.mounted) refreshMembers(context);
}

Future<void> restoreMember(BuildContext context, MemberRow member) async {
  final list = context.read<MembersListCubit>();
  final done = await FormDialog.confirm<void>(
    context,
    title: 'استرجاع ${member.name}؟',
    message: 'يعود لقائمة الأعضاء بنفس حسابه وسجله.',
    confirmLabel: 'استرجاع',
    icon: Icons.restore_rounded,
    danger: false,
    onConfirm: () => list.restore(member.id),
  );
  if (done != null && context.mounted) refreshMembers(context);
}

/// بعد أي تغيير (إضافة، أرشفة، استرجاع): الصفحة الحالية والعدّادان بصمت.
void refreshMembers(BuildContext context) {
  context.read<MembersListCubit>().refresh(keepPage: true);
  context.read<MemberCountsCubit>().refresh();
}
