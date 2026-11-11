/// إعدادات التطبيق الثابتة: رابط الخادم، اسم التطبيق بطلب الدخول، المهلات، وحدود تكبير الخط.
/// الرابط يتغير وقت البناء دون تعديل الكود:
/// `flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1`
abstract final class AppConfig {
  /// رابط الـ API (نسبي له كل المسارات).
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:8000/api/v1');

  /// عنوان التطبيق (تبويب المتصفح / مبدّل التطبيقات).
  static const appTitle = 'UltraGym · العضو';

  /// قيمة `app` بطلب الدخول `POST /auth/login` (فارغة = لا تُرسل).
  static const loginApp = 'player_app';

  /// قيمة `app` لتسجيل الجهاز وفحص النسخة (`/devices` و `/app-version`).
  static const platformApp = 'player_app';

  /// الويب: التوكن بـ localStorage (true، جلسة طويلة) أو sessionStorage (false، تنتهي بإغلاق التبويب).
  static const persistentWebSession = true;

  /// مسارات الدخول والجلسة لهذه الواجهة.
  static const authBase = '/auth';

  /// نسخة التطبيق المرسلة لـ `/devices` و `/app-version` (حدّثها مع `version` بـ pubspec أو بـ `--dart-define=APP_VERSION`).
  static const appVersion = String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0');

  /// توقيت النادي الافتراضي للعرض (الخادم يرجع `tenant.timezone`).
  static const defaultTimezone = 'Asia/Damascus';

  static const connectTimeout = Duration(seconds: 15);
  static const receiveTimeout = Duration(seconds: 30);

  /// مهلة الاتصال حين توجد نسخة محفوظة بالكاش (منهجية §9).
  static const cachedConnectTimeout = Duration(seconds: 8);

  /// حدود تكبير خط النظام حتى لا يحدث overflow بأي مقاس.
  static const minTextScale = 1.0;
  static const maxTextScale = 1.3;
}
