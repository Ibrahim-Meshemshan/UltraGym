import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../quick_search/presentation/widgets/quick_search_button.dart';
import '../../domain/models/training_models.dart';
import '../bloc/training_cubits.dart';
import 'measurement_actions.dart';
import 'measurement_values.dart';
import 'measurements_table.dart';

/// تبويب "القياسات": اختيار العضو بالبحث (أو من `?player_id=`)، ثم آخر القيم والفرق منذ البداية، رسم الوزن، والجدول.
/// الإضافة والتعديل والحذف للمالك؛ الاستقبال يقرأ.
class MeasurementsSection extends StatelessWidget {
  const MeasurementsSection({super.key, required this.editable, this.playerId});

  final bool editable;

  /// عضو مبدئي من الرابط (ملف العضو).
  final int? playerId;

  @override
  Widget build(BuildContext context) {
    final id = playerId;
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ValueCubit<TrainingMember?>(null)),
        BlocProvider(create: (_) => ValueCubit<int>(1)),
        if (id != null) BlocProvider(create: (_) => sl<TrainingMemberCubit>(param1: id)..load()),
      ],
      child: _Body(editable: editable, initialId: id),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.editable, required this.initialId});

  final bool editable;
  final int? initialId;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final picked = context.watch<ValueCubit<TrainingMember?>>().state;
    final page = context.watch<ValueCubit<int>>().state;
    final initial = initialId == null ? null : context.watch<TrainingMemberCubit>().state.data;
    final member = picked ?? initial;
    final id = picked?.id ?? initialId;
    final name = member?.name ?? 'العضو';

    Future<void> pick() async {
      final p = await QuickSearch.pick(context);
      if (p == null || !context.mounted) return;
      context.read<ValueCubit<int>>().set(1);
      context.read<ValueCubit<TrainingMember?>>().set((id: p.id, name: p.name, memberCode: p.memberCode));
    }

    Future<void> add(int playerId, VoidCallback reload) async {
      if (!await MeasurementActions.save(context, playerId: playerId, playerName: name) || !context.mounted) return;
      // القياس الجديد بالصفحة الأولى (الأحدث أولاً).
      page == 1 ? reload() : context.read<ValueCubit<int>>().set(1);
    }

    // "قياس جديد" بالرأس فقط حين توجد قياسات: الفارغ فيه زره (زر أساسي واحد بالشاشة).
    Widget header({bool canAdd = false}) => Wrap(
      spacing: AppSpace.s3,
      runSpacing: AppSpace.s3,
      crossAxisAlignment: WrapCrossAlignment.end,
      alignment: WrapAlignment.spaceBetween,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSize.measureMemberMax),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const FieldLabel('العضو'),
              OutlinedButton.icon(
                onPressed: pick,
                icon: const Icon(Icons.person_search_rounded),
                label: Text(
                  member == null ? (id == null ? 'اختيار عضو' : '…') : [member.name, ?member.memberCode].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (editable && id != null && canAdd)
          Builder(
            builder: (context) => UGButton(
              label: 'قياس جديد',
              icon: Icons.add_rounded,
              onPressed: () => add(id, () => context.read<MeasurementsCubit>().refresh()),
            ),
          ),
      ],
    );

    return CutCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.s5),
        child: id == null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpace.s5,
                children: [
                  header(),
                  EmptyState(
                    icon: Icons.monitor_weight_outlined,
                    title: 'اختر عضواً لعرض قياساته',
                    message: 'ابحث بالاسم أو الموبايل أو المعرّف. القياسات يسجّلها النادي وتظهر للعضو بتطبيقه.',
                    actionLabel: 'اختيار عضو',
                    onAction: pick,
                  ),
                ],
              )
            : BlocProvider(
                key: ValueKey('measurements-$id-$page'),
                create: (_) => sl<MeasurementsCubit>(param1: (playerId: id, page: page))..load(),
                child: Builder(
                  builder: (context) {
                    final cubit = context.watch<MeasurementsCubit>();
                    final has = cubit.state.data?.items.isNotEmpty ?? false;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: AppSpace.s5,
                      children: [
                        header(canAdd: has),
                        SliceView<MeasurementsPage>(
                          slice: cubit.state,
                          onRetry: cubit.load,
                          loading: const DetailsShimmer(),
                          isEmpty: (p) => p.items.isEmpty,
                          empty: EmptyState(
                            icon: Icons.monitor_weight_outlined,
                            title: 'لا قياسات لـ $name بعد',
                            message: editable
                                ? 'سجّل أول قياس (الوزن مثلاً) ليتابع تقدمه من تطبيقه.'
                                : 'لم يُسجَّل له قياس بعد. القياسات يسجّلها مالك النادي.',
                            actionLabel: editable ? 'قياس جديد' : null,
                            onAction: editable ? () => add(id, cubit.refresh) : null,
                          ),
                          builder: (context, data) => _Content(
                            data: data,
                            first: page == 1,
                            onPage: context.read<ValueCubit<int>>().set,
                            onEdit: editable
                                ? (m) async {
                                    final ok = await MeasurementActions.save(
                                      context,
                                      playerId: id,
                                      playerName: name,
                                      existing: m,
                                    );
                                    if (ok) await cubit.refresh();
                                  }
                                : null,
                            onDelete: editable
                                ? (m) async {
                                    final ok = await MeasurementActions.delete(context, playerId: id, m: m);
                                    if (ok) await cubit.refresh();
                                  }
                                : null,
                          ),
                        ),
                        if (has)
                          Text(
                            'الوزن والعضل بـ kg، والدهون %، والمقاسات بـ cm. الفرق من أول قياس للعضو حتى آخره، ويرى العضو قياساته وتقدمه بتطبيقه.',
                            style: UType.caption(color: c.inkMuted),
                          ),
                      ],
                    );
                  },
                ),
              ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.data, required this.first, required this.onPage, this.onEdit, this.onDelete});

  final MeasurementsPage data;

  /// الصفحة الأولى فيها الأحدث: البطاقات والرسم منها فقط.
  final bool first;
  final ValueChanged<int> onPage;
  final ValueChanged<BodyMeasurement>? onEdit, onDelete;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: AppSpace.s5,
    children: [
      if (first) MeasurementValues(page: data),
      if (first && WeightTrend.pointsOf(data.items).length > 1) WeightTrend(items: data.items),
      MeasurementsTable(items: data.items, onEdit: onEdit, onDelete: onDelete),
      if (data.pagination.lastPage > 1) PaginationBar(pagination: data.pagination, onPage: onPage, noun: 'قياساً'),
    ],
  );
}
