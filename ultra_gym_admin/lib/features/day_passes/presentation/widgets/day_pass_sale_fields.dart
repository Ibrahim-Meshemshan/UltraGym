import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../members/domain/models/member_models.dart';
import '../../../quick_search/presentation/widgets/lookup_tile.dart';
import '../../../quick_search/presentation/widgets/quick_search_button.dart';
import '../../domain/models/day_pass_models.dart';
import '../bloc/day_passes_cubit.dart';

/// أسماء حقول نموذج البيع (كما بجسم `POST day-passes`).
abstract final class DayPassFields {
  static const name = 'visitor_name', phone = 'visitor_phone', gender = 'gender', price = 'price_usd', notes = 'notes';
}

/// لمن يُباع: زائر (الاسم، الموبايل، والجنس بفرع أوقات منفصلة) أو عضو مسجّل يُختار بالبحث.
class DayPassBuyerFields extends StatelessWidget {
  const DayPassBuyerFields({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final cubit = context.read<DayPassSaleCubit>();
    final (buyer, player, genderRequired) = context.select<DayPassSaleCubit, (DayPassBuyer, Object?, bool)>(
      (c) => (c.state.buyer, c.state.player, c.state.price.data?.genderRequired ?? false),
    );
    final picked = cubit.state.player;
    // الحقول تسجّل تحققها مع البناء: المخفي منها (زائر ← عضو، أو فرع بلا أوقات منفصلة) لا يمنع الإرسال.
    final form = context.read<AppFormCubit>();
    if (buyer == DayPassBuyer.member) {
      form
        ..validator(DayPassFields.name, null)
        ..validator(DayPassFields.phone, null);
    }
    if (buyer == DayPassBuyer.member || !genderRequired) form.validator(DayPassFields.gender, null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.s3,
      children: [
        Wrap(
          spacing: AppSpace.s2,
          children: [
            for (final (b, label) in const [(DayPassBuyer.visitor, 'زائر'), (DayPassBuyer.member, 'عضو مسجّل')])
              ChoiceChip(label: Text(label), selected: buyer == b, onSelected: (_) => cubit.setBuyer(b)),
          ],
        ),
        if (buyer == DayPassBuyer.visitor) ...[
          FormText(
            DayPassFields.name,
            label: 'اسم الزائر',
            required: true,
            autofocus: true,
            validator: Validators.required('اكتب اسم الزائر.'),
          ),
          FormText(
            DayPassFields.phone,
            label: 'الموبايل',
            hint: '09xxxxxxxx',
            ltr: true,
            keyboardType: TextInputType.phone,
            validator: Validators.phone(optional: true),
          ),
          if (genderRequired)
            const FormDropdown<String>(
              DayPassFields.gender,
              label: 'الجنس',
              options: MemberFilters.genders,
              required: true,
              hint: 'مطلوب بفرع الأوقات المنفصلة',
            ),
        ] else ...[
          if (picked != null)
            LookupTile(player: picked, onTap: () => _pick(context))
          else
            Text(
              'لعضو بلا اشتراك صالح بهذا الفرع؛ من عنده اشتراك يُسجَّل دخوله العادي.',
              style: UType.caption(color: c.inkMuted),
            ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () => _pick(context),
              icon: const Icon(Icons.person_search_rounded),
              label: Text(player == null ? 'اختر العضو بالبحث' : 'تغيير العضو'),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _pick(BuildContext context) async {
    final picked = await QuickSearch.pick(context);
    if (picked == null || !context.mounted) return;
    context.read<DayPassSaleCubit>().pick(picked);
  }
}

/// سعر فرع البيع: للعرض، أو حقل السعر لمن يستطيع تغييره (المالك؛ 0 = يوم تجربة مجاني).
/// غير مفعّل، أو بلا سعر لمن لا يستطيع كتابته: سبب واضح والبيع معطّل.
class DayPassPriceBox extends StatelessWidget {
  const DayPassPriceBox({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final cubit = context.read<DayPassSaleCubit>();
    final slice = context.select<DayPassSaleCubit, Slice<DayPassPrice>>((c) => c.state.price);
    final p = slice.data;
    // حقل السعر (للمالك) قد يختفي مع تغيير الفرع: تحققه لا يبقى.
    if (p?.canChangePrice != true) context.read<AppFormCubit>().validator(DayPassFields.price, null);
    if (slice.isFirstLoad) return const AppShimmer(child: ShimmerBox(height: AppSize.control));
    if (p == null) {
      return ErrorState(failure: slice.failure!, compact: true, onRetry: cubit.retryPrice);
    }
    if (!p.enabled) return const _Note('الدخول اليومي غير مفعّل بإعدادات النادي.', tone: UTone.warning);
    if (!p.hasPrice && !p.canChangePrice) {
      return const _Note('لم يُحدد سعر للدخول اليومي بهذا الفرع. يحدده مالك النادي من الإعدادات.', tone: UTone.warning);
    }
    final shown = Wrap(
      spacing: AppSpace.s2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('السعر', style: UType.label(color: c.inkMuted)),
        if (p.hasPrice) ...[
          LtrText(Formatters.usd(p.priceUsd), style: UType.body(color: c.ink).weight(600)),
          if (p.priceSyp != null) LtrText(Formatters.syp(p.priceSyp), style: UType.label(color: c.inkMuted)),
        ] else
          Text('غير محدد بعد', style: UType.label(color: c.warningInk)),
        Text('· يُدفع كاملاً', style: UType.caption(color: c.inkMuted)),
      ],
    );
    if (!p.canChangePrice) return shown;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.s2,
      children: [
        shown,
        FormText(
          DayPassFields.price,
          label: 'سعر هذا الدخول بالدولار · للمالك',
          hint: '0 = يوم تجربة مجاني',
          ltr: true,
          required: !p.hasPrice,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: Validators.amount(optional: p.hasPrice),
        ),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text, {required this.tone});

  final String text;
  final UTone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (bg, fg) = tone == UTone.warning ? (c.warningSoft, c.warningInk) : (c.infoSoft, c.infoInk);
    return Container(
      padding: const EdgeInsets.all(AppSpace.s3),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.fieldAll),
      child: Text(text, style: UType.label(color: fg)),
    );
  }
}
