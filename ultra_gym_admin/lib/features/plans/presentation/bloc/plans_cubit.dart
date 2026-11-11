import '../../../../core/core.dart';
import '../../data/repo/plans_repository.dart';
import '../../domain/models/plans_models.dart';

/// بطاقات الخطط (50 بالصفحة، بترتيب `sort_order`). `archived=only` لتبويب الأرشيف.
class PlansListCubit extends ListCubit<Plan> {
  PlansListCubit(PlansRepository repo, {bool archived = false})
    : super(
        (q) => repo.plans(q),
        query: ListQuery(perPage: 50, filters: {if (archived) PlanFilters.archived: 'only'}),
      );
}

/// جدول الكوبونات (الأحدث أولاً، 15 بالصفحة).
class CouponsCubit extends ListCubit<Coupon> {
  CouponsCubit(PlansRepository repo) : super((q) => repo.coupons(q));
}

/// كل الخطط (حتى الموقوفة) لاختيار ما يشمله الكوبون وتسمية خططه بالجدول.
class CouponPlansCubit extends LoadCubit<List<Plan>> {
  CouponPlansCubit(PlansRepository repo)
    : super(() async => (await repo.plans(const ListQuery(perPage: 100))).map((p) => p.items));
}

abstract final class PlanFilters {
  static const archived = 'archived', status = 'status';
}
