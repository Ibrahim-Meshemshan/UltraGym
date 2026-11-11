import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../domain/models/membership_detail_models.dart';
import '../bloc/membership_detail_cubit.dart';
import '../widgets/membership_account.dart';
import '../widgets/membership_header.dart';
import '../widgets/membership_tabs.dart';

/// تفاصيل الاشتراك `/memberships/{id}` (`MembershipDetail.html`): الرأس والأفعال والحقائق،
/// ثم التبويبات (الدفعات، التجميدات، الحضور) بجانب الحساب. معرّف غير صالح = "غير موجود" بلا طلب.
class MembershipDetailScreen extends StatelessWidget {
  const MembershipDetailScreen({super.key, required this.id});

  final int? id;

  @override
  Widget build(BuildContext context) {
    final id = this.id;
    if (id == null) {
      return const AppPage(
        children: [
          _BackLink(),
          AppEmptyState(
            icon: Icons.search_off_rounded,
            title: 'الاشتراك غير موجود',
            message: 'الرابط غير صحيح. افتح الاشتراك من قائمة الاشتراكات أو ملف العضو.',
          ),
        ],
      );
    }
    return BlocProvider(
      key: ValueKey(id),
      create: (_) => sl<MembershipDetailCubit>(param1: id)..load(),
      child: BlocBuilder<MembershipDetailCubit, Slice<MembershipDetail>>(
        builder: (context, slice) => AppPage(
          children: [
            const _BackLink(),
            SliceView(
              slice: slice,
              loading: const _DetailShimmer(),
              onRetry: context.read<MembershipDetailCubit>().load,
              builder: (context, d) => _Body(d),
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
      onPressed: () => context.go(Routes.memberships),
      icon: const Icon(Icons.arrow_back_rounded, size: AppSize.iconSm),
      label: const Text('كل الاشتراكات'),
    ),
  );
}

class _Body extends StatelessWidget {
  const _Body(this.d);

  final MembershipDetail d;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: AppSpace.s4,
    children: [
      if (d.isCancelled) CancelledNotice(d),
      MembershipHeader(d),
      LayoutBuilder(
        builder: (context, box) => box.maxWidth >= AppSize.profileSplit
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpace.s4,
                children: [
                  Expanded(flex: 2, child: MembershipTabsCard(d)),
                  Expanded(child: MembershipAccountCard(d)),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpace.s4,
                children: [MembershipAccountCard(d), MembershipTabsCard(d)],
              ),
      ),
    ],
  );
}

/// هيكل التحميل: رأس بسطرين ومربعات، ثم جدول بجانب بطاقة الحساب.
class _DetailShimmer extends StatelessWidget {
  const _DetailShimmer();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: AppSpace.s4,
    children: [
      const AppShimmer(
        child: ShimmerCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpace.s3,
            children: [
              ShimmerBox(width: AppSize.gridItem, height: AppSpace.s5),
              ShimmerBox(width: AppSize.searchPill, height: AppSpace.s3),
              ShimmerBox(height: AppSize.controlLg),
            ],
          ),
        ),
      ),
      LayoutBuilder(
        builder: (context, box) {
          const table = TableShimmer(rows: 4, columns: 5);
          const account = DetailsShimmer();
          return box.maxWidth >= AppSize.profileSplit
              ? const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpace.s4,
                  children: [
                    Expanded(flex: 2, child: table),
                    Expanded(child: account),
                  ],
                )
              : const Column(spacing: AppSpace.s4, children: [account, table]);
        },
      ),
    ],
  );
}
