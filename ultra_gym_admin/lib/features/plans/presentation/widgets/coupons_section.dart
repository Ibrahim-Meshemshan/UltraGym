import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../domain/models/plans_models.dart';
import '../bloc/plans_cubit.dart';
import 'coupon_actions.dart';

/// الكوبونات (`Plans.html`، للمالك فقط): "كوبون جديد"، البحث بالكود والحالة، ثم الجدول بالخصم والصلاحية
/// والاستخدام والخطط المشمولة والحالة، و "تعديل" / حذف غير المستعمل.
class CouponsSection extends StatelessWidget {
  const CouponsSection({super.key});

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(create: (_) => sl<CouponsCubit>()..load()),
      BlocProvider(create: (_) => sl<CouponPlansCubit>()..load()),
    ],
    child: const _Body(),
  );
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final list = context.read<CouponsCubit>();
    final state = context.watch<CouponsCubit>().state;
    final plans = context.select<CouponPlansCubit, List<Plan>>((p) => p.state.data ?? const []);
    Future<void> save([Coupon? coupon]) async {
      if (await CouponActions.save(context, coupon: coupon, plans: plans)) await list.refresh(keepPage: true);
    }

    Future<void> delete(Coupon coupon) async {
      if (await CouponActions.delete(context, coupon)) await list.refresh(keepPage: true);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.s4,
      children: [
        Row(
          spacing: AppSpace.s3,
          children: [
            Expanded(
              child: Text(
                'الاستقبال يطبّق الكوبون بكوده عند البيع، والخادم يفحصه: فعّال، بدأ، لم ينتهِ، لم يُستنفد، ويشمل الخطة.',
                style: UType.label(color: c.inkMuted),
              ),
            ),
            UGButton(label: 'كوبون جديد', icon: Icons.add_rounded, onPressed: save),
          ],
        ),
        PagedTable<Coupon>(
          state: state,
          noun: 'كوبوناً',
          minWidth: AppSize.couponsTableMin,
          onPage: list.goTo,
          onRetry: list.load,
          onClearFilters: list.clearFilters,
          header: FilterBar(
            search: state.query.search,
            onSearch: list.search,
            hint: 'ابحث بالكود',
            filters: [
              FilterMenu<String>(
                label: 'الحالة',
                value: state.query.filter(PlanFilters.status) as String?,
                options: const [(value: 'active', label: 'فعّال'), (value: 'inactive', label: 'متوقف')],
                onChanged: (v) => list.filter(PlanFilters.status, v),
              ),
            ],
            onClear: state.query.hasFilters ? list.clearFilters : null,
          ),
          empty: EmptyState(
            icon: Icons.local_offer_rounded,
            title: 'لا كوبونات بعد',
            message: 'أنشئ كوداً بخصم نسبة أو مبلغ ليطبّقه الاستقبال عند البيع.',
            actionLabel: 'كوبون جديد',
            onAction: save,
          ),
          mobileItem: (context, x) => _MobileCoupon(x, plans: plans, onEdit: () => save(x), onDelete: () => delete(x)),
          onRowTap: save,
          columns: [
            TableCol(
              'الكود',
              flex: 3,
              cell: (c, x) => LtrText(x.code, style: UType.body(color: c.colors.ink).weight(700)),
            ),
            TableCol('الخصم', flex: 2, cell: (c, x) => LtrText(PlanTexts.discount(x), style: UType.body(color: c.colors.ink))),
            TableCol('الصلاحية', flex: 4, cell: (c, x) => _Validity(x)),
            TableCol('الاستخدام', flex: 3, cell: (c, x) => _Usage(x)),
            TableCol(
              'يشمل',
              flex: 3,
              cell: (c, x) => Text(
                PlanTexts.couponPlans(x, plans),
                style: UType.label(color: c.colors.inkMuted),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TableCol('الحالة', flex: 2, cell: (c, x) => _Status(x)),
            TableCol(
              '',
              width: AppSize.ledgerActionsCol,
              cell: (c, x) => _Actions(onEdit: () => save(x), onDelete: x.canDelete ? () => delete(x) : null, code: x.code),
            ),
          ],
        ),
      ],
    );
  }
}

class _Validity extends StatelessWidget {
  const _Validity(this.x);

  final Coupon x;

  @override
  Widget build(BuildContext context) {
    final style = UType.label(color: context.colors.inkMuted);
    if (x.startsOn == null && x.endsOn == null) return Text('بلا تاريخ', style: style);
    return Wrap(
      spacing: AppSpace.s1,
      children: [
        LtrText(x.startsOn ?? '…', style: style),
        Text('←', style: style),
        LtrText(x.endsOn ?? 'مفتوح', style: style),
      ],
    );
  }
}

class _Usage extends StatelessWidget {
  const _Usage(this.x);

  final Coupon x;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final usage = x.usage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpace.s1,
      children: [
        LtrText(PlanTexts.uses(x), style: UType.label(color: c.ink)),
        if (usage != null)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSize.usageBar),
            child: ClipRRect(
              borderRadius: AppRadius.fullAll,
              child: LinearProgressIndicator(
                value: usage,
                minHeight: AppSpace.s1,
                color: c.primary,
                backgroundColor: c.surfaceAlt,
              ),
            ),
          ),
      ],
    );
  }
}

class _Status extends StatelessWidget {
  const _Status(this.x);

  final Coupon x;

  @override
  Widget build(BuildContext context) =>
      StatusBadge(x.active ? 'فعّال' : 'متوقف', tone: x.active ? UTone.success : UTone.neutral);
}

class _Actions extends StatelessWidget {
  const _Actions({required this.onEdit, required this.onDelete, required this.code});

  final VoidCallback onEdit;
  final VoidCallback? onDelete;
  final String code;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      TextButton(onPressed: onEdit, child: const Text('تعديل')),
      if (onDelete != null)
        IconButton(
          tooltip: 'حذف $code',
          onPressed: onDelete,
          color: context.colors.dangerInk,
          icon: const Icon(Icons.delete_outline_rounded),
        ),
    ],
  );
}

class _MobileCoupon extends StatelessWidget {
  const _MobileCoupon(this.x, {required this.plans, required this.onEdit, required this.onDelete});

  final Coupon x;
  final List<Plan> plans;
  final VoidCallback onEdit, onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final muted = UType.caption(color: c.inkMuted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.s2,
      children: [
        Row(
          spacing: AppSpace.s2,
          children: [
            LtrText(x.code, style: UType.body(color: c.ink).weight(700)),
            LtrText(PlanTexts.discount(x), style: UType.label(color: c.inkMuted)),
            const Spacer(),
            _Status(x),
          ],
        ),
        _Validity(x),
        _Usage(x),
        Text(PlanTexts.couponPlans(x, plans), style: muted),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: _Actions(onEdit: onEdit, onDelete: x.canDelete ? onDelete : null, code: x.code),
        ),
      ],
    );
  }
}
