import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// محوّل HTTP وهمي: يرجع ما يحدده الاختبار ويحفظ آخر طلب.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.respond);

  ResponseBody Function(RequestOptions options) respond;
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonBody(int status, Object body, {Map<String, List<String>> headers = const {}}) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        ...headers,
      },
    );
