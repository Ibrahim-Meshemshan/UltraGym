import '../../../../core/core.dart';
import '../../domain/models/branch_models.dart';

// فروع النادي المسموحة للمستخدم الحالي./
abstract interface class BranchesRepository {
  /// كل الفروع بطلب واحد (أقصى صفحة 100، والنادي أقل من ذلك بكثير).
  Future<ApiResult<List<Branch>>> list();
}
