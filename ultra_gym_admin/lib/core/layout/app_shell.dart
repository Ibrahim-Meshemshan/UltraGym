import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/models/auth_models.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/branches/presentation/bloc/branch_scope_cubit.dart';
import '../../features/branches/presentation/widgets/branch_picker.dart';
import '../../features/branches/presentation/widgets/cash_status_badge.dart';
import '../../features/club_plan/presentation/bloc/club_plan_cubit.dart';
import '../../features/club_plan/presentation/widgets/club_plan_banner.dart';
import '../../features/club_plan/presentation/widgets/plan_feature_locked.dart';
import '../../features/notifications/presentation/bloc/unread_count_cubit.dart';
import '../../features/notifications/presentation/widgets/notifications_button.dart';
import '../../features/quick_search/presentation/widgets/quick_search_button.dart';
import '../bloc/value_cubit.dart';
import '../config/app_config.dart';
import '../di/injection.dart';
import '../responsive/responsive.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'app_sidebar.dart';
import 'app_top_bar.dart';
import 'nav_config.dart';
import 'support_banner.dart';

/// هيكل ما بعد الدخول: `AppSidebar` + `AppTopBar` + شريط جلسة الدعم + محتوى القسم.
/// ≥1024 قائمة مفتوحة تُطوى بزر (`ToggleCubit`)، 600-1024 مطوية دائماً، <600 درج من زر القائمة.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.location, required this.child});

  /// مسار الصفحة الحالية: يحدد القسم المحدد وعنوان الشريط.
  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final s = context.read<AuthBloc>().state.session;
    final key = BranchScopeCubit.keyFor(tenantId: s?.tenant?.id, userId: s?.user.id ?? 0);
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ToggleCubit()),
        // الفرع الحالي بعمر الهيكل: يقرؤه كل قسم بـ context.read<BranchScopeCubit>().state.branchId
        BlocProvider(create: (_) => sl<BranchScopeCubit>(param1: key)..load()),
        // باقة النادي: ميزات القائمة وشريط اشتراك النادي بالمنصة
        BlocProvider(create: (_) => sl<ClubPlanCubit>(param1: s?.isClubOwner ?? false)..load()),
        // عدّاد الجرس: كل 60 ثانية بينما الواجهة ظاهرة
        BlocProvider(create: (_) => sl<UnreadCountCubit>()..start()),
      ],
      child: _ShellView(location: location, child: child),
    );
  }
}

class _ShellView extends StatelessWidget {
  const _ShellView({required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final session = context.select<AuthBloc, Session?>((b) => b.state.session);
    // لحظة الخروج: الراوتر سيعيد التوجيه للدخول.
    if (session == null) return ColoredBox(color: context.colors.bg);

    final current = AdminNav.entryFor(location);
    final title = current?.labelFor(session) ?? AppConfig.appTitle;
    // رابط قسم ميزته ليست بالباقة (القائمة تخفيه): صفحة "ليست ضمن باقتك" بدل المحتوى.
    final locked = !context.select<ClubPlanCubit, bool>((c) => c.state.has(current?.feature));
    final body = locked ? PlanFeatureLocked(owner: session.isClubOwner) : child;
    void open(NavEntry e) => context.go(e.route);

    if (context.isMobile) {
      return Scaffold(
        drawer: Drawer(
          width: AppSize.sidebar,
          backgroundColor: context.colors.sidebar,
          shape: const RoundedRectangleBorder(),
          child: Builder(
            builder: (drawer) => AppSidebar(
              session: session,
              selected: current,
              onSelect: (e) {
                Scaffold.of(drawer).closeDrawer();
                open(e);
              },
            ),
          ),
        ),
        body: SafeArea(
          child: _Content(
            session: session,
            title: title,
            actions: const [BranchPicker(compact: true), NotificationsButton()],
            leading: Builder(
              builder: (ctx) => TopBarIconButton(
                icon: Icons.menu_rounded,
                tooltip: 'القائمة',
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
            child: body,
          ),
        ),
      );
    }

    final folded = context.watch<ToggleCubit>().state;
    final desktop = context.isDesktop;
    return QuickSearchHotkey(
      child: _desktop(context, session, current, title, body, folded: folded, desktop: desktop, open: open),
    );
  }

  Widget _desktop(
    BuildContext context,
    Session session,
    NavEntry? current,
    String title,
    Widget body, {
    required bool folded,
    required bool desktop,
    required void Function(NavEntry) open,
  }) {
    return Scaffold(
      body: Row(
        children: [
          AppSidebar(session: session, selected: current, onSelect: open, collapsed: !desktop || folded),
          Expanded(
            child: _Content(
              session: session,
              title: title,
              actions: const [BranchPicker(), CashStatusBadge(), QuickSearchButton(), NotificationsButton()],
              leading: desktop
                  ? TopBarIconButton(
                      icon: folded ? Icons.menu_rounded : Icons.menu_open_rounded,
                      tooltip: folded ? 'فتح القائمة' : 'طيّ القائمة',
                      onPressed: context.read<ToggleCubit>().toggle,
                    )
                  : null,
              child: body,
            ),
          ),
        ],
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.session,
    required this.title,
    required this.child,
    this.leading,
    this.actions = const [],
  });

  final Session session;
  final String title;
  final Widget? leading;
  final List<Widget> actions;
  final Widget child;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.colors.bg,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTopBar(title: title, leading: leading, actions: actions),
        if (session.isImpersonated) SupportBanner(session: session),
        ClubPlanBanner(owner: session.isClubOwner),
        Expanded(child: child),
      ],
    ),
  );
}
