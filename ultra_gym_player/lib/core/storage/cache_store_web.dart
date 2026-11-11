import 'package:web/web.dart' as web;

import 'cache_store_base.dart';

/// الويب (للمعاينة فقط): `localStorage` بمفاتيح `ug_cache:`.
class WebCacheStore implements CacheStore {
  static const _prefix = 'ug_cache:';

  web.Storage get _s => web.window.localStorage;

  @override
  Future<CacheEntry?> read(String key) async {
    try {
      final raw = _s.getItem('$_prefix$key');
      return raw == null ? null : CacheEntry.decode(raw);
    } on Object {
      return null;
    }
  }

  @override
  Future<void> write(String key, CacheEntry entry) async {
    try {
      final raw = entry.encode();
      if (raw.length <= CacheLimits.maxBytes) _s.setItem('$_prefix$key', raw);
    } on Object {
      return;
    }
  }

  @override
  Future<void> clear() async {
    final keys = [
      for (var i = 0; i < _s.length; i++)
        if (_s.key(i) case final String k when k.startsWith(_prefix)) k,
    ];
    for (final k in keys) {
      _s.removeItem(k);
    }
  }
}

CacheStore createCacheStore() => WebCacheStore();
