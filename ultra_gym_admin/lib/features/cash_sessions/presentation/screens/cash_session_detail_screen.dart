import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../../branches/presentation/bloc/branch_scope_cubit.dart';
import '../../domain/models/cash_session_models.dart';
import '../bloc/cash_sessions_cubit.dart';
import '../widgets/cash_session_card.dart';
import '../widgets/cash_session_dialogs.dart';

/// تفاصيل وردية `/cash-sessions/{id}` (من صفوف السجل وإشعارات `cash_session`): نفس بطاقة الصندوق بفرعها،
/// المغلقة بالجرد والفرق، والمفتوحة بـ "إغلاق الوردية بالجرد". معرّف غير صالح = "غير موجودة" بلا طلب.
class CashSessionDetailScreen extends StatelessWidget {
  const CashSessionDetailScreen({super.key, required this.id});

  final int? id;

  @override
  Widget build(BuildContext context) {
    final id = this.id;
    if (id == null) {
      return const AppPage(
        children: [
          _BackLink(),
          EmptyState(
            icon: Icons.search_off_rounded,
            title: 'الوردية غير موجودة',
            message: 'الرابط غير صحيح. افتح الوردية من قائمة الورديات.',
          ),
        ],
      );
    }
    return BlocProvider(
      key: ValueKey(id),
      create: (_) => sl<CashSessionDetailCubit>(param1: id)..load(),
      child: BlocBuilder<CashSessionDetailCubit, Slice<CashSession>>(
        builder: (context, slice) => AppPage(
          children: [
            const _BackLink(),
            SliceView<CashSession>(
              slice: slice,
              loading: const DetailsShimmer(),
              onRetry: context.read<CashSessionDetailCubit>().load,
              builder: (context, s) => CashSessionCard(
                session: s,
                showBranch: true,
                onReport: () => CashSessionActions.report(s.id),
                onClose: () => _close(context, s),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _close(BuildContext context, CashSession s) async {
    final cubit = context.read<CashSessionDetailCubit>();
    final scope = context.read<BranchScopeCubit?>();
    if (await CashSessionActions.close(context, s) == null) return;
    unawaited(scope?.refresh());
    await cubit.refresh();
  }
}

class _BackLink extends StatelessWidget {
  const _BackLink();

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: TextButton.icon(
      onPressed: () => context.go(Routes.cashSessions),
      icon: const Icon(Icons.arrow_back_rounded, size: AppSize.iconSm),
      label: const Text('كل الورديات'),
    ),
  );
}
