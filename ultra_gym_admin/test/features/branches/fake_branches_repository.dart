import 'package:ultra_gym_admin/core/networking/api_result.dart';
import 'package:ultra_gym_admin/features/branches/data/repo/branches_repository.dart';
import 'package:ultra_gym_admin/features/branches/domain/models/branch_models.dart';

const mainBranch = Branch(id: 1, name: 'الفرع الرئيسي - المزة', city: 'دمشق', isMain: true, cashSessionOpen: true);
const malkiBranch = Branch(id: 2, name: 'فرع المالكي', city: 'دمشق');
const closedBranch = Branch(id: 3, name: 'فرع مؤرشف', status: 'inactive');

/// مستودع فروع وهمي: النتائج بالترتيب، والأخيرة تتكرر.
class FakeBranchesRepository implements BranchesRepository {
  FakeBranchesRepository(this.results);

  final List<ApiResult<List<Branch>>> results;
  int calls = 0;

  @override
  Future<ApiResult<List<Branch>>> list() async {
    calls++;
    return results.length > 1 ? results.removeAt(0) : results.first;
  }
}
