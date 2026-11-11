import '../../../../core/core.dart';

/// فترة قسم بفرع أوقات منفصلة (`gender_schedule[]`): أيام الأسبوع + من/إلى بتوقيت النادي.
class GenderSlot extends Equatable {
  const GenderSlot({required this.days, required this.from, required this.to, required this.gender, this.label});

  factory GenderSlot.fromJson(Json j) => GenderSlot(
    days: j.strList('days'),
    from: _minutes(j.str('from')),
    to: _minutes(j.str('to')),
    gender: j.str('gender'),
    label: j.strOrNull('gender_label'),
  );

  /// `saturday` … كما يرسلها الخادم.
  final List<String> days;

  /// دقائق من منتصف الليل. `to = 0` (`00:00`) يعني نهاية اليوم.
  final int from, to;
  final String gender;
  final String? label;

  static int _minutes(String hhmm) {
    final p = hhmm.split(':');
    return (int.tryParse(p.first) ?? 0) * 60 + (p.length > 1 ? int.tryParse(p[1]) ?? 0 : 0);
  }

  @override
  List<Object?> get props => [days, from, to, gender, label];
}

/// فرع الموظف (`GET club-admin/branches`، محصورة بفروعه من الخادم).
class StationBranch extends Equatable {
  const StationBranch({
    required this.id,
    required this.name,
    this.isMain = false,
    this.timeSplit = false,
    this.schedule = const [],
  });

  factory StationBranch.fromJson(Json j) => StationBranch(
    id: j.intv('id'),
    name: j.str('name', '—'),
    isMain: j.flag('is_main'),
    timeSplit: j.strOrNull('gender_policy') == 'time_split',
    schedule: j.list('gender_schedule', GenderSlot.fromJson),
  );

  final int id;
  final String name;
  final bool isMain, timeSplit;
  final List<GenderSlot> schedule;

  static const _weekdays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];

  /// القسم الحالي للعرض بالشريط العلوي (بتوقيت النادي): "مختلط" لفرع بلا أوقات منفصلة، واسم القسم للفترة
  /// الجارية، و null خارج كل الفترات. للعرض فقط: قرار الدخول من الخادم.
  String? sectionAt(DateTime clubTime) {
    if (!timeSplit) return 'مختلط';
    final day = _weekdays[clubTime.weekday - 1];
    final minute = clubTime.hour * 60 + clubTime.minute;
    for (final s in schedule) {
      final end = s.to <= s.from ? 24 * 60 : s.to;
      if (s.days.contains(day) && minute >= s.from && minute < end) return s.label ?? Labels.gender(s.gender);
    }
    return null;
  }

  @override
  List<Object?> get props => [id, name, isMain, timeSplit, schedule];
}

/// سطر من سجل الدخول (`latest[]` بحضور اليوم، و `record` برد تسجيل الدخول).
class AttendanceEntry extends Equatable {
  const AttendanceEntry({
    required this.id,
    required this.playerId,
    required this.playerName,
    required this.status,
    this.checkedInAt,
    this.method,
    this.rejectionReason,
    this.rejectionMessage,
    this.inGrace = false,
    this.isOffline = false,
  });

  factory AttendanceEntry.fromJson(Json j) => AttendanceEntry(
    id: j.intv('id'),
    playerId: j.obj('player').intv('id'),
    playerName: j.obj('player').str('name', '—'),
    status: j.str('status'),
    checkedInAt: j.date('checked_in_at'),
    method: j.strOrNull('method'),
    rejectionReason: j.strOrNull('rejection_reason'),
    rejectionMessage: j.strOrNull('rejection_message'),
    inGrace: j.flag('in_grace'),
    isOffline: j.flag('is_offline'),
  );

  final int id, playerId;
  final String playerName, status;
  final DateTime? checkedInAt;

  /// `qr` · `code` · `manual` · `day_pass`.
  final String? method;
  final String? rejectionReason, rejectionMessage;
  final bool inGrace, isOffline;

  bool get isRejected => status == 'rejected';

  /// طريقة الدخول بالعربية كما بسجل الاستقبال.
  String get methodLabel => switch (method) {
    'qr' => 'QR',
    'code' => 'المعرّف',
    'manual' => 'بحث يدوي',
    'day_pass' => 'دخول يومي',
    _ => '—',
  };

  @override
  List<Object?> get props => [
    id,
    playerId,
    playerName,
    status,
    checkedInAt,
    method,
    rejectionReason,
    rejectionMessage,
    inGrace,
    isOffline,
  ];
}

/// حضور يوم العمل بالفرع (`GET club-admin/attendance/today?branch_id=`): الأرقام وآخر الدخول كما من الخادم.
class TodaySummary extends Equatable {
  const TodaySummary({this.accepted = 0, this.rejected = 0, this.inGrace = 0, this.latest = const []});

  factory TodaySummary.fromJson(Json j) => TodaySummary(
    accepted: j.intv('accepted'),
    rejected: j.intv('rejected'),
    inGrace: j.intv('in_grace'),
    latest: j.list('latest', AttendanceEntry.fromJson),
  );

  final int accepted, rejected, inGrace;
  final List<AttendanceEntry> latest;

  @override
  List<Object?> get props => [accepted, rejected, inGrace, latest];
}
