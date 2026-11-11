import 'package:flutter/material.dart';

import '../../features/auth/domain/models/auth_models.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/station/presentation/bloc/active_branch_cubit.dart';
import '../core.dart';

/// الشريط العلوي للاستقبال (`Reception.html`): الفرع والتاريخ والقسم الحالي، شارة الاتصال، الثيم، والموظف.
class ReceptionTopBar extends StatelessWidget {
  const ReceptionTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final mobile = context.isMobile;
    return Container(
      constraints: const BoxConstraints(minHeight: AppSize.topBar),
      padding: EdgeInsets.symmetric(horizontal: mobile ? AppSpace.s4 : AppSpace.s6, vertical: AppSpace.s2),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Row(
        spacing: AppSpace.s3,
        children: [
          const Expanded(child: _BranchTitle()),
          const _ConnectionBadge(),
          IconButton(
            tooltip: Theme.of(context).brightness == Brightness.dark ? 'التبديل للوضع الفاتح' : 'التبديل للوضع الداكن',
            icon: Icon(Theme.of(context).brightness == Brightness.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
            onPressed: () => context.read<ThemeCubit>().select(
              Theme.of(context).brightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark,
            ),
          ),
          const _UserMenu(),
        ],
      ),
    );
  }
}

/// اسم الفرع (مع اختيار الفرع إن كان للموظف أكثر من فرع)، وتحته التاريخ والقسم الآن. تتحدث كل دقيقة.
class _BranchTitle extends StatelessWidget {
  const _BranchTitle();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.watch<ActiveBranchCubit>().state;
    final branch = s.branch;
    final branches = s.branches.data ?? const [];
    final name = Text(
      branch?.name ?? AppConfig.appTitle,
      style: UType.h3(color: c.ink),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (branches.length > 1)
          PopupMenuButton<int>(
            tooltip: 'تغيير الفرع',
            initialValue: branch?.id,
            onSelected: (id) => context.read<ActiveBranchCubit>().select(id),
            itemBuilder: (_) => [for (final b in branches) PopupMenuItem(value: b.id, child: Text(b.name))],
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [Flexible(child: name), Icon(Icons.expand_more_rounded, color: c.inkMuted)],
            ),
          )
        else
          name,
        if (branch != null)
          StreamBuilder<void>(
            stream: Stream.periodic(AppConfig.clockTick),
            builder: (context, _) {
              final now = Formatters.clubTime(sl<ServerClock>().now());
              final section = branch.sectionAt(now);
              return Text(
                [Formatters.date(now), if (section != null) 'قسم: $section الآن'].join(' · '),
                style: UType.caption(color: c.inkMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              );
            },
          ),
      ],
    );
  }
}

/// "متصل" أو "دون اتصال" من `ConnectionCubit` (لا شارة قبل أول فحص).
class _ConnectionBadge extends StatelessWidget {
  const _ConnectionBadge();

  @override
  Widget build(BuildContext context) => BlocBuilder<ConnectionCubit, ConnectionStatus>(
    bloc: sl<ConnectionCubit>(),
    builder: (context, status) => switch (status) {
      ConnectionStatus.online => const StatusBadge('متصل', tone: UTone.success),
      ConnectionStatus.offline => const StatusBadge('دون اتصال', tone: UTone.warning),
      ConnectionStatus.unknown => const SizedBox.shrink(),
    },
  );
}

/// الموظف: الأحرف الأولى والاسم (يختفي الاسم على الشاشة الضيقة)، والقائمة فيها الخروج.
class _UserMenu extends StatelessWidget {
  const _UserMenu();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final user = context.select<AuthBloc, Session?>((b) => b.state.session)?.user;
    if (user == null) return const SizedBox.shrink();
    return PopupMenuButton<void>(
      tooltip: 'الحساب',
      itemBuilder: (_) => [
        PopupMenuItem(
          onTap: () => context.read<AuthBloc>().add(const AuthLogoutRequested()),
          child: const Row(spacing: AppSpace.s2, children: [Icon(Icons.logout_rounded), Text('تسجيل الخروج')]),
        ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpace.s2,
        children: [
          InitialsAvatar(user.name, size: AppSize.controlSm, tone: UTone.neutral),
          if (!context.isMobile) Text(user.name, style: UType.label(color: c.ink)),
        ],
      ),
    );
  }
}
