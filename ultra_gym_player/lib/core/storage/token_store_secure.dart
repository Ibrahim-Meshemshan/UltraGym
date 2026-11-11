import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'token_store_base.dart';

export 'token_store_base.dart';

/// الموبايل: التوكن بـ Keychain / Keystore.
class SecureTokenStore implements TokenStore {
  const SecureTokenStore();

  static const _storage = FlutterSecureStorage();
  static const _key = 'ug_token';

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);

  @override
  Future<void> clear() => _storage.delete(key: _key);
}

TokenStore createTokenStore() => const SecureTokenStore();
