import '../../../../core/core.dart';
import '../../domain/models/quick_search_models.dart';

/// البحث السريع عن عضو بالاسم أو الموبايل أو المعرّف (حرفان على الأقل).
abstract interface class QuickSearchRepository {
  /// `branchId` = فرع تقييم إمكانية الدخول (null = بلا فرع محدد).
  Future<ApiResult<List<LookupPlayer>>> lookup(String q, {int? branchId});
}
