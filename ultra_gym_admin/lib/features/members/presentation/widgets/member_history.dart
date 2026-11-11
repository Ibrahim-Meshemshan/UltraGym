import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../domain/models/member_profile_models.dart';
import '../bloc/member_profile_cubit.dart';
import 'history_columns.dart';

/// سجل العضو بتبويبات (الاشتراكات، الحضور، الدفعات): جدول مقسّم لكل تبويب، يُحمَّل عند فتحه.
class MemberHistoryCard extends StatelessWidget {
  const MemberHistoryCard({super.key, required this.memberId});

  final int memberId;

  static const _tabs = <AppTab>[
    (label: 'الاشتراكات', count: null),
    (label: 'الحضور', count: null),
    (label: 'الدفعات', count: null),
  ];

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => ValueCubit(MemberHistoryTab.memberships),
    child: BlocBuilder<ValueCubit<MemberHistoryTab>, MemberHistoryTab>(
      builder: (context, tab) {
        final header = Padding(
          padding: const EdgeInsetsDirectional.only(start: AppSpace.s5, end: AppSpace.s5, top: AppSpace.s2),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: AppTabs(
              tabs: _tabs,
              selected: tab.index,
              onSelect: (i) => context.read<ValueCubit<MemberHistoryTab>>().set(MemberHistoryTab.values[i]),
            ),
          ),
        );
        return switch (tab) {
          MemberHistoryTab.memberships => _History<MembershipItem>(
            key: const ValueKey(MemberHistoryTab.memberships),
            id: memberId,
            header: header,
            columns: HistoryColumns.memberships,
            mobileItem: HistoryColumns.membershipMobile,
            onRowTap: (m) => context.go(Routes.child(Routes.memberships, m.id)),
            noun: 'اشتراكاً',
            empty: const EmptyState(
              icon: Icons.card_membership_rounded,
              title: 'لا اشتراكات بعد',
              message: 'اشتراكات العضو وتجديداته تظهر هنا بحالتها ودينها.',
            ),
          ),
          MemberHistoryTab.attendance => _History<AttendanceEntry>(
            key: const ValueKey(MemberHistoryTab.attendance),
            id: memberId,
            header: header,
            columns: HistoryColumns.attendance,
            mobileItem: HistoryColumns.attendanceMobile,
            noun: 'زيارة',
            empty: const EmptyState(
              icon: Icons.login_rounded,
              title: 'لا زيارات بعد',
              message: 'كل دخول للنادي (مقبول أو مرفوض) يظهر هنا بوقته وفرعه.',
            ),
          ),
          MemberHistoryTab.payments => _History<PaymentEntry>(
            key: const ValueKey(MemberHistoryTab.payments),
            id: memberId,
            header: header,
            columns: HistoryColumns.payments,
            mobileItem: HistoryColumns.paymentMobile,
            noun: 'حركة',
            empty: const EmptyState(
              icon: Icons.receipt_long_rounded,
              title: 'لا دفعات بعد',
              message: 'دفعات العضو واسترجاعاته تظهر هنا بإيصالاتها.',
            ),
          ),
        };
      },
    ),
  );
}

/// تبويب واحد: Cubit خاص به (`MemberHistoryCubit<T>`) + `PagedTable`.
class _History<T> extends StatelessWidget {
  const _History({
    super.key,
    required this.id,
    required this.header,
    required this.columns,
    required this.mobileItem,
    required this.noun,
    required this.empty,
    this.onRowTap,
  });

  final int id;
  final Widget header;
  final List<TableCol<T>> columns;
  final Widget Function(BuildContext context, T row) mobileItem;
  final String noun;
  final Widget empty;
  final ValueChanged<T>? onRowTap;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => sl<MemberHistoryCubit<T>>(param1: id)..load(),
    child: BlocBuilder<MemberHistoryCubit<T>, ListState<T>>(
      builder: (context, state) {
        final cubit = context.read<MemberHistoryCubit<T>>();
        return PagedTable<T>(
          state: state,
          columns: columns,
          onPage: cubit.goTo,
          onRetry: cubit.load,
          empty: empty,
          header: header,
          mobileItem: mobileItem,
          onRowTap: onRowTap,
          noun: noun,
          minWidth: AppSize.historyTableMin,
        );
      },
    ),
  );
}
