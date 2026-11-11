import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'cache_store_base.dart';

/// الجهاز: ملف JSON لكل رد بـ `getApplicationSupportDirectory()/api_cache`.
/// حد 400 رد (يحذف الأقدم كل 40 كتابة)، ولا يُحفظ رد أكبر من 1.5MB.
class FileCacheStore implements CacheStore {
  Directory? _dir;
  int _writes = 0;

  Future<Directory> _folder() async {
    final d = _dir ??= Directory('${(await getApplicationSupportDirectory()).path}/api_cache');
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  @override
  Future<CacheEntry?> read(String key) async {
    try {
      final f = File('${(await _folder()).path}/$key.json');
      return await f.exists() ? CacheEntry.decode(await f.readAsString()) : null;
    } on Object {
      return null;
    }
  }

  @override
  Future<void> write(String key, CacheEntry entry) async {
    try {
      final raw = entry.encode();
      if (raw.length > CacheLimits.maxBytes) return;
      await File('${(await _folder()).path}/$key.json').writeAsString(raw, flush: true);
      if (++_writes % CacheLimits.pruneEvery == 0) await _prune();
    } on Object {
      return;
    }
  }

  Future<void> _prune() async {
    final files = (await _folder()).listSync().whereType<File>().toList();
    if (files.length <= CacheLimits.maxEntries) return;
    files.sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));
    for (final f in files.take(files.length - CacheLimits.maxEntries)) {
      await f.delete();
    }
  }

  @override
  Future<void> clear() async {
    try {
      final d = await _folder();
      if (await d.exists()) await d.delete(recursive: true);
      _dir = null;
    } on Object {
      return;
    }
  }
}

CacheStore createCacheStore() => FileCacheStore();
