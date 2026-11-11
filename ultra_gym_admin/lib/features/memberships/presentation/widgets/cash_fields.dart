import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../branches/presentation/bloc/branch_scope_cubit.dart';

/// حقلا المبلغ بالعملتين (`.pay` بالنموذج): الدولار والليرة معاً أو أحدهما. كل مبلغ سطر `{currency, amount}`.
class PaymentFields extends StatelessWidget {
  const PaymentFields({super.key, this.usdLabel = 'بالدولار', this.sypLabel = 'بالليرة السورية'});

  final String usdLabel, sypLabel;

  static const usd = 'usd', syp = 'syp';

  @override
  Widget build(BuildContext context) {
    final fields = [
      FormText(
        usd,
        label: usdLabel,
        hint: '0.00',
        ltr: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: Validators.amount(optional: true),
      ),
      FormText(
        syp,
        label: sypLabel,
        hint: '0',
        ltr: true,
        keyboardType: TextInputType.number,
        validator: Validators.amount(optional: true),
      ),
    ];
    return LayoutBuilder(
      builder: (context, box) => box.maxWidth >= AppSize.gridItem * 2
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpace.s3,
              children: [for (final f in fields) Expanded(child: f)],
            )
          : Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: AppSpace.s4, children: fields),
    );
  }

  /// أسطر الدفع من النموذج (الفارغ والصفر لا يُرسلان).
  static List<Json> linesOf(AppFormCubit form) => [
    for (final (key, currency) in const [(usd, 'USD'), (syp, 'SYP')])
      if (_amount(form.value(key)) case final a? when a > 0) {'currency': currency, 'amount': a},
  ];

  static num? _amount(Object? v) => num.tryParse('${v ?? ''}'.replaceAll(',', '').trim());

  /// لا مبلغ بأي عملة: يظهر أعلى النموذج بلا طلب.
  static const noAmount = ApiFailure<Never>(
    Failure(type: FailureType.validation, message: 'اكتب المبلغ بالدولار أو بالليرة.'),
  );
}

/// صندوق الفرع للعملية المالية: فرع الشريط العلوي، أو حقل اختيار حين يكون على "كل الفروع" وللنادي أكثر من فرع،
/// أو null بفرع واحد (الخادم يستنتجه).
class CashBranch {
  CashBranch._(this._fixed, this.options, this._initial);

  factory CashBranch.of(BuildContext context, {int? fallback}) {
    final s = context.read<BranchScopeCubit>().state;
    if (s.branchId != null || !s.canChoose) return CashBranch._(s.branchId, const [], null);
    final options = [for (final b in s.active) (value: b.id, label: b.name)];
    return CashBranch._(null, options, options.any((o) => o.value == fallback) ? fallback : null);
  }

  static const key = 'branch_id';

  final int? _fixed, _initial;
  final List<FormOption<int>> options;

  bool get needsField => options.isNotEmpty;

  Json get initial => {key: ?_initial};

  Widget field({String label = 'صندوق الفرع'}) =>
      FormDropdown<int>(key, label: label, options: options, required: true, hint: 'اختر الفرع');

  int? idOf(AppFormCubit form) => _fixed ?? form.value(key) as int?;
}
