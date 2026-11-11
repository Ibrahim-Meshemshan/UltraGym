/// كل مسارات التطبيق. لا مسار مكتوب نصاً داخل أي شاشة.
abstract final class Routes {
  static const splash = '/';
  static const login = '/login';
  static const changePassword = '/change-password';
  static const offline = '/offline';
  static const blocked = '/blocked';
  static const updateRequired = '/update-required';
  static const home = '/home';

  /// مسار فرعي بمعرّف: `Routes.child(Routes.members, 12)` ← `/members/12`.
  static String child(String base, Object id) => '$base/$id';
}
