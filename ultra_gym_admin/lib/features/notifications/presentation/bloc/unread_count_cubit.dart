import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../../../core/core.dart';
import '../../data/repo/notifications_repository.dart';

/// عدّاد الجرس بعمر الهيكل: يُطلب عند الفتح، وكل 60 ثانية فقط بينما الواجهة ظاهرة،
/// وعند عودتها للظهور، وبعد أي عملية (`refresh()` من الشاشة). فشل الطلب لا يمسح العدد السابق.
class UnreadCountCubit extends Cubit<int> {
  UnreadCountCubit(this._repo, {this.interval = AppConfig.unreadPollInterval}) : super(0);

  final NotificationsRepository _repo;
  final Duration interval;
  Timer? _timer;
  AppLifecycleListener? _lifecycle;

  /// أول طلب + التحديث الدوري + متابعة ظهور الواجهة واختفائها.
  void start() {
    unawaited(refresh());
    _schedule();
    _lifecycle ??= AppLifecycleListener(
      onShow: () {
        unawaited(refresh());
        _schedule();
      },
      onHide: () => _timer?.cancel(),
    );
  }

  Future<void> refresh() async {
    final r = await _repo.unreadCount();
    if (isClosed) return;
    if (r case ApiSuccess(:final data)) emit(data);
  }

  /// بعد تعليم إشعار مقروءاً (قبل وصول العدد الجديد).
  void decrement() => emit(math.max(0, state - 1));

  /// بعد "قراءة الكل".
  void clear() => emit(0);

  void _schedule() {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => unawaited(refresh()));
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    _lifecycle?.dispose();
    return super.close();
  }
}
