import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../data/repo/finance_settings_repository.dart';
import '../../domain/models/finance_settings_models.dart';

/// "السعر المعتمد الآن" (`FinanceSettings.html`): 1 USD = N SYP ومن حدّثه ومتى، ثم (للمالك) نموذج سعر جديد.
/// بلا سعر: تنبيه بأن أي مبلغ بالليرة يُرفض حتى يُحدَّد.
class CurrentRateCard extends StatelessWidget {
  const CurrentRateCard({super.key, required this.rate, this.updatedBy, required this.owner, required this.onSaved});

  final CurrentRate rate;

  /// من سجّل آخر سعر (أول سطر بالسجل).
  final String? updatedBy;
  final bool owner;
  final VoidCallback onSaved;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return CutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.s4,
        children: [
          Text('السعر المعتمد الآن', style: UType.label(color: c.inkMuted)),
          if (rate.isSet) ...[
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                textDirection: TextDirection.ltr,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                spacing: AppSpace.s2,
                children: [
                  LtrText('1 USD =', style: UType.body(color: c.inkMuted)),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: LtrText(Formatters.number(rate.sypPerUsd), style: UType.stat(color: c.ink)),
                    ),
                  ),
                  LtrText('SYP', style: UType.body(color: c.inkMuted)),
                ],
              ),
            ),
            Text(
              [
                if (updatedBy != null) 'حدّثه $updatedBy',
                if (rate.updatedAt != null) Formatters.ltr(Formatters.dateTime(rate.updatedAt)),
              ].join(' · '),
              style: UType.caption(color: c.inkMuted),
            ),
          ] else
            Container(
              padding: const EdgeInsets.all(AppSpace.s3),
              decoration: BoxDecoration(color: c.warningSoft, borderRadius: AppRadius.fieldAll),
              child: Text(
                owner
                    ? 'لم يُحدَّد سعر الصرف بعد. أي مبلغ بالليرة يُرفض حتى تعتمد سعراً.'
                    : 'لم يُحدَّد سعر الصرف بعد. اطلب من مالك النادي اعتماده قبل قبض أي مبلغ بالليرة.',
                style: UType.label(color: c.warningInk),
              ),
            ),
          if (owner) BlocProvider(create: (_) => AppFormCubit(), child: _RateForm(onSaved: onSaved)),
        ],
      ),
    );
  }
}

/// سعر جديد (ليرة لكل دولار) + ملاحظة ← `POST finance/exchange-rate`. يُطبَّق على الحركات الجديدة فقط.
class _RateForm extends StatelessWidget {
  _RateForm({required this.onSaved});

  final VoidCallback onSaved;

  /// نفس السعر بعد فشل الشبكة = نفس المفتاح (يعيش مع هذا الويدجت لا مع كل بناء).
  final _keeper = IdempotencyKeeper();

  static const _rate = 'syp_per_usd', _note = 'note';

  Future<void> _submit(BuildContext context) async {
    final form = context.read<AppFormCubit>();
    final result = await form.submit((f) {
      final body = {
        _rate: num.parse('${f.value(_rate)}'.replaceAll(',', '').trim()),
        _note: ?_text(f.value(_note)),
      };
      return sl<FinanceSettingsRepository>().setRate(body, idempotencyKey: _keeper.keyFor(body));
    });
    if (result case ApiSuccess(:final message)) {
      AppSnackbar.show(message ?? 'تم تحديث سعر الصرف.');
      form.text(_rate).clear();
      form.text(_note).clear();
      onSaved();
    }
  }

  static String? _text(Object? v) {
    final s = '${v ?? ''}'.trim();
    return s.isEmpty ? null : s;
  }

  static String? _atLeastOne(String? v) {
    final n = num.tryParse((v ?? '').replaceAll(',', '').trim());
    return n != null && n < 1 ? 'اكتب سعراً لا يقل عن 1.' : null;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final busy = context.select<AppFormCubit, bool>((f) => f.state.submitting);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.s3,
      children: [
        Divider(height: 1, color: c.line),
        const FormErrorBanner(),
        FormText(
          _rate,
          label: 'سعر جديد (ليرة لكل دولار)',
          required: true,
          ltr: true,
          hint: '13,000',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: Validators.all([Validators.amount(message: 'اكتب السعر بالأرقام.'), _atLeastOne]),
          onSubmitted: (_) => _submit(context),
        ),
        const FormText(_note, label: 'ملاحظة', hint: 'مثلاً: سعر السوق صباح اليوم'),
        Text(
          'يُطبَّق على الحركات الجديدة فقط. الحركات السابقة تحتفظ بسعرها.',
          style: UType.caption(color: c.inkMuted),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: UGButton(
            label: 'اعتماد السعر',
            icon: Icons.check_rounded,
            onPressed: busy ? null : () => _submit(context),
          ),
        ),
      ],
    );
  }
}
