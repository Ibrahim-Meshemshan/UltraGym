import 'package:dio/dio.dart';

/// ساعة الخادم: فرق ساعة الجهاز عن `X-Server-Time`. استعمل `now()` لـ QR والعمليات دون اتصال.
class ServerClock {
  Duration _offset = Duration.zero;
  bool _synced = false;

  Duration get offset => _offset;
  bool get isSynced => _synced;

  void sync(DateTime serverUtc) {
    _offset = serverUtc.toUtc().difference(DateTime.now().toUtc());
    _synced = true;
  }

  /// الوقت الحالي بتوقيت الخادم (UTC).
  DateTime now() => DateTime.now().toUtc().add(_offset);
}

/// يقرأ `X-Server-Time` من كل رد (ناجح أو خطأ) ويحدّث `ServerClock`.
class ServerClockInterceptor extends Interceptor {
  ServerClockInterceptor(this._clock);

  final ServerClock _clock;

  void _read(Headers headers) {
    final t = DateTime.tryParse(headers.value('x-server-time') ?? '');
    if (t != null) _clock.sync(t);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    _read(response.headers);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final r = err.response;
    if (r != null) _read(r.headers);
    handler.next(err);
  }
}
