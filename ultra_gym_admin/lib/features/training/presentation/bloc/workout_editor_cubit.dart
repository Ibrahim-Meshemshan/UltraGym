import '../../../../core/core.dart';
import '../../data/repo/training_repository.dart';
import '../../domain/models/training_models.dart';
import '../../domain/models/workout_draft.dart';

class WorkoutEditorState extends Equatable {
  const WorkoutEditorState({required this.draft, this.errors = const {}, this.saving = false, this.failure});

  final WorkoutDraft draft;

  /// أخطاء الحقول بمفاتيح الخادم (`days.0.exercises.1.name`): من التحقق المحلي أو من 422.
  final Map<String, String> errors;
  final bool saving;

  /// فشل الحفظ (الرسالة أعلى المحرر).
  final Failure? failure;

  String? error(String path) => errors[path];

  WorkoutEditorState copyWith({WorkoutDraft? draft, Map<String, String>? errors, bool? saving, (Failure?,)? failure}) =>
      WorkoutEditorState(
        draft: draft ?? this.draft,
        errors: errors ?? this.errors,
        saving: saving ?? this.saving,
        failure: failure == null ? this.failure : failure.$1,
      );

  @override
  List<Object?> get props => [draft, errors, saving, failure];
}

/// محرر برنامج التدريب: الأيام والتمارين تُضاف وتُحذف محلياً، والحفظ يرسل البرنامج كاملاً.
/// تعديل حقل يمسح خطأه، وتغيير بنية الأيام يمسح كل الأخطاء (المفاتيح بالترتيب).
class WorkoutEditorCubit extends Cubit<WorkoutEditorState> {
  WorkoutEditorCubit(this._repo, WorkoutDraft draft) : super(WorkoutEditorState(draft: draft));

  final TrainingRepository _repo;
  final _keeper = IdempotencyKeeper();

  WorkoutDraft get _d => state.draft;

  void _edit(WorkoutDraft next, {String? path, String? also}) {
    final errors = path == null
        ? const <String, String>{}
        : ({...state.errors}
            ..remove(path)
            ..remove(also));
    emit(state.copyWith(draft: next, errors: errors, failure: (null,)));
  }

  void setTitle(String v) => _edit(_d.copyWith(title: v), path: 'title');
  void setDescription(String v) => _edit(_d.copyWith(description: v), path: 'description');
  void setPlayer(TrainingRef? v) => _edit(_d.copyWith(player: (v,)), path: 'player_id');
  void setTrainer(TrainingRef? v) => _edit(_d.copyWith(trainer: (v,)), path: 'trainer_id');
  void setPeriod(DateTime? from, DateTime? to) => _edit(
    _d.copyWith(period: (from, to)),
    path: 'ends_on',
    also: 'starts_on',
  );
  void setStatus(String v) => _edit(_d.copyWith(status: v), path: 'status');

  int _dayIndex(int uid) => _d.days.indexWhere((d) => d.uid == uid);

  void addDay() {
    if (_d.days.length >= WorkoutDraft.maxDays) return;
    _edit(_d.copyWith(days: [..._d.days, DayDraft.blank()]));
  }

  void removeDay(int uid) => _edit(
    _d.copyWith(
      days: [
        for (final d in _d.days)
          if (d.uid != uid) d,
      ],
    ),
  );

  void setDayTitle(int uid, String v) {
    final i = _dayIndex(uid);
    _edit(
      _d.copyWith(days: [for (final d in _d.days) d.uid == uid ? d.copyWith(title: v) : d]),
      path: 'days.$i.title',
    );
  }

  void addExercise(int dayUid) => _updateDay(dayUid, (d) {
    if (d.exercises.length >= WorkoutDraft.maxExercises) return d;
    return d.copyWith(
      exercises: [
        ...d.exercises,
        ExerciseDraft(uid: DraftIds.next()),
      ],
    );
  });

  void removeExercise(int dayUid, int uid) => _updateDay(
    dayUid,
    (d) => d.copyWith(
      exercises: [
        for (final e in d.exercises)
          if (e.uid != uid) e,
      ],
    ),
  );

  /// `field` = مفتاح الخادم: `name`، `sets`، `reps`، `rest_seconds`، `notes`.
  void setExercise(int dayUid, int uid, String field, String v) {
    final i = _dayIndex(dayUid);
    final j = i < 0 ? -1 : _d.days[i].exercises.indexWhere((e) => e.uid == uid);
    ExerciseDraft apply(ExerciseDraft e) => switch (field) {
      'name' => e.copyWith(name: v),
      'sets' => e.copyWith(sets: v),
      'reps' => e.copyWith(reps: v),
      'rest_seconds' => e.copyWith(rest: v),
      _ => e.copyWith(notes: v),
    };
    final days = [
      for (final d in _d.days)
        d.uid == dayUid ? d.copyWith(exercises: [for (final e in d.exercises) e.uid == uid ? apply(e) : e]) : d,
    ];
    _edit(_d.copyWith(days: days), path: 'days.$i.exercises.$j.$field');
  }

  void _updateDay(int uid, DayDraft Function(DayDraft d) f) =>
      _edit(_d.copyWith(days: [for (final d in _d.days) d.uid == uid ? f(d) : d]));

  /// يرجع البرنامج المحفوظ، أو null (أخطاء محلية أو فشل الخادم بالحالة).
  Future<WorkoutPlan?> save() async {
    final local = _d.validate();
    if (local.isNotEmpty) {
      emit(state.copyWith(errors: local, failure: (null,)));
      return null;
    }
    final body = _d.body();
    emit(state.copyWith(saving: true, errors: const {}, failure: (null,)));
    final r = await _repo.savePlan(body, id: _d.id, idempotencyKey: _d.isNew ? _keeper.keyFor(body) : null);
    if (isClosed) return null;
    switch (r) {
      case ApiSuccess(:final data):
        emit(state.copyWith(saving: false, draft: WorkoutDraft.of(data)));
        return data;
      case ApiFailure(:final failure):
        emit(state.copyWith(saving: false, errors: failure.fieldErrors, failure: (failure,)));
        return null;
    }
  }
}
