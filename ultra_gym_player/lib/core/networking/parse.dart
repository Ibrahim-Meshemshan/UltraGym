import 'package:uuid/uuid.dart';

import '../utils/json_x.dart';

/// يحوّل حقل `data` من الرد إلى النوع المطلوب.
typedef Parser<T> = T Function(Object? data);

/// محوّلات جاهزة لـ `ApiClient`.
abstract final class Parse {
  /// تجاهل البيانات (عمليات لا يهمنا ردها).
  static void none(Object? _) {}

  static Json json(Object? data) => asJson(data);

  static Parser<T> object<T>(T Function(Json json) fromJson) => (data) => fromJson(asJson(data));

  static Parser<List<T>> list<T>(T Function(Json json) fromJson) => (data) => asList(data, fromJson);

  /// حقل واحد من `data` كموديل: `Parse.field('membership', Membership.fromJson)`.
  static Parser<T> field<T>(String key, T Function(Json json) fromJson) => (data) => fromJson(asJson(data).obj(key));

  static Parser<int> intField(String key) => (data) => asJson(data).intv(key);

  static Parser<String> strField(String key) => (data) => asJson(data).str(key);
}

/// مفتاح منع التكرار: يُولَّد عند ضغط الزر ويُحفظ حتى ينجح الطلب، ونفسه عند إعادة المحاولة.
abstract final class Idempotency {
  static const _uuid = Uuid();

  static String newKey() => _uuid.v4();
}
