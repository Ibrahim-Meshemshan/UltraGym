import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../data/repo/cash_sessions_repository.dart';
import '../../domain/models/cash_session_models.dart';
import 'cash_closed_dialog.dart';
import 'cash_session_panels.dart';

/// أفعال الصندوق: فتح وردية بالرصيد الافتتاحي، إغلاقها بالجرد الفعلي، وتقريرها.
/// العمليتان بـ `Idempotency-Key` (مفتاح لكل نافذة، وجسم معدّل بعد 422 = مفتاح جديد).
abstract final class CashSessionActions {
  static const _openUsd = 'opening_usd', _openSyp = 'opening_syp', _closeUsd = 'closing_usd';
  static const _closeSyp = 'closing_syp', _notes = 'notes';

  /// `POST cash-sessions {branch_id, opening_usd, opening_syp, notes?}`؛ الافتتاحي مقترح من جرد آخر وردية.
  static Future<CashSession?> open(BuildContext context, CashBox box) async {
    final keeper = IdempotencyKeeper();
    final suggested = box.suggestedUsd > 0 || box.suggestedSyp > 0;
    final done = await FormDialog.show<CashSession>(
      context,
      title: 'فتح الصندوق',
      icon: Icons.point_of_sale_rounded,
      message: [
        if (box.branchName != null) 'فرع ${box.branchName}.',
        'اكتب الموجود بالدرج الآن بكل عملة.',
        if (suggested) 'المبلغ المقترح من جرد آخر وردية.',
      ].join(' '),
      initial: {_openUsd: _plain(box.suggestedUsd), _openSyp: _plain(box.suggestedSyp)},
      submitLabel: 'فتح الوردية',
      fields: (_) => FormColumn(
        children: [
          _Pair(
            first: _amountField(_openUsd, 'الافتتاحي بالدولار', usd: true),
            second: _amountField(_openSyp, 'الافتتاحي بالليرة', usd: false),
          ),
          const FormText(_notes, label: 'ملاحظة', hint: 'مثلاً: وردية الصباح'),
        ],
      ),
      onSubmit: (form) {
        final body = {
          'branch_id': box.branchId,
          _openUsd: _num(form.value(_openUsd)),
          _openSyp: _num(form.value(_openSyp)),
          _notes: ?_text(form.value(_notes)),
        };
        return sl<CashSessionsRepository>().open(body, idempotencyKey: keeper.keyFor(body));
      },
    );
    return done?.data;
  }

  /// `POST cash-sessions/{id}/close {closing_usd, closing_syp, notes?}`: الخادم يحسب الفرق النهائي
  /// (الجرد − المتوقع)، ثم نافذة النتيجة مع "تقرير الوردية".
  static Future<CashSession?> close(BuildContext context, CashSession session) async {
    final keeper = IdempotencyKeeper();
    final done = await FormDialog.show<CashSession>(
      context,
      title: 'إغلاق الوردية ${Formatters.ltr('#${session.id}')}',
      icon: Icons.lock_rounded,
      message: 'عُدّ الموجود فعلياً بالدرج بكل عملة واكتبه.',
      submitLabel: 'إغلاق الوردية',
      fields: (form) => FormColumn(
        children: [
          _Pair(
            first: _CountField(form, _closeUsd, expected: session.expectedUsdNow, usd: true),
            second: _CountField(form, _closeSyp, expected: session.expectedSypNow, usd: false),
          ),
          const FormText(_notes, label: 'ملاحظة', hint: 'مثلاً: سبب العجز إن عُرف'),
        ],
      ),
      onSubmit: (form) {
        final body = {
          _closeUsd: _num(form.value(_closeUsd)),
          _closeSyp: _num(form.value(_closeSyp)),
          _notes: ?_text(form.value(_notes)),
        };
        return sl<CashSessionsRepository>().close(session.id, body, idempotencyKey: keeper.keyFor(body));
      },
    );
    final closed = done?.data;
    if (closed != null && context.mounted) await CashClosedDialog.show(context, closed);
    return closed;
  }

  /// تقرير الوردية (PDF، أو صفحة HTML للطباعة حين لا يتوفر محرك PDF بالخادم).
  static Future<void> report(int id) async {
    switch (await sl<CashSessionsRepository>().report(id)) {
      case ApiSuccess(:final data):
        await BlobOpener.open(data);
      case ApiFailure(:final failure):
        AppSnackbar.show(failure.message);
    }
  }

  static Widget _amountField(String name, String label, {required bool usd}) => FormText(
    name,
    label: label,
    required: true,
    hint: usd ? '0.00' : '0',
    ltr: true,
    keyboardType: usd ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.number,
    validator: Validators.amount(),
  );

  static String _plain(double v) => v == v.roundToDouble() ? '${v.toInt()}' : '$v';

  static num? _num(Object? v) => num.tryParse('${v ?? ''}'.replaceAll(',', '').trim());

  static String? _text(Object? v) {
    final s = '${v ?? ''}'.trim();
    return s.isEmpty ? null : s;
  }
}

/// حقل الجرد بعملة: تحته المتوقع والفرق تقديراً مع الكتابة (الخادم يثبّت الفرق النهائي).
class _CountField extends StatelessWidget {
  const _CountField(this.form, this.name, {required this.expected, required this.usd});

  final AppFormCubit form;
  final String name;
  final double? expected;
  final bool usd;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final muted = UType.caption(color: c.inkMuted);
    final text = form.text(name);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.s2,
      children: [
        CashSessionActions._amountField(name, usd ? 'الموجود بالدولار' : 'الموجود بالليرة', usd: usd),
        Row(
          children: [
            Expanded(child: Text('المتوقع', style: muted)),
            LtrText(usd ? Formatters.usd(expected) : Formatters.syp(expected), style: UType.label(color: c.ink)),
          ],
        ),
        ListenableBuilder(
          listenable: text,
          builder: (context, _) {
            final counted = CashSessionActions._num(text.text);
            final e = expected;
            final diff = counted == null || e == null ? null : double.parse((counted - e).toStringAsFixed(2));
            return Row(
              children: [
                Expanded(child: Text('الفرق', style: muted)),
                if (diff == null) Text('—', style: muted) else CashDifferenceBadge(diff, usd: usd),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// حقلان متجاوران، وعمود على الضيق.
class _Pair extends StatelessWidget {
  const _Pair({required this.first, required this.second});

  final Widget first, second;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => box.maxWidth >= AppSize.gridItem * 2
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpace.s3,
            children: [
              Expanded(child: first),
              Expanded(child: second),
            ],
          )
        : Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: AppSpace.s4, children: [first, second]),
  );
}
