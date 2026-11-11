import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../bloc/slice.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'error_state.dart';

/// الحالات الأربع لأي قسم: تحميل بهياكل، خطأ مع إعادة محاولة، فارغة كدعوة، ومحتوى.
/// إعادة التحميل تُبقي المحتوى بشفافية 0.55 مع شريط تقدّم 2px والضغط معطّل مؤقتاً.
class SliceView<T> extends StatelessWidget {
  const SliceView({
    super.key,
    required this.slice,
    required this.loading,
    required this.builder,
    this.onRetry,
    this.isEmpty,
    this.empty,
    this.frame,
  });

  final Slice<T> slice;

  /// هيكل بنفس شكل المحتوى (لا CircularProgressIndicator).
  final Widget loading;
  final Widget Function(BuildContext context, T data) builder;
  final VoidCallback? onRetry;
  final bool Function(T data)? isEmpty;

  /// دعوة لا اعتذار (`EmptyState`).
  final Widget? empty;

  /// إطار اختياري حول حالات التحميل والخطأ (ليبقى رأس الصفحة وزر الرجوع ظاهرين).
  final Widget Function(Widget child)? frame;

  @override
  Widget build(BuildContext context) {
    final data = slice.data;
    final (String key, Widget child) = switch (slice) {
      _ when slice.isFirstLoad => ('loading', _framed(loading)),
      _ when data == null => ('error', _framed(_error())),
      _ when isEmpty?.call(data as T) ?? false => ('empty', empty ?? const SizedBox.shrink()),
      _ => ('content', _Refreshing(active: slice.isRefreshing, child: builder(context, data as T))),
    };
    final duration = AppMotion.of(context, AppMotion.normal);
    final animated = key == 'content' && duration > Duration.zero
        ? child.animate().fadeIn(duration: duration, curve: AppMotion.curve)
        : child;
    return AnimatedSwitcher(duration: duration, child: KeyedSubtree(key: ValueKey(key), child: animated));
  }

  Widget _error() {
    final f = slice.failure;
    return f == null ? const SizedBox.shrink() : ErrorState(failure: f, onRetry: onRetry);
  }

  Widget _framed(Widget child) => frame?.call(child) ?? child;
}

class _Refreshing extends StatelessWidget {
  const _Refreshing({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final duration = AppMotion.of(context, AppMotion.fast);
    return Stack(children: [
      AbsorbPointer(
        absorbing: active,
        child: AnimatedOpacity(opacity: active ? .55 : 1, duration: duration, child: child),
      ),
      if (active)
        PositionedDirectional(
          top: 0,
          start: 0,
          end: 0,
          child: LinearProgressIndicator(minHeight: 2, color: context.colors.primary, backgroundColor: Colors.transparent),
        ),
    ]);
  }
}
