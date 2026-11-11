import 'token_store_base.dart';

/// جلسة المستخدم: التوكن (يُقرأ قبل runApp) ومسحه مع الكاش عند الخروج أو الانتهاء أو الإيقاف.
class SessionStorage {
  SessionStorage(this._store, {this.onClear});

  final TokenStore _store;

  /// يُستدعى مع كل مسح (مسح كاش الردود مثلاً).
  final Future<void> Function()? onClear;

  String? _token;

  String? get token => _token;
  bool get hasToken => _token != null && _token!.isNotEmpty;

  Future<void> load() async => _token = await _store.read();

  Future<void> save(String token) async {
    _token = token;
    await _store.write(token);
  }

  Future<void> clear() async {
    _token = null;
    await _store.clear();
    await onClear?.call();
  }
}
