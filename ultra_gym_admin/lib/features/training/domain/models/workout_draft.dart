import '../../../../core/core.dart';
import 'training_models.dart';

/// تمرين بالمحرر: النصوص كما كُتبت. `keep` = حقول يحفظها الخادم ولا يعرضها المحرر (الوزن، المدة) فلا تضيع بالحفظ.
class ExerciseDraft extends Equatable {
  const ExerciseDraft({
    required this.uid,
    this.name = '',
    this.sets = '',
    this.reps = '',
    this.rest = '',
    this.notes = '',
    this.keep = const {},
  });

  factory ExerciseDraft.of(Exercise e) => ExerciseDraft(
    uid: DraftIds.next(),
    name: e.name,
    sets: e.sets?.toString() ?? '',
    reps: e.reps ?? '',
    rest: e.restSeconds?.toString() ?? '',
    notes: e.notes ?? '',
    keep: {'weight_kg': ?e.weightKg, 'duration_seconds': ?e.durationSeconds},
  );

  final int uid;
  final String name, sets, reps, rest, notes;
  final Json keep;

  ExerciseDraft copyWith({String? name, String? sets, String? reps, String? rest, String? notes}) => ExerciseDraft(
    uid: uid,
    name: name ?? this.name,
    sets: sets ?? this.sets,
    reps: reps ?? this.reps,
    rest: rest ?? this.rest,
    notes: notes ?? this.notes,
    keep: keep,
  );

  Json body() => {
    'name': name.trim(),
    'sets': ?int.tryParse(sets.trim()),
    'reps': ?_text(reps),
    'rest_seconds': ?int.tryParse(rest.trim()),
    'notes': ?_text(notes),
    ...keep,
  };

  @override
  List<Object?> get props => [uid, name, sets, reps, rest, notes, keep];
}

class DayDraft extends Equatable {
  const DayDraft({required this.uid, this.title = '', this.exercises = const []});

  factory DayDraft.of(WorkoutDay d) =>
      DayDraft(uid: DraftIds.next(), title: d.title, exercises: [for (final e in d.exercises) ExerciseDraft.of(e)]);

  /// يوم جديد بتمرين فارغ واحد.
  factory DayDraft.blank() => DayDraft(
    uid: DraftIds.next(),
    exercises: [ExerciseDraft(uid: DraftIds.next())],
  );

  final int uid;
  final String title;
  final List<ExerciseDraft> exercises;

  DayDraft copyWith({String? title, List<ExerciseDraft>? exercises}) =>
      DayDraft(uid: uid, title: title ?? this.title, exercises: exercises ?? this.exercises);

  @override
  List<Object?> get props => [uid, title, exercises];
}

/// البرنامج بالمحرر. العضو يُختار عند الإنشاء فقط (بلا عضو = قالب عام)؛ نقل برنامج لعضو آخر بـ "إسناد لعضو" (نسخة).
class WorkoutDraft extends Equatable {
  const WorkoutDraft({
    this.id,
    this.title = '',
    this.description = '',
    this.player,
    this.trainer,
    this.memberPlan = false,
    this.startsOn,
    this.endsOn,
    this.status = 'active',
    this.days = const [],
  });

  factory WorkoutDraft.of(WorkoutPlan p) => WorkoutDraft(
    id: p.id,
    title: p.title,
    description: p.description ?? '',
    player: p.player,
    trainer: p.trainer,
    startsOn: p.startsOn,
    endsOn: p.endsOn,
    status: p.status,
    days: [for (final d in p.days) DayDraft.of(d)],
  );

  /// برنامج جديد بيوم واحد: لعضو (`memberPlan`، العضو إلزامي) أو قالب عام.
  factory WorkoutDraft.blank({required bool memberPlan}) =>
      WorkoutDraft(memberPlan: memberPlan, days: [DayDraft.blank()]);

  static const maxDays = 14, maxExercises = 40;

  final int? id;
  final String title, description, status;
  final TrainingRef? player;
  final TrainingRef? trainer;

  /// خطة جديدة من تبويب "لأعضاء": اختيار العضو إلزامي.
  final bool memberPlan;
  final DateTime? startsOn, endsOn;
  final List<DayDraft> days;

  bool get isNew => id == null;
  bool get isTemplate => player == null;

  WorkoutDraft copyWith({
    String? title,
    String? description,
    (TrainingRef?,)? player,
    (TrainingRef?,)? trainer,
    (DateTime?, DateTime?)? period,
    String? status,
    List<DayDraft>? days,
  }) => WorkoutDraft(
    id: id,
    title: title ?? this.title,
    description: description ?? this.description,
    player: player == null ? this.player : player.$1,
    trainer: trainer == null ? this.trainer : trainer.$1,
    memberPlan: memberPlan,
    startsOn: period == null ? startsOn : period.$1,
    endsOn: period == null ? endsOn : period.$2,
    status: status ?? this.status,
    days: days ?? this.days,
  );

  /// الجسم نفسه للإضافة والتعديل؛ الأيام مرقّمة بترتيبها. `player_id` يُرسل بالإضافة فقط.
  Json body() => {
    'title': title.trim(),
    'description': _text(description),
    if (isNew) 'player_id': player?.id,
    'trainer_id': trainer?.id,
    'starts_on': startsOn == null ? null : Formatters.date(startsOn),
    'ends_on': endsOn == null ? null : Formatters.date(endsOn),
    'status': status,
    'days': [
      for (final (i, d) in days.indexed)
        {
          'day': i + 1,
          'title': d.title.trim(),
          'exercises': [for (final e in d.exercises) e.body()],
        },
    ],
  };

  /// تحقق محلي بمفاتيح أخطاء الخادم نفسها (`days.0.exercises.1.name`)، فيظهر الخطأ تحت حقله في الحالتين.
  Map<String, String> validate() {
    final errors = <String, String>{};
    if (title.trim().isEmpty) errors['title'] = 'اكتب عنوان الخطة.';
    if (isNew && memberPlan && player == null) errors['player_id'] = 'اختر العضو.';
    if (days.isEmpty) errors['days'] = 'أضف يوماً واحداً على الأقل.';
    if (startsOn != null && endsOn != null && endsOn!.isBefore(startsOn!)) {
      errors['ends_on'] = 'تاريخ النهاية قبل البداية.';
    }
    for (final (i, d) in days.indexed) {
      if (d.title.trim().isEmpty) errors['days.$i.title'] = 'اكتب عنوان اليوم.';
      if (d.exercises.isEmpty) errors['days.$i.exercises'] = 'أضف تمريناً واحداً على الأقل.';
      for (final (j, e) in d.exercises.indexed) {
        final at = 'days.$i.exercises.$j';
        if (e.name.trim().isEmpty) errors['$at.name'] = 'اكتب اسم التمرين.';
        if (!_intIn(e.sets, 1, 50)) errors['$at.sets'] = 'من 1 إلى 50.';
        if (!_intIn(e.rest, 0, 1800)) errors['$at.rest_seconds'] = 'من 0 إلى 1800 ثانية.';
      }
    }
    return errors;
  }

  @override
  List<Object?> get props => [id, title, description, player, trainer, memberPlan, startsOn, endsOn, status, days];
}

String? _text(String v) => v.trim().isEmpty ? null : v.trim();

/// فارغ مقبول (اختياري)، وإلا عدد صحيح ضمن الحدين.
bool _intIn(String v, int min, int max) {
  if (v.trim().isEmpty) return true;
  final n = int.tryParse(v.trim());
  return n != null && n >= min && n <= max;
}
