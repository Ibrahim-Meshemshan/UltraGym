/// معرّف محلي ثابت لعناصر المحررات (يوم، تمرين، فترة): مفتاح حقولها فتبقى بقيمها عند حذف ما قبلها. لا يُرسل للخادم.
abstract final class DraftIds {
  static int _seq = 0;
  static int next() => ++_seq;
}
