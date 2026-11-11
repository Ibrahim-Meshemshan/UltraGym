import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ultragym_design/ultragym_design.dart';

import '../../features/auth/domain/models/auth_models.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/club_plan/presentation/bloc/club_plan_cubit.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import '../utils/labels.dart';
import 'nav_config.dart';
import 'nav_tile.dart';

/// القائمة الجانبية (`Dashboard.html`): داكنة بالثيمين، الشعار، مجموعات بعناوين، وحساب المستخدم بالأسفل.
/// مفتوحة 264 أو مطوية 76 (أيقونات + تلميحات)، وتتمرر إن طالت. لا زخرفة هنا.
///
/// لا نستعمل `UGSidebar` من الحزمة لأنه بلا عناوين مجموعات ولا تمرير (أقسام اللوحة 15).
class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    required this.session,
    required this.selected,
    required this.onSelect,
    this.collapsed = false,
  });

  final Session session;
  final NavEntry? selected;
  final ValueChanged<NavEntry> onSelect;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AnimatedContainer(
      duration: AppMotion.of(context, AppMotion.slow),
      curve: AppMotion.emphasized,
      width: collapsed ? AppSize.sidebarCollapsed : AppSize.sidebar,
      color: c.sidebar,
      child: Semantics(
        container: true,
        label: 'القائمة الرئيسية',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Brand(collapsed: collapsed),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpace.s3, AppSpace.s4, AppSpace.s3, AppSpace.s2),
                children: [
                  for (final g in AdminNav.visibleFor(session, has: context.watch<ClubPlanCubit>().state.has)) ...[
                    if (g.title != null) _GroupLabel(g.title!, collapsed: collapsed),
                    for (final e in g.entries)
                      NavTile(
                        icon: e.icon,
                        label: e.labelFor(session),
                        selected: identical(e, selected),
                        collapsed: collapsed,
                        onTap: () => onSelect(e),
                      ),
                  ],
                ],
              ),
            ),
            _Account(session: session, collapsed: collapsed),
          ],
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({required this.collapsed});

  final bool collapsed;

  @override
  Widget build(BuildContext context) => Container(
    height: AppSize.topBar,
    padding: const EdgeInsets.symmetric(horizontal: AppSpace.s5),
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: SidebarInk.of(context).divider)),
    ),
    alignment: collapsed ? Alignment.center : AlignmentDirectional.centerStart,
    child: UltraGymLogo(
      variant: collapsed ? ULogo.mark : ULogo.horizontal,
      onDark: context.isDark,
      height: collapsed ? 26 : 28,
    ),
  );
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.title, {required this.collapsed});

  final String title;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    if (collapsed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.s2, horizontal: AppSpace.s3),
        child: Divider(height: 1, color: SidebarInk.of(context).divider),
      );
    }
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(AppSpace.s3, AppSpace.s4, AppSpace.s3, AppSpace.s2),
      child: Semantics(
        header: true,
        child: Text(title, style: UType.caption(color: SidebarInk.of(context).groupLabel)),
      ),
    );
  }
}

/// المستخدم الحالي ودوره، وزر الخروج.
class _Account extends StatelessWidget {
  const _Account({required this.session, required this.collapsed});

  final Session session;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final role = Labels.role(session.isClubOwner ? 'club_owner' : session.roles.firstOrNull).text;
    final avatar = Tooltip(
      message: '${session.user.name} · $role',
      child: CircleAvatar(
        radius: AppSize.controlSm / 2,
        backgroundColor: c.primary,
        child: Text(_initial(session.user.name), style: UType.label(color: c.onPrimary).weight(600)),
      ),
    );
    final logout = IconButton(
      tooltip: 'تسجيل الخروج',
      onPressed: () => context.read<AuthBloc>().add(const AuthLogoutRequested()),
      icon: Icon(Icons.logout_rounded, size: AppSize.iconSm, color: c.sidebarInk),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.s4, vertical: AppSpace.s3),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: SidebarInk.of(context).divider)),
      ),
      child: collapsed
          ? Column(mainAxisSize: MainAxisSize.min, children: [avatar, AppSpace.gap1, logout])
          : Row(
              children: [
                avatar,
                AppSpace.gap3,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        session.user.name,
                        style: UType.label(color: SidebarInk.of(context).selectedText).weight(600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        role,
                        style: UType.caption(color: c.sidebarInk),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                logout,
              ],
            ),
    );
  }

  static String _initial(String name) => name.trim().isEmpty ? '؟' : String.fromCharCode(name.trim().runes.first);
}
