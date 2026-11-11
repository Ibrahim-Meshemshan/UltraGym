import 'package:flutter_bloc/flutter_bloc.dart';

/// بديل `setState` لأي حالة واجهة محلية (التبويب المحدد، الفرع المختار...).
class ValueCubit<T> extends Cubit<T> {
  ValueCubit(super.initial);

  void set(T value) => emit(value);

  void update(T Function(T value) transform) => emit(transform(state));
}

/// حالة نعم/لا (إظهار كلمة السر، طي القائمة...).
class ToggleCubit extends ValueCubit<bool> {
  ToggleCubit([super.initial = false]);

  void toggle() => emit(!state);
}

/// السحب للتحديث: يطلق الحدث ثم ينتظر حتى تهدأ حالة الـ Bloc (أو تنتهي المهلة).
Future<void> pullRefresh<S>(
  StateStreamable<S> bloc,
  void Function() trigger, {
  required bool Function(S state) busy,
  Duration max = const Duration(seconds: 20),
}) async {
  final done = bloc.stream.firstWhere((s) => !busy(s));
  trigger();
  await done.timeout(max, onTimeout: () => bloc.state);
}
