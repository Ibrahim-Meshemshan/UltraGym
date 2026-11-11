import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../domain/models/member_profile_models.dart';
import '../bloc/member_profile_cubit.dart';
import '../widgets/member_history.dart';
import '../widgets/profile_cards.dart';
import '../widgets/profile_header.dart';

/// ملف العضو `/members/{id}` (`MemberProfile.html`): الرأس والأفعال، ثم عمودان (الاشتراك والسجل | البيانات والنشاط).
/// معرّف غير صالح = نفس حالة "غير موجود" من الخادم.
class MemberProfileScreen extends StatelessWidget {
  const MemberProfileScreen({super.key, required this.id});

  final int? id;

  @override
  Widget build(BuildContext context) {
    final id = this.id;
    if (id == null) {
      return const AppPage(
        children: [
          _BackLink(),
          EmptyState(
            icon: Icons.person_off_outlined,
            title: 'العضو غير موجود',
            message: 'الرابط غير صحيح. ابحث عن العضو من قائمة الأعضاء.',
          ),
        ],
      );
    }
    return BlocProvider(
      key: ValueKey(id),
      create: (_) => sl<MemberProfileCubit>(param1: id)..load(),
      child: BlocBuilder<MemberProfileCubit, Slice<MemberProfile>>(
        builder: (context, slice) => AppPage(
          children: [
            const _BackLink(),
            SliceView(
              slice: slice,
              loading: const _ProfileShimmer(),
              onRetry: context.read<MemberProfileCubit>().load,
              builder: (context, p) => _ProfileBody(p),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackLink extends StatelessWidget {
  const _BackLink();

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: TextButton.icon(
      onPressed: () => context.go(Routes.members),
      icon: const Icon(Icons.arrow_back_rounded, size: AppSize.iconSm),
      label: const Text('كل الأعضاء'),
    ),
  );
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody(this.p);

  final MemberProfile p;

  @override
  Widget build(BuildContext context) {
    final main = [CurrentMembershipCard(p), MemberHistoryCard(memberId: p.id)];
    final side = [
      MemberDataCard(p),
      ActivityCard(p),
      if (p.membership?.trainerName != null || p.measurement != null) TrainingCard(p),
      if (p.notes case final n? when n.trim().isNotEmpty) NotesCard(n),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.s4,
      children: [
        if (p.isArchived || p.isSuspended) ProfileNotice(p),
        ProfileHeader(p),
        LayoutBuilder(
          builder: (context, box) => box.maxWidth >= AppSize.profileSplit
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpace.s4,
                  children: [
                    Expanded(flex: 2, child: _Stack(main)),
                    Expanded(child: _Stack(side)),
                  ],
                )
              : _Stack([...main.take(1), ...side, ...main.skip(1)]),
        ),
      ],
    );
  }
}

class _Stack extends StatelessWidget {
  const _Stack(this.children);

  final List<Widget> children;

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: AppSpace.s4, children: children);
}

/// هيكل التحميل: رأس بصورة وسطرين، ثم بطاقتان بعمودين.
class _ProfileShimmer extends StatelessWidget {
  const _ProfileShimmer();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: AppSpace.s4,
    children: [
      const AppShimmer(
        child: ShimmerCard(
          child: Row(
            spacing: AppSpace.s5,
            children: [
              ShimmerBox(width: AppSize.profileAvatar, height: AppSize.profileAvatar),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpace.s3,
                  children: [
                    ShimmerBox(width: AppSize.gridItem, height: AppSpace.s5),
                    ShimmerBox(width: AppSize.searchPill, height: AppSpace.s3),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      LayoutBuilder(
        builder: (context, box) {
          const table = TableShimmer(rows: 5, columns: 4);
          const details = DetailsShimmer();
          return box.maxWidth >= AppSize.profileSplit
              ? const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpace.s4,
                  children: [
                    Expanded(flex: 2, child: table),
                    Expanded(child: details),
                  ],
                )
              : const Column(spacing: AppSpace.s4, children: [details, table]);
        },
      ),
    ],
  );
}
