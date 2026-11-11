import '../../../../core/core.dart';

/// مرجع بسيط (عضو، مدرب): `{id, name}`.
typedef TrainingRef = ({int id, String name});

/// العضو المختار بالقياسات (من البحث أو من رابط `?player_id=`).
typedef TrainingMember = ({int id, String name, String? memberCode});

TrainingRef? _ref(Json? j) => j == null ? null : (id: j.intv('id'), name: j.str('name'));

/// تمرين داخل يوم: الحقول كما يحفظها الخادم (`WorkoutRules::clean`).
class Exercise extends Equatable {
  const Exercise({
    required this.name,
    this.sets,
    this.reps,
    this.weightKg,
    this.durationSeconds,
    this.restSeconds,
    this.notes,
  });

  factory Exercise.fromJson(Json j) => Exercise(
    name: j.str('name'),
    sets: j.intOrNull('sets'),
    reps: j.strOrNull('reps'),
    weightKg: j.dblOrNull('weight_kg'),
    durationSeconds: j.intOrNull('duration_seconds'),
    restSeconds: j.intOrNull('rest_seconds'),
    notes: j.strOrNull('notes'),
  );

  final String name;
  final int? sets, durationSeconds, restSeconds;
  final String? reps, notes;
  final double? weightKg;

  @override
  List<Object?> get props => [name, sets, reps, weightKg, durationSeconds, restSeconds, notes];
}

class WorkoutDay extends Equatable {
  const WorkoutDay({required this.day, required this.title, this.exercises = const []});

  factory WorkoutDay.fromJson(Json j) =>
      WorkoutDay(day: j.intv('day'), title: j.str('title'), exercises: j.list('exercises', Exercise.fromJson));

  final int day;
  final String title;
  final List<Exercise> exercises;

  @override
  List<Object?> get props => [day, title, exercises];
}

/// برنامج تدريب `club-admin/workout-plans`: لعضو محدد (يظهر بتطبيقه)، أو قالب عام (`is_template`، بلا عضو).
/// القائمة بلا `days` (فقط `days_count`)، والتفاصيل بها.
class WorkoutPlan extends Equatable {
  const WorkoutPlan({
    required this.id,
    required this.title,
    this.description,
    this.isTemplate = false,
    this.source = 'club',
    this.player,
    this.trainer,
    this.startsOn,
    this.endsOn,
    this.status = 'active',
    this.daysCount = 0,
    this.days = const [],
  });

  factory WorkoutPlan.fromJson(Json j) => WorkoutPlan(
    id: j.intv('id'),
    title: j.str('title'),
    description: j.strOrNull('description'),
    isTemplate: j.flag('is_template'),
    source: j.str('source', 'club'),
    player: _ref(j.objOrNull('player')),
    trainer: _ref(j.objOrNull('trainer')),
    startsOn: j.day('starts_on'),
    endsOn: j.day('ends_on'),
    status: j.str('status', 'active'),
    daysCount: j.intv('days_count'),
    days: j.list('days', WorkoutDay.fromJson),
  );

  final int id;
  final String title, source, status;
  final String? description;
  final bool isTemplate;
  final TrainingRef? player, trainer;
  final DateTime? startsOn, endsOn;
  final int daysCount;
  final List<WorkoutDay> days;

  bool get isArchived => status == 'archived';

  /// أضافه العضو بنفسه من تطبيقه.
  bool get byPlayer => source == 'player';

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    isTemplate,
    source,
    player,
    trainer,
    startsOn,
    endsOn,
    status,
    daysCount,
    days,
  ];
}

/// قياس جسم `players/{id}/measurements` (الأحدث أولاً). `bmi` محسوب بالخادم.
class BodyMeasurement extends Equatable {
  const BodyMeasurement({required this.id, required this.measuredOn, this.values = const {}, this.bmi, this.notes});

  factory BodyMeasurement.fromJson(Json j) => BodyMeasurement(
    id: j.intv('id'),
    measuredOn: j.day('measured_on') ?? DateTime(2000),
    values: {for (final f in MeasureField.values) f: j.dblOrNull(f.key)},
    bmi: j.dblOrNull('bmi'),
    notes: j.strOrNull('notes'),
  );

  final int id;
  final DateTime measuredOn;
  final Map<MeasureField, double?> values;
  final double? bmi;
  final String? notes;

  double? operator [](MeasureField f) => values[f];

  @override
  List<Object?> get props => [id, measuredOn, values, bmi, notes];
}

/// صفحة قياسات العضو + التقدم بين أول وآخر قياس (`meta.progress`، من الخادم؛ null بقياس واحد).
class MeasurementsPage extends Equatable {
  const MeasurementsPage({required this.items, required this.pagination, this.progress});

  factory MeasurementsPage.from(Paged<BodyMeasurement> p) => MeasurementsPage(
    items: p.items,
    pagination: p.pagination,
    progress: switch (p.meta.objOrNull('progress')) {
      final j? => {for (final f in MeasureField.values) f: j.dblOrNull(f.key)},
      null => null,
    },
  );

  final List<BodyMeasurement> items;
  final Pagination pagination;
  final Map<MeasureField, double?>? progress;

  @override
  List<Object?> get props => [items, pagination, progress];
}

/// حقول القياس بترتيب العرض، مع الوحدة وأقصى قيمة يقبلها الخادم و "الأفضل" (للون التقدم فقط).
enum MeasureField {
  weight('weight_kg', 'الوزن', 'kg', 400, better: -1),
  bodyFat('body_fat_percent', 'نسبة الدهون', '%', 80, better: -1),
  muscle('muscle_mass_kg', 'الكتلة العضلية', 'kg', 200, better: 1),
  waist('waist_cm', 'الخصر', 'cm', 250, better: -1),
  height('height_cm', 'الطول', 'cm', 260),
  chest('chest_cm', 'الصدر', 'cm', 250),
  hips('hips_cm', 'الورك', 'cm', 250),
  arm('arm_cm', 'الذراع', 'cm', 100),
  thigh('thigh_cm', 'الفخذ', 'cm', 150);

  const MeasureField(this.key, this.label, this.unit, this.max, {this.better = 0});

  final String key, label, unit;
  final double max;

  /// 1 = الزيادة أفضل، -1 = النقص أفضل، 0 = محايد.
  final int better;

  /// بطاقات الرأس (أهم القياسات).
  static const headline = [weight, bodyFat, muscle, waist, height];
}

/// نصوص التدريب بمكان واحد.
abstract final class TrainingTexts {
  /// `12.5 kg`، `18.2%`.
  static String value(double? v, String unit) =>
      v == null ? '—' : '${Formatters.number(v)}${unit.isEmpty || unit == '%' ? '' : ' '}$unit';

  /// `−3.1` / `+1.4` (الفرق من الخادم).
  static String delta(double v) => v == 0 ? '0' : '${v > 0 ? '+' : '−'}${Formatters.number(v.abs())}';

  /// السطر الثاني بالقائمة: العضو (أو "قالب عام") · عدد الأيام · المدرب.
  static String subtitle(WorkoutPlan p) => [
    if (p.isTemplate) 'قالب عام' else p.player?.name ?? '—',
    Formatters.count(p.daysCount, 'يوم واحد', 'يومان', 'أيام', many: 'يوماً'),
    ?p.trainer?.name,
  ].join(' · ');
}
