import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/models/notification_models.dart';
import '../bloc/notifications_list_cubit.dart';
import '../bloc/unread_count_cubit.dart';
import '../notification_links.dart';
import 'notification_tile.dart';

/// قائمة الجرس (`SystemStates.html` "الإشعارات"): العنوان مع عدد الجديد و"قراءة الكل"،
/// الإشعارات الأحدث أولاً (غير المقروء مميز)، "عرض المزيد"، ورابط إعدادات الإشعارات للمالك.
/// تُنشأ قائمتها مع كل فتح، فتُحدَّث كل مرة.
class NotificationsPanel extends StatelessWidget {
  const NotificationsPanel({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) {
      unawaited(context.read<UnreadCountCubit>().refresh());
      return sl<NotificationsListCubit>()..load();
    },
    child: const _PanelBody(),
  );
}

class _PanelBody extends StatelessWidget {
  const _PanelBody();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final count = context.watch<UnreadCountCubit>().state;
    final owner = context.select<AuthBloc, bool>((b) => b.state.session?.isClubOwner ?? false);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(AppSpace.s4, AppSpace.s2, AppSpace.s2, AppSpace.s2),
          child: Row(
            children: [
              Expanded(
                child: Text(count > 0 ? 'الإشعارات · $count جديدة' : 'الإشعارات', style: UType.h3(color: c.ink)),
              ),
              TextButton(onPressed: count > 0 ? () => _readAll(context) : null, child: const Text('قراءة الكل')),
            ],
          ),
        ),
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: AppSize.panelList),
            child: BlocBuilder<NotificationsListCubit, ListState<AppNotification>>(
              builder: (context, s) => SliceView<Paged<AppNotification>>(
                slice: s.slice,
                loading: const Padding(padding: EdgeInsets.all(AppSpace.s4), child: ListShimmer(count: 3)),
                frame: (child) => Padding(padding: const EdgeInsets.all(AppSpace.s4), child: child),
                onRetry: context.read<NotificationsListCubit>().load,
                isEmpty: (p) => p.isEmpty,
                empty: const _Empty(),
                builder: (context, page) => ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  children: [
                    for (final n in page.items) NotificationTile(notification: n, onTap: () => _open(context, n)),
                    if (s.slice.data?.hasMore ?? false) _More(state: s),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (owner) ...[
          Divider(height: 1, color: c.line),
          Padding(
            padding: const EdgeInsets.all(AppSpace.s1),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(onPressed: () => _go(context, Routes.settings), child: const Text('إعدادات الإشعارات')),
            ),
          ),
        ],
      ],
    );
  }

  /// يعلّمه مقروءاً (دون انتظار) ثم يفتح شاشته ويغلق القائمة.
  static void _open(BuildContext context, AppNotification n) {
    final count = context.read<UnreadCountCubit>();
    if (!n.isRead) {
      unawaited(
        context.read<NotificationsListCubit>().markRead(n).then((ok) {
          if (ok) count.decrement();
        }),
      );
    }
    final route = NotificationLinks.route(n);
    if (route != null) _go(context, route);
  }

  static void _go(BuildContext context, String route) {
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.go(route);
  }

  static Future<void> _readAll(BuildContext context) async {
    final count = context.read<UnreadCountCubit>();
    final r = await context.read<NotificationsListCubit>().markAllRead();
    switch (r) {
      case ApiSuccess():
        count.clear();
      case ApiFailure(:final failure):
        AppSnackbar.show(failure.message);
    }
  }
}

class _More extends StatelessWidget {
  const _More({required this.state});

  final ListState<AppNotification> state;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.s1),
        child: TextButton(
          onPressed: state.loadingMore ? null : context.read<NotificationsListCubit>().more,
          child: Text(state.moreFailure != null ? 'تعذّر التحميل. أعد المحاولة' : 'عرض المزيد'),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.s5, vertical: AppSpace.s8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none_rounded, size: AppSize.controlSm, color: c.inkFaint),
          AppSpace.gap3,
          Text('لا إشعارات بعد', style: UType.h3(color: c.ink)),
          AppSpace.gap1,
          Text(
            'تصلك هنا تنبيهات الاشتراكات والصندوق ورسائل المنصة.',
            style: UType.body(color: c.inkMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
