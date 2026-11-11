import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ultra_gym_admin/core/error/failure.dart';
import 'package:ultra_gym_admin/core/networking/api_result.dart';
import 'package:ultra_gym_admin/core/utils/json_x.dart';
import 'package:ultra_gym_admin/features/branches/domain/models/branch_models.dart';
import 'package:ultra_gym_admin/features/branches/presentation/bloc/branch_scope_cubit.dart';
import 'package:ultra_gym_admin/features/branches/presentation/widgets/cash_status_badge.dart';
import 'package:ultragym_design/ultragym_design.dart';

import 'fake_branches_repository.dart';

const _key = 'branch.1.7';
const _fail = ApiFailure<List<Branch>>(Failure(type: FailureType.network, message: 'تعذّر الاتصال.'));

void main() {
  late SharedPreferences prefs;

  Future<BranchScopeCubit> loaded(List<ApiResult<List<Branch>>> results, {Map<String, Object> saved = const {}}) async {
    SharedPreferences.setMockInitialValues(saved);
    prefs = await SharedPreferences.getInstance();
    final cubit = BranchScopeCubit(FakeBranchesRepository(results), prefs, storageKey: _key);
    await cubit.load();
    return cubit;
  }

  test('parses the branches response', () {
    final b = Branch.fromJson(
      asJson({
        'id': 2,
        'name': 'فرع المالكي',
        'city': 'دمشق',
        'is_main': false,
        'status': 'active',
        'gender_policy': 'time_split',
        'cash_session_open': true,
      }),
    );
    expect(
      b,
      const Branch(id: 2, name: 'فرع المالكي', city: 'دمشق', genderPolicy: 'time_split', cashSessionOpen: true),
    );
  });

  test('one active branch is chosen automatically and cannot be changed', () async {
    final cubit = await loaded([
      const ApiSuccess([mainBranch, closedBranch]),
    ]);
    expect(cubit.state.branchId, mainBranch.id);
    expect(cubit.state.canChoose, isFalse);
    expect(CashStatusBadge.label(cubit.state), ('الصندوق مفتوح', UTone.accent));
    await cubit.close();
  });

  test('several branches start on all branches, and the choice is saved per user and club', () async {
    final cubit = await loaded([
      const ApiSuccess([mainBranch, malkiBranch]),
    ]);
    expect(cubit.state.branchId, isNull);
    expect(CashStatusBadge.label(cubit.state), ('الصندوق: 1 من 2 مفتوح', UTone.accent));

    await cubit.select(malkiBranch.id);
    expect(cubit.state.selected, malkiBranch);
    expect(prefs.getInt(_key), malkiBranch.id);
    expect(CashStatusBadge.label(cubit.state), ('الصندوق مغلق', UTone.warning));

    await cubit.select(null);
    expect(prefs.containsKey(_key), isFalse);
    await cubit.close();
  });

  test('a saved branch is restored, and one that is gone or inactive falls back to all', () async {
    var cubit = await loaded(
      [
        const ApiSuccess([mainBranch, malkiBranch]),
      ],
      saved: {'flutter.$_key': 2},
    );
    expect(cubit.state.branchId, 2);
    await cubit.close();

    cubit = await loaded(
      [
        const ApiSuccess([mainBranch, malkiBranch, closedBranch]),
      ],
      saved: {'flutter.$_key': 3},
    );
    expect(cubit.state.branchId, isNull);
    await cubit.close();
  });

  test('silent refresh keeps the list on failure; first load failure is shown', () async {
    var cubit = await loaded([
      const ApiSuccess([mainBranch, malkiBranch]),
      _fail,
    ]);
    await cubit.refresh();
    expect(cubit.state.branches.hasData, isTrue);
    expect(cubit.state.branches.isSuccess, isTrue);
    await cubit.close();

    cubit = await loaded([_fail]);
    expect(cubit.state.branches.isFailure, isTrue);
    expect(cubit.state.active, isEmpty);
    await cubit.close();
  });

  test('no open cash session anywhere warns', () async {
    final cubit = await loaded([
      const ApiSuccess([malkiBranch, Branch(id: 4, name: 'فرع رابع')]),
    ]);
    expect(CashStatusBadge.label(cubit.state), ('الصندوق مغلق بكل الفروع', UTone.warning));
    await cubit.close();
  });
}
