import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_gym_player/core/error/failure.dart';
import 'package:ultra_gym_player/core/networking/api_client.dart';
import 'package:ultra_gym_player/core/networking/api_result.dart';
import 'package:ultra_gym_player/core/networking/auth_interceptor.dart';
import 'package:ultra_gym_player/core/networking/list_query.dart';
import 'package:ultra_gym_player/core/networking/paged.dart';
import 'package:ultra_gym_player/core/networking/parse.dart';
import 'package:ultra_gym_player/core/networking/server_clock.dart';
import 'package:ultra_gym_player/core/storage/session_storage.dart';
import 'package:ultra_gym_player/core/storage/token_store_base.dart';
import 'package:ultra_gym_player/core/utils/json_x.dart';

import 'fake_api.dart';

class _Item {
  const _Item(this.id, this.name);
  factory _Item.fromJson(Json j) => _Item(j.intv('id'), j.str('name'));
  final int id;
  final String name;
}

void main() {
  late FakeAdapter adapter;
  late ApiClient api;
  late SessionStorage session;
  late SessionEvents events;
  late ServerClock clock;

  setUp(() async {
    adapter = FakeAdapter((_) => jsonBody(200, {'success': true, 'data': null}));
    session = SessionStorage(MemoryTokenStore());
    events = SessionEvents();
    clock = ServerClock();
    final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:8000/api/v1', headers: {'Accept': 'application/json'}))
      ..httpClientAdapter = adapter
      ..interceptors.addAll([ServerClockInterceptor(clock), AuthInterceptor(session, events)]);
    api = ApiClient(dio);
  });

  test('parses the success envelope, message and meta', () async {
    adapter.respond = (_) => jsonBody(200, {
          'success': true,
          'message': 'الملف',
          'data': {'id': 7, 'name': 'أحمد'},
          'meta': {'x': 1},
        });
    final r = await api.getObject('/profile', fromJson: _Item.fromJson);
    expect(r, isA<ApiSuccess<_Item>>());
    final s = r as ApiSuccess<_Item>;
    expect(s.data.id, 7);
    expect(s.message, 'الملف');
    expect(s.meta['x'], 1);
    expect(adapter.last!.uri.toString(), 'http://127.0.0.1:8000/api/v1/profile');
  });

  test('getPaged reads items, pagination and summary, and sends list params', () async {
    adapter.respond = (_) => jsonBody(200, {
          'success': true,
          'data': [
            {'id': 1, 'name': 'a'},
            {'id': 2, 'name': 'b'},
          ],
          'meta': {
            'pagination': {'current_page': 1, 'per_page': 2, 'total': 5, 'last_page': 3},
            'summary': {'due_usd': 10},
          },
        });
    final r = await api.getPaged(
      '/club-admin/players',
      fromJson: _Item.fromJson,
      query: const ListQuery(perPage: 2).withSearch('أحمد').withFilter('status', 'active'),
    );
    final page = r.dataOrNull!;
    expect(page.items.map((e) => e.id), [1, 2]);
    expect(page.pagination, const Pagination(perPage: 2, total: 5, lastPage: 3));
    expect(page.hasMore, isTrue);
    expect(page.summary['due_usd'], 10);
    final q = adapter.last!.queryParameters;
    expect(q['search'], 'أحمد');
    expect(q['status'], 'active');
    expect(q['page'], 1);
  });

  test('422 becomes a validation Failure with field errors, never an exception', () async {
    adapter.respond = (_) => jsonBody(422, {
          'success': false,
          'message': 'البيانات المدخلة غير صالحة',
          'code': 'VALIDATION_ERROR',
          'errors': {
            'owner.phone': ['The owner.phone field is required.'],
          },
        });
    final r = await api.post('/super-admin/tenants', body: const {}, parse: Parse.none);
    final f = r.failureOrNull!;
    expect(f.type, FailureType.validation);
    expect(f.message, 'البيانات المدخلة غير صالحة');
    expect(f.fieldError('owner'), 'هذا الحقل مطلوب.');
  });

  test('business 409 keeps its code for special handling', () async {
    adapter.respond = (_) => jsonBody(409, {'success': false, 'message': 'لا وردية مفتوحة', 'code': 'CASH_SESSION_REQUIRED'});
    final r = await api.post('/club-admin/memberships/1/payments', parse: Parse.none);
    expect(r.failureOrNull!.type, FailureType.conflict);
    expect(r.failureOrNull!.hasCode('CASH_SESSION_REQUIRED'), isTrue);
  });

  test('sends Bearer token and Idempotency-Key, syncs server time', () async {
    await session.save('abc');
    adapter.respond = (_) => jsonBody(201, {'success': true, 'data': {}}, headers: {
          'x-server-time': ['2026-11-10T09:30:00Z'],
        });
    await api.post('/club-admin/memberships', body: const {'plan_id': 1}, idempotencyKey: 'key-1', parse: Parse.none);
    expect(adapter.last!.headers['Authorization'], 'Bearer abc');
    expect(adapter.last!.headers['Idempotency-Key'], 'key-1');
    expect(clock.isSynced, isTrue);
  });

  test('401 emits a session-expired event', () async {
    adapter.respond = (_) => jsonBody(401, {'success': false, 'message': 'x', 'code': 'UNAUTHENTICATED'});
    final next = events.stream.first;
    final r = await api.get('/auth/me', parse: Parse.json);
    expect(r.failureOrNull!.type, FailureType.unauthenticated);
    expect(await next, SessionEvent.expired);
  });

  test('network errors map to a network Failure', () async {
    adapter.respond = (o) => throw DioException.connectionError(requestOptions: o, reason: 'down');
    final r = await api.get('/ping', parse: Parse.none);
    expect(r.failureOrNull!.isNetwork, isTrue);
  });
}
