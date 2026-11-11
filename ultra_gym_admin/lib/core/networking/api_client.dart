import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../error/error_handler.dart';
import '../utils/json_x.dart';
import 'api_result.dart';
import 'list_query.dart';
import 'paged.dart';
import 'parse.dart';

/// ملف نزل من الخادم (فاتورة، إيصال، تقرير). `isHtml` = الخادم بلا محرك PDF (`html-printable`).
class FileBlob {
  const FileBlob({required this.filename, required this.contentType, required this.bytes, this.isHtml = false});

  final String filename, contentType;
  final Uint8List bytes;
  final bool isHtml;
}

/// واجهة الطلبات الوحيدة. كل دالة ترجع `ApiResult` ولا ترمي استثناء.
class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  Future<ApiResult<T>> get<T>(String path, {required Parser<T> parse, Json? query, Options? options}) =>
      _send(() => _dio.get<dynamic>(path, queryParameters: query, options: options), parse);

  Future<ApiResult<T>> post<T>(
    String path, {
    required Parser<T> parse,
    Object? body,
    Json? query,
    String? idempotencyKey,
    Options? options,
  }) => _send(
    () => _dio.post<dynamic>(path, data: body, queryParameters: query, options: _opts(options, idempotencyKey)),
    parse,
  );

  Future<ApiResult<T>> put<T>(
    String path, {
    required Parser<T> parse,
    Object? body,
    String? idempotencyKey,
    Options? options,
  }) => _send(() => _dio.put<dynamic>(path, data: body, options: _opts(options, idempotencyKey)), parse);

  Future<ApiResult<T>> patch<T>(
    String path, {
    required Parser<T> parse,
    Object? body,
    String? idempotencyKey,
    Options? options,
  }) => _send(() => _dio.patch<dynamic>(path, data: body, options: _opts(options, idempotencyKey)), parse);

  Future<ApiResult<T>> delete<T>(
    String path, {
    required Parser<T> parse,
    Object? body,
    Json? query,
    Options? options,
  }) => _send(() => _dio.delete<dynamic>(path, data: body, queryParameters: query, options: options), parse);

  /// رفع ملف (`multipart/form-data`).
  Future<ApiResult<T>> upload<T>(String path, {required FormData form, required Parser<T> parse}) =>
      _send(() => _dio.post<dynamic>(path, data: form), parse);

  Future<ApiResult<T>> getObject<T>(String path, {required T Function(Json json) fromJson, Json? query}) =>
      get(path, query: query, parse: Parse.object(fromJson));

  Future<ApiResult<List<T>>> getList<T>(String path, {required T Function(Json json) fromJson, Json? query}) =>
      get(path, query: query, parse: Parse.list(fromJson));

  /// قائمة مقسّمة: العناصر + `meta.pagination` + `meta.summary`.
  Future<ApiResult<Paged<T>>> getPaged<T>(
    String path, {
    required T Function(Json json) fromJson,
    ListQuery query = const ListQuery(),
    Json? extra,
  }) async {
    final r = await get(path, query: {...query.toParams(), ...?extra}, parse: Parse.list(fromJson));
    return switch (r) {
      ApiSuccess<List<T>>(:final data, :final meta, :final message, :final cachedAt) => ApiSuccess(
        Paged(
          items: data,
          pagination: Pagination.fromJson(meta.obj('pagination')),
          summary: meta.obj('summary'),
          meta: meta,
        ),
        message: message,
        meta: meta,
        cachedAt: cachedAt,
      ),
      ApiFailure<List<T>>(:final failure) => ApiFailure(failure),
    };
  }

  /// قيمة + `meta` كاملة (مثل `unread_count` و `period`).
  Future<ApiResult<(T, Json)>> getWithMeta<T>(String path, {required Parser<T> parse, Json? query}) async {
    final r = await get(path, query: query, parse: parse);
    return switch (r) {
      ApiSuccess<T>(:final data, :final meta, :final message, :final cachedAt) => ApiSuccess(
        (data, meta),
        message: message,
        meta: meta,
        cachedAt: cachedAt,
      ),
      ApiFailure<T>(:final failure) => ApiFailure(failure),
    };
  }

  /// تنزيل ملف محمي بالتوكن. بالويب يطلب `?as=base64` حتى لا تلتقطه برامج التحميل.
  Future<ApiResult<FileBlob>> getBytes(String path, {Json? query}) =>
      _bytes((q, o) => _dio.get<dynamic>(path, queryParameters: q, options: o), query);

  Future<ApiResult<FileBlob>> postBytes(String path, {Object? body, Json? query, String? idempotencyKey}) => _bytes(
    (q, o) => _dio.post<dynamic>(path, data: body, queryParameters: q, options: _opts(o, idempotencyKey)),
    query,
  );

  Future<ApiResult<FileBlob>> _bytes(Future<Response<dynamic>> Function(Json q, Options o) call, Json? query) async {
    try {
      if (kIsWeb) {
        final r = await call({...?query, 'as': 'base64'}, Options());
        final body = asJson(r.data);
        final j = body.containsKey('base64') ? body : body.obj('data');
        return ApiSuccess(
          FileBlob(
            filename: j.str('filename', 'file'),
            contentType: j.str('content_type', 'application/octet-stream'),
            bytes: base64Decode(j.str('base64')),
            isHtml: r.headers.value('x-document-format') == 'html-printable',
          ),
        );
      }
      final r = await call({...?query}, Options(responseType: ResponseType.bytes));
      return ApiSuccess(
        FileBlob(
          filename: _filename(r.headers.value('content-disposition')),
          contentType: r.headers.value('content-type') ?? 'application/octet-stream',
          bytes: Uint8List.fromList(r.data as List<int>),
          isHtml: r.headers.value('x-document-format') == 'html-printable',
        ),
      );
    } catch (e, s) {
      return ApiFailure(ErrorHandler.handle(e, s));
    }
  }

  Future<ApiResult<T>> _send<T>(Future<Response<dynamic>> Function() call, Parser<T> parse) async {
    try {
      final r = await call();
      final body = asJson(r.data);
      if (body['success'] == false) return ApiFailure(ErrorHandler.fromResponse(r));
      return ApiSuccess(
        parse(body['data']),
        message: body.strOrNull('message'),
        meta: body.obj('meta'),
        cachedAt: r.extra['fromCache'] == true ? r.extra['cachedAt'] as DateTime? : null,
      );
    } catch (e, s) {
      return ApiFailure(ErrorHandler.handle(e, s));
    }
  }

  static Options? _opts(Options? options, String? idempotencyKey) {
    if (idempotencyKey == null) return options;
    final o = options ?? Options();
    return o.copyWith(headers: {...?o.headers, 'Idempotency-Key': idempotencyKey});
  }

  static String _filename(String? disposition) {
    final m = RegExp(r'''filename\*?=(?:UTF-8'')?"?([^";]+)"?''', caseSensitive: false).firstMatch(disposition ?? '');
    return m == null ? 'file' : Uri.decodeComponent(m[1]!);
  }
}
