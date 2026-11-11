import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../branches/presentation/bloc/branch_scope_cubit.dart';
import '../../data/repo/plans_repository.dart';
import '../../domain/models/plans_models.dart';
import 'plan_form_fields.dart';

typedef _F = PlanFormFields;

/// أفعال المالك على الخطط: إضافة وتعديل بنافذة واحدة، أرشفة واسترجاع. ترجع true إن تغيّر شيء (للتحديث).
abstract final class PlanActions {
  static List<({int id, String name})> _branches(BuildContext context) => [
    for (final b in context.read<BranchScopeCubit>().state.active) (id: b.id, name: b.name),
  ];

  static Json _initial(Plan? p) => {
    _F.type: p?.type ?? 'duration',
    _F.scope: p == null || p.allBranches ? 'all' : 'selected',
    _F.branchIds: [for (final b in p?.branches ?? const <({int id, String name})>[]) b.id],
    _F.personal: p?.isPersonal ?? false,
    _F.active: p?.active ?? true,
    if (p != null) ...{
      _F.name: p.name,
      _F.description: ?p.description,
      _F.days: '${p.durationDays}',
      if (p.sessionsCount != null) _F.sessions: '${p.sessionsCount}',
      _F.price: p.priceUsd % 1 == 0 ? '${p.priceUsd.toInt()}' : '${p.priceUsd}',
      // حدود النادي الافتراضية تبقى فارغة (null = افتراضي النادي).
      if (!p.defaultFreeze) ...{_F.freezes: '${p.maxFreezes}', _F.freezeDays: '${p.maxFreezeDays}'},
    },
  };

  static int? _int(Object? v) => int.tryParse('${v ?? ''}'.trim());

  /// الجسم الكامل (`POST` و `PATCH` بنفس الشكل): الحدود الفارغة null = افتراضي النادي.
  static Json bodyOf(AppFormCubit f, {required bool multiBranch}) {
    final type = '${f.value(_F.type)}';
    final selected = multiBranch && f.value(_F.scope) == 'selected';
    final description = '${f.value(_F.description) ?? ''}'.trim();
    return {
      _F.name: '${f.value(_F.name) ?? ''}'.trim(),
      _F.description: description.isEmpty ? null : description,
      _F.type: type,
      _F.days: _int(f.value(_F.days)),
      if (type == 'sessions') _F.sessions: _int(f.value(_F.sessions)),
      _F.price: num.parse('${f.value(_F.price)}'.replaceAll(',', '').trim()),
      _F.scope: selected ? 'selected' : 'all',
      if (selected) _F.branchIds: [...?(f.value(_F.branchIds) as List<dynamic>?)?.whereType<int>()],
      _F.freezes: _int(f.value(_F.freezes)),
      _F.freezeDays: _int(f.value(_F.freezeDays)),
      _F.personal: f.value(_F.personal) == true,
      'status': f.value(_F.active) == false ? 'inactive' : 'active',
    };
  }

  static Future<bool> save(BuildContext context, {Plan? plan}) async {
    final branches = _branches(context);
    final keeper = IdempotencyKeeper();
    final done = await FormDialog.show<Plan>(
      context,
      title: plan == null ? 'خطة جديدة' : 'تعديل خطة',
      icon: Icons.sell_rounded,
      submitLabel: 'حفظ الخطة',
      message: plan == null ? null : 'التعديل لا يغيّر الاشتراكات المباعة سابقاً.',
      initial: _initial(plan),
      fields: (_) => PlanFormFields(branches: branches),
      onSubmit: (form) {
        final body = bodyOf(form, multiBranch: branches.length > 1);
        return sl<PlansRepository>().savePlan(
          body,
          id: plan?.id,
          idempotencyKey: plan == null ? keeper.keyFor(body) : null,
        );
      },
    );
    return done != null;
  }

  static Future<bool> archive(BuildContext context, Plan plan) async {
    final done = await FormDialog.confirm<void>(
      context,
      title: 'أرشفة الخطة',
      message: 'ستُوقف "${plan.name}" وتنتقل للأرشيف. الاشتراكات المباعة منها لا تتأثر، ويمكن استرجاعها لاحقاً.',
      confirmLabel: 'أرشفة',
      icon: Icons.archive_outlined,
      onConfirm: () => sl<PlansRepository>().archivePlan(plan.id),
    );
    return done != null;
  }

  static Future<bool> restore(BuildContext context, Plan plan) async {
    final done = await FormDialog.confirm<Plan>(
      context,
      title: 'استرجاع الخطة',
      message: 'تعود "${plan.name}" لقائمة الخطط موقوفة، وتفعّلها من "تعديل" حين تريد بيعها.',
      confirmLabel: 'استرجاع',
      icon: Icons.unarchive_outlined,
      danger: false,
      onConfirm: () => sl<PlansRepository>().restorePlan(plan.id),
    );
    return done != null;
  }
}
