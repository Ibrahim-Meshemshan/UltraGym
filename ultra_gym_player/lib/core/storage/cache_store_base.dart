import 'dart:convert';

/// رد محفوظ: البيانات كما وصلت + ETag + وقت الحفظ.
class CacheEntry {
  const CacheEntry({required this.data, required this.savedAt, this.etag});

  factory CacheEntry.decode(String raw) {
    final j = jsonDecode(raw) as Map<String, dynamic>;
    return CacheEntry(data: j['data'], etag: j['etag'] as String?, savedAt: DateTime.parse(j['saved_at'] as String));
  }

  final Object? data;
  final String? etag;
  final DateTime savedAt;

  String encode() => jsonEncode({'data': data, 'etag': etag, 'saved_at': savedAt.toUtc().toIso8601String()});
}

/// تخزين الردود. أي خطأ تخزين يُتجاهل: الكاش اختياري.
abstract interface class CacheStore {
  Future<CacheEntry?> read(String key);
  Future<void> write(String key, CacheEntry entry);
  Future<void> clear();
}

/// حدود الكاش (منهجية §9).
abstract final class CacheLimits {
  static const maxEntries = 400;
  static const pruneEvery = 40;
  static const maxBytes = 1536 * 1024;
}

/// بصمة FNV-1a (32 بت) لمفتاح `token | uri`: كل حساب له كاشه.
String fnv1a(String input) {
  var hash = 0x811c9dc5;
  for (final b in utf8.encode(input)) {
    hash ^= b;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}
