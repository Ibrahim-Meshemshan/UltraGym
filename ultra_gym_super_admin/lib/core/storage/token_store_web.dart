import 'package:web/web.dart' as web;

import '../config/app_config.dart';
import 'token_store_base.dart';

export 'token_store_base.dart';

/// الويب: `localStorage` للجلسات الطويلة، أو `sessionStorage` (تنتهي بإغلاق التبويب) حسب `AppConfig.persistentWebSession`.
class WebTokenStore implements TokenStore {
  WebTokenStore({required this.persistent});

  final bool persistent;
  static const _key = 'ug_token';

  web.Storage get _storage => persistent ? web.window.localStorage : web.window.sessionStorage;

  @override
  Future<String?> read() async => _storage.getItem(_key);

  @override
  Future<void> write(String token) async => _storage.setItem(_key, token);

  @override
  Future<void> clear() async => _storage.removeItem(_key);
}

TokenStore createTokenStore() => WebTokenStore(persistent: AppConfig.persistentWebSession);
