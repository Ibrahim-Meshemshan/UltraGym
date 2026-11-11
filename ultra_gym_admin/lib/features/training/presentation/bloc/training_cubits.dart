import '../../../../core/core.dart';
import '../../data/repo/training_repository.dart';
import '../../domain/models/training_models.dart';

/// فلاتر قائمة البرامج بالخادم.
abstract final class WorkoutFilters {
  /// 1 = القوالب العامة فقط، 0 = برامج الأعضاء فقط (قاعدة `boolean` بلارافيل لا تقبل "true").
  static const templates = 'templates';
  static const perPage = 30;

  static ListQuery query({required bool templates}) =>
      ListQuery(perPage: perPage, filters: {WorkoutFilters.templates: templates ? 1 : 0});
}

/// قائمة البرامج (لأعضاء أو قوالب عامة) بـ "عرض المزيد"، والبحث بالعنوان.
class WorkoutPlansCubit extends ListCubit<WorkoutPlan> {
  WorkoutPlansCubit(TrainingRepository repo, bool templates)
    : super((q) => repo.plans(q), query: WorkoutFilters.query(templates: templates));
}

/// برنامج واحد بأيامه (للمحرر).
class WorkoutPlanCubit extends LoadCubit<WorkoutPlan> {
  WorkoutPlanCubit(TrainingRepository repo, int id) : super(() => repo.plan(id));
}

/// المدربون الفعّالون لقائمة "المدرب" بالمحرر.
class TrainersCubit extends LoadCubit<List<TrainingRef>> {
  TrainersCubit(TrainingRepository repo) : super(repo.trainers);
}

/// اسم العضو لرابط `?player_id=`.
class TrainingMemberCubit extends LoadCubit<TrainingMember> {
  TrainingMemberCubit(TrainingRepository repo, int id) : super(() => repo.member(id));
}

/// قياسات عضو (صفحة واحدة؛ صفحة أخرى = Cubit جديد).
class MeasurementsCubit extends LoadCubit<MeasurementsPage> {
  MeasurementsCubit(TrainingRepository repo, ({int playerId, int page}) args)
    : super(() => repo.measurements(args.playerId, page: args.page));
}
