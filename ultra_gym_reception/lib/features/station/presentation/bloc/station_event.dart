part of 'station_bloc.dart';

sealed class StationEvent {
  const StationEvent();
}

/// تغيّر فرع المحطة (أول مرة أو من الشريط العلوي): يمسح النتيجة ويحمّل حضور اليوم.
final class StationBranchChanged extends StationEvent {
  const StationBranchChanged(this.branchId);
  final int branchId;
}

/// تحديث حضور اليوم (بعد كل تسجيل، أو زر إعادة المحاولة).
final class StationTodayRequested extends StationEvent {
  const StationTodayRequested();
}

/// نص الحقل بعد Enter (كتابة أو قارئ باركود)، أو رمز من الكاميرا.
final class StationSubmitted extends StationEvent {
  const StationSubmitted(this.raw);
  final String raw;
}

/// عضو مختار من نتائج البحث.
final class StationPlayerPicked extends StationEvent {
  const StationPlayerPicked(this.player);
  final LookupPlayer player;
}

/// إعادة آخر تسجيل فشل بالشبكة: بنفس مفتاح منع التكرار.
final class StationRetried extends StationEvent {
  const StationRetried();
}

/// "العضو التالي" أو Esc: مسح النتيجة والبحث.
final class StationCleared extends StationEvent {
  const StationCleared();
}
