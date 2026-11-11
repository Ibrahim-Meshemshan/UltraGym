import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../branches/presentation/bloc/branch_scope_cubit.dart';
import '../../../staff/presentation/widgets/staff_cells.dart';
import '../../domain/models/reception_device_models.dart';
import '../bloc/reception_devices_cubit.dart';
import 'device_actions.dart';

/// "الأجهزة المسجلة" (`ReceptionDevices.html`): الجهاز والمعرّف المختصر، الفرع، آخر تحميل، آخر مزامنة،
/// الحالة، و "إيقاف" للمالك على الفعّال. الخادم لا يرسل من سجّل الجهاز ولا عدد العمليات المنتظرة.
class DevicesTable extends StatelessWidget {
  const DevicesTable({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final list = context.read<ReceptionDevicesCubit>();
    final state = context.watch<ReceptionDevicesCubit>().state;
    final owner = context.select<AuthBloc, bool>((b) => b.state.session?.isClubOwner ?? false);
    final branches = context.select<BranchScopeCubit, List<FormOption<int>>>(
      (b) => b.state.branchId != null || !b.state.canChoose
          ? const []
          : [for (final x in b.state.active) (value: x.id, label: x.name)],
    );
    final now = sl<ServerClock>().now();

    Widget? action(ReceptionDevice d) => owner && d.isActive
        ? TextButton(
            onPressed: () async {
              if (await DeviceActions.revoke(context, d)) await list.refresh(keepPage: true);
            },
            style: TextButton.styleFrom(foregroundColor: c.dangerInk),
            child: const Text('إيقاف'),
          )
        : null;

    return PagedTable<ReceptionDevice>(
      state: state,
      noun: 'جهازاً',
      minWidth: AppSize.devicesTableMin,
      onPage: list.goTo,
      onRetry: list.load,
      onClearFilters: list.clearFilters,
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.s3,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpace.s3,
            children: [
              Text('الأجهزة المسجلة', style: UType.h3(color: c.ink)),
              Text('الإيقاف للمالك فقط', style: UType.caption(color: c.inkMuted)),
            ],
          ),
          FilterBar(
            search: '',
            onSearch: null,
            onClear: state.query.hasFilters ? list.clearFilters : null,
            filters: [
              if (branches.isNotEmpty)
                FilterMenu<int>(
                  label: 'الفرع',
                  options: branches,
                  value: state.query.filter('branch_id') as int?,
                  onChanged: (v) => list.filter('branch_id', v),
                ),
            ],
            chips: FilterChoiceChips<String>(
              semanticsLabel: 'حالة الجهاز',
              options: DeviceTexts.statuses,
              value: state.query.filter('status') as String?,
              onChanged: (v) => list.filter('status', v),
            ),
          ),
        ],
      ),
      empty: const AppEmptyState(
        icon: Icons.devices_other_rounded,
        title: 'لا أجهزة استقبال بعد',
        message: 'افتح شاشة الاستقبال على الجهاز وسجّله باسم وفرع، فيظهر هنا تلقائياً.',
      ),
      mobileItem: (context, d) => StaffMobileCard(
        person: _DeviceName(d),
        badge: DeviceTexts.status(d),
        menu: action(d),
        lines: [
          (label: 'الفرع', value: d.branchName ?? '—', ltr: false),
          (label: 'آخر تحميل', value: DeviceTexts.pack(d, now), ltr: false),
          (label: 'آخر مزامنة', value: DeviceTexts.sync(d, now), ltr: false),
        ],
      ),
      columns: [
        TableCol('الجهاز', flex: 3, cell: (context, d) => _DeviceName(d)),
        TableCol('الفرع', flex: 2, cell: (context, d) => MutedCell(d.branchName ?? '—')),
        TableCol('آخر تحميل للبيانات', flex: 2, cell: (context, d) => MutedCell(DeviceTexts.pack(d, now))),
        TableCol('آخر مزامنة', flex: 2, cell: (context, d) => MutedCell(DeviceTexts.sync(d, now))),
        TableCol('الحالة', flex: 1, cell: (context, d) => BadgeCell(DeviceTexts.status(d))),
        TableCol('إجراءات', width: AppSize.actionsCol, cell: (context, d) => action(d) ?? const SizedBox.shrink()),
      ],
    );
  }
}

/// اسم الجهاز ومعرّفه المختصر (LTR).
class _DeviceName extends StatelessWidget {
  const _DeviceName(this.device);

  final ReceptionDevice device;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(device.name, style: UType.body(color: c.ink).weight(600), maxLines: 1, overflow: TextOverflow.ellipsis),
        Tooltip(
          message: device.uuid,
          child: LtrText(device.shortUuid, style: UType.caption(color: c.inkFaint)),
        ),
      ],
    );
  }
}
