import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../data/repo/training_repository.dart';
import '../../domain/models/training_models.dart';

/// إضافة قياس وتعديله وحذفه (`Training.html` نافذة "قياس جديد"). للمالك فقط.
abstract final class MeasurementActions {
  static const _noValue = ApiFailure<Never>(
    Failure(type: FailureType.validation, message: 'اكتب قياساً واحداً على الأقل.'),
  );

  /// `82.4` أو `82,4` (الفاصلة عشرية هنا: لا قياس بالآلاف).
  static num? parse(Object? v) => num.tryParse('${v ?? ''}'.replaceAll(',', '.').trim());

  static FieldValidator _range(MeasureField f) => (v) {
    if ((v ?? '').trim().isEmpty) return null;
    final n = parse(v);
    if (n == null || n < 0) return 'اكتب رقماً صحيحاً.';
    if (n > f.max) return 'أقصى قيمة ${Formatters.number(f.max)}.';
    return null;
  };

  /// القيمة بلا أصفار زائدة لحقل التعديل (`82` لا `82.0`).
  static String _plain(double v) => v == v.roundToDouble() ? '${v.toInt()}' : '$v';

  /// الجسم: التاريخ والملاحظة من النموذج، والأرقام أرقاماً. بالتعديل الحقل الممسوح يُرسل null.
  static Json bodyOf(AppFormCubit form, {required bool keepNulls}) => {
    ...form.apiBody(keepNulls: keepNulls, except: {for (final f in MeasureField.values) f.key}),
    for (final f in MeasureField.values)
      if (parse(form.value(f.key)) case final n?) f.key: n else if (keepNulls) f.key: null,
  };

  /// يرجع true إن حُفظ.
  static Future<bool> save(
    BuildContext context, {
    required int playerId,
    required String playerName,
    BodyMeasurement? existing,
  }) async {
    final today = Formatters.clubTime(sl<ServerClock>().now());
    final keeper = IdempotencyKeeper();
    final m = existing;
    final done = await FormDialog.show<BodyMeasurement>(
      context,
      title: m == null ? 'قياس جديد · $playerName' : 'تعديل قياس · $playerName',
      icon: Icons.monitor_weight_outlined,
      submitLabel: 'حفظ القياس',
      successMessage: 'تم حفظ القياس.',
      initial: {
        'measured_on': m?.measuredOn ?? DateTime(today.year, today.month, today.day),
        'notes': ?m?.notes,
        if (m != null)
          for (final f in MeasureField.values)
            if (m[f] case final v?) f.key: _plain(v),
      },
      fields: (_) => FormColumn(
        children: [
          FormDate(
            'measured_on',
            label: 'التاريخ',
            required: true,
            firstDate: DateTime(today.year - 10),
            lastDate: DateTime(today.year, today.month, today.day),
          ),
          ResponsiveGrid(
            minItemWidth: AppSize.formFieldMin,
            maxColumns: 3,
            children: [
              for (final f in MeasureField.values)
                FormText(
                  f.key,
                  label: '${f.label} (${f.unit})',
                  ltr: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: _range(f),
                ),
            ],
          ),
          const FormText('notes', label: 'ملاحظات', maxLines: 2),
        ],
      ),
      onSubmit: (form) async {
        if (MeasureField.values.every((f) => parse(form.value(f.key)) == null)) return _noValue;
        final repo = sl<TrainingRepository>();
        if (m != null) return repo.saveMeasurement(playerId, bodyOf(form, keepNulls: true), id: m.id);
        final body = bodyOf(form, keepNulls: false);
        return repo.saveMeasurement(playerId, body, idempotencyKey: keeper.keyFor(body));
      },
    );
    return done != null;
  }

  /// يرجع true إن حُذف.
  static Future<bool> delete(BuildContext context, {required int playerId, required BodyMeasurement m}) async {
    final done = await FormDialog.confirm<void>(
      context,
      title: 'حذف القياس',
      message: 'يُحذف قياس ${Formatters.ltr(Formatters.date(m.measuredOn))} ويختفي من تطبيق العضو.',
      confirmLabel: 'حذف',
      icon: Icons.delete_outline_rounded,
      successMessage: 'تم حذف القياس.',
      onConfirm: () => sl<TrainingRepository>().deleteMeasurement(playerId, m.id),
    );
    return done != null;
  }
}
