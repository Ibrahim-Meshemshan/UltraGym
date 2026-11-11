import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../data/repo/plans_repository.dart';
import '../../domain/models/plans_models.dart';

/// أفعال المالك على الكوبونات: إضافة وتعديل بنافذة واحدة (`Plans.html`)، وحذف غير المستعمل.
/// ترجع true إن تغيّر شيء (للتحديث).
abstract final class CouponActions {
  static const code = 'code',
      type = 'discount_type',
      value = 'discount_value',
      maxUses = 'max_uses',
      startsOn = 'starts_on',
      endsOn = 'ends_on',
      planIds = 'plan_ids',
      note = 'note',
      active = 'active';

  static final _codePattern = RegExp(r'^[A-Z0-9_-]{3,30}$');

  static String? _code(String? v) {
    final s = (v ?? '').trim().toUpperCase();
    if (s.isEmpty) return 'اكتب كود الكوبون.';
    return _codePattern.hasMatch(s) ? null : 'من 3 إلى 30 حرفاً لاتينياً أو رقماً (و - _).';
  }

  static String? _uses(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return null;
    final n = int.tryParse(s);
    return n == null || n < 1 ? 'اكتب عدداً صحيحاً من 1، أو اتركه فارغاً بلا حد.' : null;
  }

  static DateTime? _date(String? ymd) => ymd == null ? null : DateTime.tryParse(ymd);

  static String? _ymd(Object? v) => v is DateTime
      ? '${v.year.toString().padLeft(4, '0')}-${v.month.toString().padLeft(2, '0')}-${v.day.toString().padLeft(2, '0')}'
      : null;

  static Json bodyOf(AppFormCubit f) {
    final noteText = '${f.value(note) ?? ''}'.trim();
    return {
      code: '${f.value(code) ?? ''}'.trim().toUpperCase(),
      type: '${f.value(type)}',
      value: num.parse('${f.value(value)}'.replaceAll(',', '').trim()),
      maxUses: int.tryParse('${f.value(maxUses) ?? ''}'.trim()),
      startsOn: _ymd(f.value(startsOn)),
      endsOn: _ymd(f.value(endsOn)),
      planIds: [...?(f.value(planIds) as List<dynamic>?)?.whereType<int>()],
      note: noteText.isEmpty ? null : noteText,
      'status': f.value(active) == false ? 'inactive' : 'active',
    };
  }

  static Future<bool> save(BuildContext context, {Coupon? coupon, required List<Plan> plans}) async {
    final keeper = IdempotencyKeeper();
    final c = coupon;
    final done = await FormDialog.show<Coupon>(
      context,
      title: c == null ? 'كوبون جديد' : 'تعديل الكوبون',
      icon: Icons.local_offer_rounded,
      submitLabel: 'حفظ الكوبون',
      initial: {
        type: c == null || c.percent ? 'percent' : 'fixed',
        planIds: [...?c?.planIds],
        active: c?.active ?? true,
        if (c != null) ...{
          code: c.code,
          value: c.value % 1 == 0 ? '${c.value.toInt()}' : '${c.value}',
          if (c.maxUses != null) maxUses: '${c.maxUses}',
          startsOn: ?_date(c.startsOn),
          endsOn: ?_date(c.endsOn),
          note: ?c.note,
        },
      },
      fields: (form) => _CouponFields(plans: plans),
      onSubmit: (form) {
        final body = bodyOf(form);
        return sl<PlansRepository>().saveCoupon(
          body,
          id: c?.id,
          idempotencyKey: c == null ? keeper.keyFor(body) : null,
        );
      },
    );
    return done != null;
  }

  static Future<bool> delete(BuildContext context, Coupon coupon) async {
    final done = await FormDialog.confirm<void>(
      context,
      title: 'حذف الكوبون',
      message: 'سيُحذف الكوبون ${Formatters.ltr(coupon.code)} نهائياً. لم يُستعمل بأي اشتراك.',
      confirmLabel: 'حذف',
      icon: Icons.delete_outline_rounded,
      onConfirm: () => sl<PlansRepository>().deleteCoupon(coupon.id),
    );
    return done != null;
  }
}

class _CouponFields extends StatelessWidget {
  const _CouponFields({required this.plans});

  final List<Plan> plans;

  @override
  Widget build(BuildContext context) {
    final percent = context.select<AppFormCubit, bool>((f) => f.value(CouponActions.type) != 'fixed');
    return FormColumn(
      children: [
        const FormText(CouponActions.code, label: 'الكود', required: true, ltr: true, hint: 'WINTER25', validator: CouponActions._code),
        const FormChoice<String>(
          CouponActions.type,
          label: 'نوع الخصم',
          options: [(value: 'percent', label: 'نسبة %'), (value: 'fixed', label: r'مبلغ $')],
        ),
        FormText(
          CouponActions.value,
          // المفتاح يعيد بناء الحقل مع تغيير النوع فيتبدّل حدّ التحقق (100% للنسبة).
          key: ValueKey(percent),
          label: percent ? 'النسبة %' : 'المبلغ بالدولار',
          required: true,
          ltr: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: Validators.all([
            Validators.amount(message: 'اكتب قيمة الخصم بالأرقام.'),
            (v) => (num.tryParse((v ?? '').replaceAll(',', '').trim()) ?? 1) <= 0 ? 'الخصم أكبر من صفر.' : null,
            if (percent) (v) => (num.tryParse((v ?? '').trim()) ?? 0) > 100 ? 'النسبة لا تتجاوز 100.' : null,
          ]),
        ),
        const FormText(
          CouponActions.maxUses,
          label: 'أقصى عدد استخدامات',
          ltr: true,
          hint: 'بلا حد',
          keyboardType: TextInputType.number,
          validator: CouponActions._uses,
        ),
        const FormDate(CouponActions.startsOn, label: 'يبدأ'),
        const FormDate(CouponActions.endsOn, label: 'ينتهي'),
        if (plans.isNotEmpty)
          FormChips<int>(
            CouponActions.planIds,
            label: 'يشمل الخطط (بلا اختيار = كل الخطط)',
            options: [for (final p in plans) (value: p.id, label: p.name)],
          ),
        const FormText(CouponActions.note, label: 'ملاحظة', hint: 'مثلاً: عرض الشتاء'),
        const FormSwitch(CouponActions.active, label: 'فعّال', hint: 'الموقوف يرفضه البيع ويبقى ظاهراً هنا.'),
      ],
    );
  }
}
