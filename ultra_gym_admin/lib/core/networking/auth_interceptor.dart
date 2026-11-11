import 'dart:async';

import 'package:dio/dio.dart';

import '../error/failure.dart';
import '../storage/session_storage.dart';

/// أحداث الجلسة التي يستمع لها AuthBloc فيعيد الراوتر التوجيه فوراً.
/// `readOnly` (اشتراك النادي منتهٍ، `SUBSCRIPTION_EXPIRED`) لا يغيّر الجلسة: يقرؤه شريط الباقة بالهيكل.
enum SessionEvent { expired, passwordChangeRequired, accountSuspended, tenantBlocked, readOnly }

/// قناة أحداث الجلسة (lazySingleton واحد بالتطبيق).
class SessionEvents {
  final _controller = StreamController<SessionEvent>.broadcast();

  Stream<SessionEvent> get stream => _controller.stream;

  void add(SessionEvent event) => _controller.add(event);

  Future<void> dispose() => _controller.close();
}

/// مفاتيح `Options.extra` التي تفهمها الـ interceptors.
abstract final class RequestFlags {
  /// لا ترسل التوكن (مسارات بلا توكن مثل `/app-version`).
  static const skipAuth = 'skipAuth';

  /// طلب الدخول نفسه: أخطاؤه تُعرض بالنموذج ولا تتحول لأحداث جلسة.
  static const authRequest = 'authRequest';

  /// لا تخزّن هذا الرد بالكاش.
  static const skipCache = 'skip';
}

/// يضيف `Bearer`، ويحوّل أخطاء الجلسة (401، تغيير كلمة سر إجباري، حساب أو نادٍ موقوف) لـ `SessionEvent`.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._session, this._events);

  final SessionStorage _session;
  final SessionEvents _events;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _session.token;
    if (token != null && options.extra[RequestFlags.skipAuth] != true) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final r = err.response;
    if (r != null && err.requestOptions.extra[RequestFlags.authRequest] != true) {
      final data = r.data;
      final code = data is Map ? data['code']?.toString() : null;
      final type = FailureType.fromCode(code) ?? FailureType.fromStatus(r.statusCode);
      final event = switch (type) {
        FailureType.unauthenticated => SessionEvent.expired,
        FailureType.passwordChangeRequired => SessionEvent.passwordChangeRequired,
        FailureType.accountSuspended => SessionEvent.accountSuspended,
        FailureType.tenantSuspended || FailureType.subscriptionInactive => SessionEvent.tenantBlocked,
        FailureType.subscriptionExpired => SessionEvent.readOnly,
        _ => null,
      };
      if (event != null) _events.add(event);
    }
    handler.next(err);
  }
}
