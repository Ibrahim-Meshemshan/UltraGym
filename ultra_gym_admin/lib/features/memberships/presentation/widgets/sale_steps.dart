import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../members/presentation/widgets/member_cells.dart';
import '../../../quick_search/presentation/widgets/quick_search_button.dart';
import '../../domain/models/sale_models.dart';
import '../bloc/sell_membership_cubit.dart';

/// بطاقة خطوة مرقّمة (`.step` بالنموذج): الرقم المائل والعنوان، وعنصر جانبي اختياري.
class SaleStep extends StatelessWidget {
  const SaleStep({super.key, required this.number, required this.title, required this.child, this.trailing});

  final int number;
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => CutCard(
    padding: const EdgeInsets.all(AppSpace.s5),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.s4,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpace.s3,
          runSpacing: AppSpace.s2,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: AppSpace.s3,
              children: [
                ExcludeSemantics(child: SlantTag('$number')),
                Semantics(
                  header: true,
                  child: Text(title, style: UType.h3(color: context.colors.ink)),
                ),
              ],
            ),
            ?trailing,
          ],
        ),
        child,
      ],
    ),
  );
}

/// الخطوة 1: العضو. يُختار بالبحث السريع، أو يأتي من الرابط (ملف العضو).
class SaleMemberStep extends StatelessWidget {
  const SaleMemberStep({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SellMembershipCubit>();
    final slice = context.select<SellMembershipCubit, Slice<SaleMember>>((c) => c.state.member);
    Future<void> pick() async {
      final p = await QuickSearch.pick(context);
      if (p != null) cubit.pickMember(SaleMember.fromLookup(p));
    }

    return SaleStep(
      number: 1,
      title: 'العضو',
      child: switch (slice) {
        Slice(isFirstLoad: true, isLoading: true) => const ListShimmer(count: 1),
        Slice(data: final m?) => _MemberRow(m, onChange: pick),
        Slice(failure: final f?) => ErrorState(failure: f, onRetry: cubit.retryMember, compact: true),
        _ => Align(
          alignment: AlignmentDirectional.centerStart,
          child: UGButton(
            label: 'اختيار العضو',
            icon: Icons.person_search_rounded,
            kind: UButtonKind.secondary,
            onPressed: pick,
          ),
        ),
      },
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow(this.m, {required this.onChange});

  final SaleMember m;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ids = [m.memberCode, m.phone].whereType<String>().join(' · ');
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpace.s3,
      runSpacing: AppSpace.s3,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpace.s3,
          children: [
            MemberAvatar(m.name),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.name, style: UType.bodyLg(color: c.ink).weight(600)),
                  if (ids.isNotEmpty) LtrText(ids, style: UType.caption(color: c.inkMuted)),
                  if (m.dueUsd > 0)
                    Text(
                      // الدين قد يكون على اشتراكه الحالي أو منتهٍ: لا نقول أيهما.
                      'عليه دين سابق ${Formatters.ltr(Formatters.usd(m.dueUsd))}',
                      style: UType.caption(color: c.warningInk),
                    ),
                ],
              ),
            ),
          ],
        ),
        switch (m.membershipStatus) {
          final s? => StatusBadge(m.membershipLabel ?? s, tone: Labels.membershipStatus(s).tone),
          null => const StatusBadge('بلا اشتراك', tone: UTone.neutral),
        },
        UGButton(label: 'تغيير العضو', icon: Icons.swap_horiz_rounded, kind: UButtonKind.ghost, onPressed: onChange),
      ],
    );
  }
}

/// الخطوة 2: الخطة (بطاقات اختيار) + المدرب لخطة التدريب الخاص.
class SalePlanStep extends StatelessWidget {
  const SalePlanStep({super.key, required this.scoped});

  /// الخطط مصفّاة بفرع البيع (الشريط العلوي على فرع محدد).
  final bool scoped;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SellMembershipCubit>();
    final (plans, planId, needsTrainer) = context.select<SellMembershipCubit, (Slice<List<SalePlan>>, int?, bool)>(
      (c) => (c.state.plans, c.state.planId, c.state.needsTrainer),
    );
    return SaleStep(
      number: 2,
      title: 'الخطة',
      trailing: Text(
        scoped ? 'الخطط الفعّالة التي تشمل هذا الفرع' : 'الخطط الفعّالة',
        style: UType.caption(color: context.colors.inkMuted),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.s4,
        children: [
          SliceView<List<SalePlan>>(
            slice: plans,
            loading: const StatsShimmer(),
            onRetry: cubit.retryPlans,
            isEmpty: (list) => list.isEmpty,
            empty: const AppEmptyState(
              icon: Icons.style_rounded,
              title: 'لا خطط فعّالة',
              message: 'أضف خطة أو فعّل واحدة من "الخطط والكوبونات" ثم عد للبيع.',
            ),
            builder: (context, list) => Semantics(
              label: 'الخطة',
              child: ResponsiveGrid(
                maxColumns: 3,
                children: [
                  for (final p in list) _PlanCard(p, selected: p.id == planId, onTap: () => cubit.selectPlan(p.id)),
                ],
              ),
            ),
          ),
          if (needsTrainer) const _TrainerField(),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard(this.p, {required this.selected, required this.onTap});

  final SalePlan p;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final kind = p.isSessions
        ? 'بالجلسات · ${p.sessionsCount ?? 0} جلسة خلال ${Formatters.days(p.durationDays)}'
        : 'بالمدة · ${Formatters.days(p.durationDays)}';
    final scope = p.allBranches ? 'كل الفروع' : p.branchNames.join('، ');
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Material(
        color: selected ? c.primarySoft : c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.fieldAll,
          side: BorderSide(color: selected ? c.primary : c.line, width: selected ? 2 : 1),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.fieldAll,
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpace.s1,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(p.name, style: UType.bodyLg(color: c.ink).weight(600)),
                    ),
                    Icon(
                      selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                      size: AppSize.iconSm,
                      color: selected ? c.primary : c.inkFaint,
                    ),
                  ],
                ),
                Text('$kind · $scope', style: UType.caption(color: c.inkMuted)),
                if (p.isPersonal) const StatusBadge('يحتاج مدرباً', tone: UTone.primary),
                AppSpace.gap1,
                LtrText(Formatters.usd(p.priceUsd), style: UType.stat(color: c.ink)),
                LtrText(Formatters.syp(p.priceSyp), style: UType.caption(color: c.inkMuted)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// المدرب إلزامي لخطة التدريب الخاص (`trainer_id`)؛ القائمة تُطلب أول مرة تُختار فيها خطة كهذه.
class _TrainerField extends StatelessWidget {
  const _TrainerField();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SellMembershipCubit>();
    final trainers = context.select<SellMembershipCubit, Slice<List<SaleTrainer>>>((c) => c.state.trainers);
    return SliceView<List<SaleTrainer>>(
      slice: trainers,
      loading: const ListShimmer(count: 1),
      onRetry: cubit.loadTrainers,
      isEmpty: (list) => list.isEmpty,
      empty: Text(
        'لا مدربين فعّالين. أضف مدرباً من "المدربون والتدريب" لبيع خطة تدريب خاص.',
        style: UType.body(color: context.colors.warningInk),
      ),
      builder: (context, list) => FormDropdown<int>(
        'trainer_id',
        label: 'المدرب',
        required: true,
        hint: 'اختر المدرب',
        options: [
          for (final t in list) (value: t.id, label: t.branchName == null ? t.name : '${t.name} · ${t.branchName}'),
        ],
      ),
    );
  }
}
