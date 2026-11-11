import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_gym_super_admin/core/bloc/app_form_cubit.dart';
import 'package:ultra_gym_super_admin/core/bloc/list_cubit.dart';
import 'package:ultra_gym_super_admin/core/bloc/load_cubit.dart';
import 'package:ultra_gym_super_admin/core/bloc/slice.dart';
import 'package:ultra_gym_super_admin/core/error/failure.dart';
import 'package:ultra_gym_super_admin/core/networking/api_result.dart';
import 'package:ultra_gym_super_admin/core/networking/list_query.dart';
import 'package:ultra_gym_super_admin/core/networking/paged.dart';
import 'package:ultra_gym_super_admin/core/utils/json_x.dart';
import 'package:ultra_gym_super_admin/core/utils/validators.dart';

const _fail = Failure(type: FailureType.network, message: 'x');

void main() {
  group('Slice', () {
    test('first load vs refresh keeps previous data', () {
      const s = Slice<int>();
      expect(s.isFirstLoad, isTrue);
      final loaded = s.toLoading().toSuccess(5);
      expect(loaded.toLoading().isRefreshing, isTrue);
      expect(loaded.toFailure(_fail).data, 5);
      expect(loaded.fromResult(const ApiFailure<int>(_fail)).data, 5);
      expect(loaded.mapData((v) => v + 1).data, 6);
    });
  });

  group('LoadCubit', () {
    test('silent refresh failure keeps data', () async {
      var ok = true;
      final c = LoadCubit<int>(() async => ok ? const ApiSuccess(1) : const ApiFailure(_fail));
      await c.load();
      expect(c.state.data, 1);
      ok = false;
      await c.refresh();
      expect(c.state.data, 1);
      expect(c.state.isSuccess, isTrue);
      await c.close();
    });
  });

  group('ListCubit', () {
    test('more() appends the next page, filter() restarts from page 1', () async {
      final calls = <ListQuery>[];
      final c = ListCubit<int>((q) async {
        calls.add(q);
        return ApiSuccess(Paged(items: [q.page * 10], pagination: Pagination(currentPage: q.page, lastPage: 2)));
      });
      await c.load();
      await c.more();
      expect(c.state.slice.data!.items, [10, 20]);
      expect(c.state.canLoadMore, isFalse);
      await c.filter('status', 'active');
      expect(calls.last.page, 1);
      expect(calls.last.filters['status'], 'active');
      expect(c.state.slice.data!.items, [10]);
      await c.close();
    });
  });

  group('AppFormCubit', () {
    test('local validation blocks submit', () async {
      final f = AppFormCubit();
      f.text('name');
      f.validator('name', Validators.required('اكتب اسمك.'));
      var sent = false;
      final r = await f.submit((_) async {
        sent = true;
        return const ApiSuccess<void>(null);
      });
      expect(r, isNull);
      expect(sent, isFalse);
      expect(f.state.errorOf('name'), 'اكتب اسمك.');
      await f.close();
    });

    test('apiBody nests dotted names, formats dates, and 422 errors land on fields', () async {
      final f = AppFormCubit(initial: {'owner.name': 'سامر'});
      f.text('owner.name');
      f.text('owner.phone').text = '0944123456';
      f.set('starts_on', DateTime(2026, 10, 7));
      f.set('payments.0.amount', 5);
      final body = f.apiBody();
      expect(body, {
        'owner': {'name': 'سامر', 'phone': '0944123456'},
        'starts_on': '2026-10-07',
        'payments': [
          {'amount': 5},
        ],
      });
      await f.submit<void>((_) async => const ApiFailure(Failure(
            type: FailureType.validation,
            message: 'غير صالح',
            errors: {
              'owner.phone': ['مستخدم'],
              'tenant.slug': ['محجوز'],
            },
          )));
      expect(f.state.errorOf('owner.phone'), 'مستخدم');
      expect(f.orphanErrors, ['محجوز']);
      expect(f.state.submitting, isFalse);
      await f.close();
    });
  });

  group('ListQuery', () {
    test('params, filters and clearing', () {
      final q = const ListQuery().withSearch(' x ').withFilter('branch_id', 2).withSort('name', SortDir.asc).withPage(3);
      expect(q.toParams(), {'page': 3, 'per_page': 15, 'search': 'x', 'sort_by': 'name', 'sort_dir': 'asc', 'branch_id': 2});
      expect(q.withFilter('branch_id', null).filters, isEmpty);
      expect(q.cleared().hasFilters, isFalse);
      expect(q.cleared().sortBy, 'name');
    });
  });

  group('json_x', () {
    test('safe reads never throw', () {
      final Json j = {'id': '12', 'n': 2.5, 'ok': 1, 'at': '2026-11-04T12:30:00Z', 'on': '2026-11-10', 'tags': ['a', null]};
      expect(j.intv('id'), 12);
      expect(j.intv('missing', 3), 3);
      expect(j.dbl('n'), 2.5);
      expect(j.flag('ok'), isTrue);
      expect(j.date('at')!.isUtc, isTrue);
      expect(j.day('on'), DateTime(2026, 11, 10));
      expect(j.strList('tags'), ['a']);
      expect(j.obj('nothing'), isEmpty);
      expect(asList<int>('bad', (e) => 1), isEmpty);
    });
  });
}
