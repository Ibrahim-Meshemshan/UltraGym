import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'failure.dart';
import 'validation_translator.dart';

/// يحوّل أي استثناء (Dio، Format، Type...) أو رد خطأ من الخادم إلى `Failure` برسالة عربية.
abstract final class ErrorHandler {
  static Failure handle(Object error, [StackTrace? stack]) {
    if (error is Failure) return error;
    if (error is DioException) return _dio(error);
    if (error is FormatException || error is TypeError) {
      debugPrint('[ErrorHandler] bad payload: $error\n$stack');
      return const Failure(type: FailureType.unknown, message: _badPayload);
    }
    debugPrint('[ErrorHandler] $error\n$stack');
    return Failure(type: FailureType.unknown, message: defaultMessage(FailureType.unknown));
  }

  /// رد خطأ من الخادم (أي رمز حالة)، أو رد 2xx فيه `success: false`.
  static Failure fromResponse(Response<dynamic> response) {
    final body = _body(response.data);
    final code = body['code']?.toString();
    final status = response.statusCode;
    final type = FailureType.fromCode(code) ?? FailureType.fromStatus(status);
    final raw = body['message']?.toString().trim();
    return Failure(
      type: type,
      code: code,
      statusCode: status,
      message: (raw == null || raw.isEmpty) ? defaultMessage(type) : raw,
      errors: _errors(body['errors']),
      data: body['data'],
      retryAfter: _retryAfter(response.headers.value('retry-after')),
    );
  }

  static Failure _dio(DioException e) {
    if (e.error is Failure) return e.error! as Failure;
    final type = switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => FailureType.timeout,
      DioExceptionType.cancel => FailureType.cancelled,
      DioExceptionType.badResponse => null,
      _ => FailureType.network,
    };
    if (type == null && e.response != null) return fromResponse(e.response!);
    final t = type ?? FailureType.network;
    return Failure(type: t, message: defaultMessage(t));
  }

  static Map<String, dynamic> _body(Object? data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    try {
      if (data is String && data.isNotEmpty) return _body(jsonDecode(data));
      if (data is List<int> && data.isNotEmpty) return _body(jsonDecode(utf8.decode(data)));
    } on FormatException {
      return const {};
    }
    return const {};
  }

  static Map<String, List<String>> _errors(Object? raw) {
    if (raw is! Map) return const {};
    return {
      for (final e in raw.entries)
        e.key.toString(): [
          for (final m in (e.value is List ? e.value as List : [e.value]))
            if (m != null) ValidationTranslator.translate(m.toString()),
        ],
    };
  }

  static Duration? _retryAfter(String? value) {
    final s = int.tryParse(value ?? '');
    return s == null ? null : Duration(seconds: s);
  }

  static const _badPayload = 'وصلت بيانات غير متوقعة من الخادم. أعد المحاولة لاحقاً.';

  /// رسالة احتياطية لكل نوع حين لا يرسل الخادم رسالة.
  static String defaultMessage(FailureType type) => switch (type) {
    FailureType.unauthenticated => 'انتهت الجلسة. سجّل الدخول من جديد.',
    FailureType.invalidCredentials => 'الموبايل أو كلمة السر غير صحيحة. تأكد منهما وأعد المحاولة.',
    FailureType.passwordChangeRequired => 'يجب تغيير كلمة السر المؤقتة قبل المتابعة.',
    FailureType.temporaryPasswordExpired => 'انتهت صلاحية كلمة السر المؤقتة. اطلب كلمة سر جديدة من النادي.',
    FailureType.accountSuspended => 'هذا الحساب موقوف. تواصل مع إدارة النادي.',
    FailureType.noActiveMembership => 'لا توجد عضوية فعّالة بأي نادٍ لهذا الحساب.',
    FailureType.appNotAllowedForRole => 'هذا الحساب لا يملك صلاحية الدخول لهذا التطبيق.',
    FailureType.tenantSuspended => 'حساب النادي موقوف حالياً. تواصل مع فريق UltraGym.',
    FailureType.subscriptionInactive => 'اشتراك النادي غير فعّال. تواصل مع فريق UltraGym.',
    FailureType.subscriptionExpired => 'انتهى اشتراك النادي. يمكنك العرض فقط حتى التجديد.',
    FailureType.featureNotAvailable => 'هذه الميزة غير متاحة بباقة النادي.',
    FailureType.forbidden || FailureType.branchForbidden => 'لا تملك صلاحية هذه العملية.',
    FailureType.planLimitReached => 'وصلت لحد باقة النادي. رقِّ الباقة للمتابعة.',
    FailureType.notFound => 'العنصر غير موجود. ربما حُذف أو لا يخصك.',
    FailureType.conflict => 'تعذّر إتمام العملية بسبب حالة البيانات الحالية.',
    FailureType.validation => 'البيانات المدخلة غير صالحة. راجع الحقول المحددة.',
    FailureType.tooManyRequests => 'محاولات كثيرة. انتظر قليلاً ثم أعد المحاولة.',
    FailureType.maintenance => 'النظام تحت الصيانة. سنعيد المحاولة تلقائياً بعد دقيقة.',
    FailureType.server => 'حدث خطأ بالخادم. أعد المحاولة بعد قليل.',
    FailureType.network => 'تعذّر الاتصال بالخادم. تأكد من الإنترنت وأعد المحاولة.',
    FailureType.timeout => 'انتهت مهلة الاتصال. تأكد من الإنترنت وأعد المحاولة.',
    FailureType.offline => 'لا يوجد اتصال بالإنترنت. هذه العملية تحتاج اتصالاً.',
    FailureType.cancelled => 'أُلغي الطلب.',
    FailureType.unknown => 'حدث خطأ غير متوقع. أعد المحاولة.',
  };
}
