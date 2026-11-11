import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../branches/domain/models/branch_models.dart';
import '../../../branches/presentation/bloc/branch_scope_cubit.dart';
import '../../data/repo/settings_repository.dart';
import '../bloc/settings_cubits.dart';
import 'branch_schedule_card.dart';
import 'club_settings_cards.dart';

/// محرر الفرع (`BranchSettings.html`): بياناته وحالته ثم أقسام الذكور والإناث، و "حفظ التغييرات" يرسل الفرع كاملاً.
/// `branch` = null لفرع جديد. بعد الحفظ أو تغيير الحالة: تحديث القائمة ومحدد الفرع بالشريط العلوي.
class BranchEditor extends StatelessWidget {
  const BranchEditor({super.key, required this.branch, required this.onSaved, required this.onCancel});

  final Branch? branch;
  final ValueChanged<Branch> onSaved;
  final VoidCallback onCancel;

  Future<void> _save(BuildContext context) async {
    final saved = await context.read<BranchEditorCubit>().save();
    if (saved == null || !context.mounted) return;
    AppSnackbar.show(branch == null ? 'تمت إضافة الفرع.' : 'تم حفظ الفرع.');
    await _refreshAll(context);
    onSaved(saved);
  }

  static Future<void> _refreshAll(BuildContext context) async {
    final scope = context.read<BranchScopeCubit>();
    await context.read<SettingsBranchesCubit>().refresh();
    await scope.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final cubit = context.read<BranchEditorCubit>();
    final s = context.watch<BranchEditorCubit>().state;
    final d = s.draft;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.s5,
      children: [
        SettingsCard(
          title: branch == null ? 'فرع جديد' : 'بيانات الفرع',
          trailing: branch == null ? null : _BranchStatus(branch!, onChanged: () => _refreshAll(context)),
          children: [
            ResponsiveGrid(
              minItemWidth: AppSize.settingsFieldMin,
              maxColumns: 2,
              children: [
                DraftField(label: 'اسم الفرع', value: d.name, error: s.error('name'), onChanged: cubit.setName),
                DraftField(
                  label: 'الهاتف',
                  value: d.phone,
                  ltr: true,
                  error: s.error('phone'),
                  onChanged: cubit.setPhone,
                ),
                DraftField(label: 'المدينة', value: d.city, error: s.error('city'), onChanged: cubit.setCity),
                DraftField(label: 'العنوان', value: d.address, error: s.error('address'), onChanged: cubit.setAddress),
                DraftField(
                  label: r'سعر الدخول اليومي ($)',
                  value: d.price,
                  ltr: true,
                  hint: 'فارغ = سعر النادي',
                  error: s.error('day_pass_price_usd'),
                  onChanged: cubit.setPrice,
                ),
              ],
            ),
            if (branch case final b?)
              Text(
                b.isMain
                    ? 'الفرع الرئيسي لا يُوقف ولا يُؤرشف.'
                    : 'لا يُحذف فرع عليه حركات؛ يمكن إيقافه، والموقوف يُؤرشف.',
                style: UType.caption(color: c.inkMuted),
              ),
          ],
        ),
        const BranchScheduleCard(),
        if (s.failure case final f? when f.fieldErrors.isEmpty) Text(f.message, style: UType.label(color: c.dangerInk)),
        Wrap(
          spacing: AppSpace.s3,
          runSpacing: AppSpace.s2,
          children: [
            UGButton(
              label: s.saving ? 'جارٍ الحفظ…' : (branch == null ? 'إضافة الفرع' : 'حفظ التغييرات'),
              icon: Icons.check_rounded,
              onPressed: s.saving ? null : () => _save(context),
            ),
            TextButton(onPressed: s.saving ? null : onCancel, child: const Text('إلغاء')),
          ],
        ),
      ],
    );
  }
}

/// الشارات وأفعال الحالة: إيقاف / تفعيل (غير الرئيسي)، وأرشفة الموقوف.
class _BranchStatus extends StatelessWidget {
  const _BranchStatus(this.b, {required this.onChanged});

  final Branch b;
  final Future<void> Function() onChanged;

  Future<void> _status(BuildContext context) async {
    final stop = b.isActive;
    final ok = await FormDialog.confirm<Branch>(
      context,
      title: stop ? 'إيقاف ${b.name}' : 'تفعيل ${b.name}',
      message: stop
          ? 'لا بيع ولا دخول ولا صندوق بهذا الفرع حتى تفعّله، ويختفي من محدد الفرع. يلزم إغلاق ورديته أولاً.'
          : 'يعود الفرع للعمل ويظهر بمحدد الفرع.',
      confirmLabel: stop ? 'إيقاف الفرع' : 'تفعيل الفرع',
      danger: stop,
      icon: stop ? Icons.pause_circle_outline_rounded : Icons.play_circle_outline_rounded,
      successMessage: stop ? 'تم إيقاف الفرع.' : 'تم تفعيل الفرع.',
      onConfirm: () => sl<SettingsRepository>().setBranchStatus(b.id, stop ? 'inactive' : 'active'),
    );
    if (ok != null && context.mounted) await onChanged();
  }

  Future<void> _archive(BuildContext context) async {
    final ok = await FormDialog.confirm<void>(
      context,
      title: 'أرشفة ${b.name}',
      message: 'يختفي الفرع من القوائم، وتبقى حركاته وسجلاته بالتقارير.',
      confirmLabel: 'أرشفة',
      icon: Icons.archive_outlined,
      successMessage: 'تمت أرشفة الفرع.',
      onConfirm: () => sl<SettingsRepository>().archiveBranch(b.id),
    );
    if (ok != null && context.mounted) await onChanged();
  }

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpace.s2,
    runSpacing: AppSpace.s2,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      if (b.isMain) const StatusBadge('الفرع الرئيسي', tone: UTone.primary),
      StatusBadge(b.isActive ? 'فعّال' : 'موقوف', tone: b.isActive ? UTone.success : UTone.neutral),
      if (!b.isMain) TextButton(onPressed: () => _status(context), child: Text(b.isActive ? 'إيقاف' : 'تفعيل')),
      if (!b.isMain && !b.isActive)
        TextButton(
          onPressed: () => _archive(context),
          style: TextButton.styleFrom(foregroundColor: context.colors.dangerInk),
          child: const Text('أرشفة'),
        ),
    ],
  );
}
