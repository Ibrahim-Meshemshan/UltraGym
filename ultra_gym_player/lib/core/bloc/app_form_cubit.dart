import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../error/failure.dart';
import '../networking/api_result.dart';
import '../utils/json_x.dart';
import 'form_payload.dart';

part 'app_form_state.dart';

/// يتحقق من حقل نصي ويرجع رسالة الخطأ أو null.
typedef FieldValidator = String? Function(String? value);

/// كل نموذج وتأكيد بالمشروع: controllers النصوص تُنشأ عند الطلب وتُتلف معه، وأخطاء 422 تتوزع على الحقول.
class AppFormCubit extends Cubit<AppFormState> {
  AppFormCubit({Json initial = const {}})
      : _initial = initial,
        super(AppFormState(values: {for (final e in initial.entries) if (e.value is! String) e.key: e.value}));

  final Json _initial;
  final Map<String, TextEditingController> _texts = {};
  final Map<String, FieldValidator> _validators = {};

  /// controller الحقل النصي (يُنشأ مرة بالقيمة الأولية). كتابة المستخدم تمسح خطأ الحقل.
  TextEditingController text(String name) => _texts.putIfAbsent(name, () {
        final v = _initial[name];
        final c = TextEditingController(text: v == null ? '' : '$v');
        c.addListener(() => _clearError(name));
        return c;
      });

  /// قيمة غير نصية (قائمة منسدلة، تاريخ، رقائق، ملف).
  void set(String name, Object? value) {
    final errors = {...state.fieldErrors}..remove(name);
    emit(state.copyWith(values: {...state.values, name: value}, fieldErrors: errors));
  }

  /// تسجيل تحقق محلي لحقل (يستدعيه ويدجت الحقل).
  void validator(String name, FieldValidator? check) => check == null ? _validators.remove(name) : _validators[name] = check;

  Object? value(String name) => _texts.containsKey(name) ? _texts[name]!.text : state.values[name];

  /// كل القيم بمفاتيحها المنقّطة.
  Json get flat => {...state.values, for (final e in _texts.entries) e.key: e.value.text};

  /// جسم الطلب المتداخل. `keepNulls` يرسل الحقول الفارغة كـ null (لمسحها بالخادم)، و `except` يستبعد حقولاً.
  Json apiBody({bool keepNulls = false, Set<String> dateTimes = const {}, Set<String> except = const {}}) {
    final out = <String, dynamic>{};
    for (final e in flat.entries) {
      if (except.contains(e.key)) continue;
      final v = FormPayload.encode(e.key, e.value, dateTimes);
      if (v != null || keepNulls) out[e.key] = v;
    }
    return FormPayload.nest(out);
  }

  Json get payload => apiBody();

  /// أخطاء 422 لحقول غير ظاهرة بالنموذج: تُعرض أعلاه.
  List<String> get orphanErrors {
    final known = {..._texts.keys, ..._validators.keys, ...state.values.keys, ..._initial.keys};
    return [for (final e in state.fieldErrors.entries) if (!known.contains(e.key)) e.value];
  }

  /// تحقق محلي ← إرسال ← توزيع أخطاء 422 على الحقول، والفشل العام أعلى النموذج.
  /// يرجع null إن فشل التحقق المحلي.
  Future<ApiResult<R>?> submit<R>(Future<ApiResult<R>> Function(AppFormCubit form) send) async {
    if (state.submitting) return null;
    final local = <String, String>{
      for (final e in _validators.entries)
        if (e.value(value(e.key)?.toString()) case final String msg) e.key: msg,
    };
    if (local.isNotEmpty) {
      emit(state.copyWith(fieldErrors: local, failure: () => null));
      return null;
    }
    emit(state.copyWith(submitting: true, fieldErrors: const {}, failure: () => null));
    final r = await send(this);
    if (isClosed) return r;
    switch (r) {
      case ApiSuccess<R>():
        emit(state.copyWith(submitting: false));
      case ApiFailure<R>(:final failure):
        final errors = failure.fieldErrors;
        emit(state.copyWith(
          submitting: false,
          fieldErrors: errors,
          failure: () => errors.isEmpty || failure.type != FailureType.validation ? failure : null,
        ));
    }
    return r;
  }

  void _clearError(String name) {
    if (isClosed || !state.fieldErrors.containsKey(name)) return;
    emit(state.copyWith(fieldErrors: {...state.fieldErrors}..remove(name)));
  }

  @override
  Future<void> close() {
    for (final c in _texts.values) {
      c.dispose();
    }
    return super.close();
  }
}
