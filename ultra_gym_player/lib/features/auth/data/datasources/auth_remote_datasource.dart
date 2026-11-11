import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/core.dart';
import '../../domain/models/auth_models.dart';
import '../repo/auth_repository.dart';

/// الدخول والجلسة عبر `ApiClient`. التوكن يُحفظ هنا عند نجاح الدخول ويُمسح عند الخروج.
class AuthRemoteDataSource implements AuthRepository {
  AuthRemoteDataSource(this._api, this._session);

  final ApiClient _api;
  final SessionStorage _session;

  static const _base = AppConfig.authBase;

  /// طلبات الدخول: أخطاؤها تُعرض بالنموذج ولا تتحول لأحداث جلسة.
  static final _authOnly = Options(extra: {RequestFlags.authRequest: true});

  @override
  bool get hasToken => _session.hasToken;

  @override
  Future<ApiResult<LoginOutcome>> login({required String phone, required String password, int? tenantId}) async {
    final r = await _api.post(
      '$_base/login',
      options: _authOnly,
      body: {
        'phone': phone.trim(),
        'password': password,
        'device_name': deviceName,
        'tenant_id': ?tenantId,
        if (AppConfig.loginApp.isNotEmpty) 'app': AppConfig.loginApp,
      },
      parse: Parse.json,
    );
    switch (r) {
      case ApiSuccess<Json>(:final data, :final message):
        if (data.flag('requires_tenant_selection')) {
          return ApiSuccess(LoginNeedsTenant(data.list('tenants', TenantChoice.fromJson)), message: message);
        }
        await _session.save(data.str('token'));
        final session = Session.fromJson(data);
        _applyTimezone(session);
        return ApiSuccess(LoginSucceeded(session), message: message);
      case ApiFailure<Json>(:final failure):
        return ApiFailure(failure);
    }
  }

  @override
  Future<ApiResult<Session>> me() async {
    final r = await _api.get('$_base/me', parse: Parse.object(Session.fromJson));
    if (r case ApiSuccess<Session>(:final data)) _applyTimezone(data);
    return r;
  }

  @override
  Future<ApiResult<void>> changePassword(Json body) => _api.post('$_base/change-password', body: body, parse: Parse.none);

  @override
  Future<void> logout() async {
    if (_session.hasToken) await _api.post('$_base/logout', body: const {}, options: _authOnly, parse: Parse.none);
    await _session.clear();
  }

  @override
  Future<void> clearLocal() => _session.clear();

  @override
  Future<void> registerDevice() async {
    if (AppConfig.platformApp.isEmpty || !_session.hasToken) return;
    await _api.post(
      '/devices',
      body: {'app': AppConfig.platformApp, 'platform': platformName, 'app_version': AppConfig.appVersion},
      parse: Parse.none,
    );
  }

  @override
  Future<AppVersionInfo?> checkVersion() async {
    if (AppConfig.platformApp.isEmpty || kIsWeb) return null;
    final r = await _api.get(
      '/app-version',
      query: {'app': AppConfig.platformApp, 'platform': platformName, 'version': AppConfig.appVersion},
      options: Options(extra: {RequestFlags.skipAuth: true, RequestFlags.skipCache: true}),
      parse: (d) => AppVersionInfo.fromJson(asJson(d), AppConfig.appVersion),
    );
    return r.dataOrNull;
  }

  void _applyTimezone(Session s) => Formatters.setTimezone(s.tenant?.timezone ?? AppConfig.defaultTimezone);

  /// منصة الجهاز كما يتوقعها الخادم.
  static String get platformName => kIsWeb
      ? 'web'
      : switch (defaultTargetPlatform) {
          TargetPlatform.iOS => 'ios',
          _ => 'android',
        };

  /// اسم الجهاز لقائمة "جلساتي".
  static String get deviceName => kIsWeb
      ? 'المتصفح · ${AppConfig.appTitle}'
      : switch (defaultTargetPlatform) {
          TargetPlatform.iOS => 'iPhone · ${AppConfig.appTitle}',
          _ => 'Android · ${AppConfig.appTitle}',
        };
}
