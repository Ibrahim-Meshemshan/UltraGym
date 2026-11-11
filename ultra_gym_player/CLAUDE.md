# CLAUDE.md · ultra_gym_player (تطبيق العضو)

> **اقرأ هذا الملف كاملاً، والملفين المستوردين أدناه، قبل أي تعديل أو إضافة على المشروع.**
> أي قاعدة هنا تغلب أي Skill أو عادة عامة. إن تعارض طلب مع قاعدة: نبّه صاحب المشروع قبل التنفيذ.

@docs/engineering-rules.md
@docs/backend-contract.md

## ما هو المشروع

- **تطبيق عضو النادي** (`role = player`): **Android / iOS** (والويب للمعاينة المحلية فقط).
- يكلّم مسارات `/player/*` (30 مساراً) + المسارات المشتركة (`/auth/*`، `/notifications/*`، `/profile`، `/devices`، `/app-version`). الخريطة (بالطرق): `docs/api-map.md`، والعقد الدقيق: `docs/api/*.yaml`.
- العضو يرى نفسه فقط بناديه الحالي. يحتاج ميزة الباقة `player_app`، ومفاتيح QR ميزة `qr_attendance`.
- قالب الشاشات (هوية §10): **رأس فحمي** بنقش وقرص وتحية Changa (زواياه السفلية 28) هو المكان المزخرف الوحيد، **إجراءات سريعة** 3 بطاقات مشطوفة (الأولى ممتلئة بالبرتقالي)، **بطاقات محتوى** مشطوفة نظيفة، **شريط تنقل سفلي** 68 بأربعة عناصر. نص الموبايل الأساسي `UType.bodyLg`.
- اللمس: `PressScale` على كل ما يُضغط، `HapticFeedback.selectionClick()` للأفعال المهمة وتبديل التبويب، أهداف ≥ 48px، اتجاه عمودي فقط.

## التشغيل والبناء

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
flutter run --dart-define=API_BASE_URL=http://<IP-جهازك>:8000/api/v1
flutter build apk --release --dart-define=API_BASE_URL=https://api.ultragym.app/api/v1
flutter build web --debug --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
flutter analyze
```

الخادم المحلي للمحاكي/الهاتف: `php artisan serve --host=0.0.0.0`. الـ debug manifest يسمح بـ http (cleartext) للتطوير فقط.
الأيقونة وشاشة البدء مولدتان من الهوية؛ لإعادة التوليد: `dart run flutter_launcher_icons` و `dart run flutter_native_splash:create`.

## الدخول والجلسة

- `POST /auth/login` بـ `{ phone, password, tenant_id?, device_name, app: "player_app" }` (`AppConfig.loginApp`) ← جلسة **90 يوماً تتجدد** مع الاستعمال.
- `phone` = "الموبايل أو معرّف العضو". `device_name` اسم الهاتف (مثلاً `Samsung A54`).
- التوكن بـ `flutter_secure_storage` (Keychain/Keystore) ويُقرأ قبل `runApp`.
- `APP_NOT_ALLOWED_FOR_ROLE` (مالك يدخل تطبيق العضو) و `NO_ACTIVE_MEMBERSHIP`: رسالة الخادم كما هي.
- **لا "إنشاء حساب" ولا "نسيت كلمة السر"**: "اطلب كلمة سر جديدة من استقبال النادي".
- **تعدد النوادي**: `GET /player/clubs` ثم `POST /player/clubs/switch { tenant_id }` يرجع توكناً جديداً ويلغي القديم: استبدله فوراً وأعد تحميل كل الشاشات (وامسح الكاش).
- **تسجيل الجهاز**: `POST /devices { app: "player_app", platform: "android"|"ios", app_version, fcm_token? }` بعد الدخول وعند كل فتح للتطبيق.
- **التحديث الإجباري**: `GET /app-version?app=player_app&platform=android&version=1.0.0` (بلا توكن) ← `force_update = true`: شاشة تمنع الاستعمال وزر المتجر (`store_url`)؛ `update_available` فقط: تنبيه يمكن تجاهله.

## الشاشات والنموذج الأولي

النموذج الأولي المعتمد بـ `docs/ui-prototype/` (افتح `index.html`). **ابنِ كل شاشة مطابقة لصفحتها**.

| الشاشة | الشريط السفلي | المسارات | صفحة النموذج |
|---|---|---|---|
| الدخول، اختيار النادي، تحديث إجباري | — | `/auth/*`، `/app-version` | `MemberLogin.html` |
| الرئيسية | الرئيسية | `GET player/home` (طلب واحد) | `MemberHome.html` |
| بطاقتي: QR متجدد + المعرّف كباركود احتياطي + حالة الاشتراك | بطاقتي | `GET player/card`، `player/qr-keys` | `MemberCard.html` |
| اشتراكاتي: الحالي بالتفاصيل، القادم، السابقة، الدفعات والإيصالات، الفاتورة | اشتراكاتي | `GET player/memberships?status=`، `…/current`، `…/{id}`، `…/{id}/invoice`، `GET player/payments`، `player/payments/{id}/receipt` | `MemberMemberships.html` |
| حسابي: الملف والصورة، نواديّ، الإشعارات، تغيير كلمة السر، الخروج | حسابي | `player/profile` (+ `/photo`)، `player/clubs`، `/auth/change-password`، `/auth/logout` | `MemberAccount.html` |
| التجديد (الخطط بالسعرين و `renewal_starts_on`) | من الرئيسية | `GET player/plans?type=&branch_id=`، `player/plans/{id}` | `MemberPlans.html` |
| حضوري وإحصائياته (أشهر، أيام أسبوع النادي، ساعات) | من الرئيسية | `GET player/attendance`، `…/stats?months=6` | `MemberAttendance.html` |
| تقدّمي: القياسات و `changes` (سالب = نقص) و `series` للرسم | من الرئيسية | `GET player/measurements`، `…/progress` | `MemberProgress.html` |
| برامجي: برامج النادي (قراءة فقط) وبرامجي الخاصة (إنشاء، تعديل، حذف، ونسخ برنامج النادي لأعدّل عليه) | من الرئيسية | `GET player/workout-plans`، `…/{id}`، `POST player/workout-plans`، `PATCH/DELETE …/{id}`، `POST …/{id}/copy` | `MemberWorkout.html` |
| الإعلانات (الفتح يعلّمه مقروءاً، `meta.unread_count`) | من الرئيسية | `GET player/announcements?unread=1`، `…/{id}`، `POST …/read-all` | `MemberHome.html` |
| الإشعارات (الجرس بالرأس + كتم الأنواع) | الرأس | `/notifications/*` | `MemberNotifications.html` |
| النادي: الفروع وتواصلها، `my_hours` لكل فرع، قواعد السماح | من حسابي | `GET player/club` | `MemberAccount.html` |
| أجهزتي المسجلة للرمز | من حسابي | `player/qr-keys` | `MemberDevices.html` |

`MobileShell`: أربعة تبويبات كل منها يحفظ حالته، وشريط سفلي عائم (`FancyTabBar`) بزر أوسط يفتح إجراءات سريعة (`QuickActions`)، وشارات أعداد (`NavBadgesCubit`). الرجوع من تبويب غير الرئيسية يعود للرئيسية. `AppPage` + `MobileHeader` هيكل أي شاشة، مع السحب للتحديث. القوائم `LoadMoreList` فوق `ListCubit`، و `ActionSheet` لإجراءات العنصر.

## برامجي التدريبية (منذ 2026-11-06)

- برامج النادي (`source` = club) قراءة فقط؛ لتعديل أحدها: `POST player/workout-plans/{id}/copy` ثم عدّل النسخة.
- برامج العضو (`source = player`): أقصى 30 برنامجاً. الجسم: `{ title (≤150), description?, starts_on?, ends_on?, status? (active|archived), days: [{ day (1-14 بلا تكرار), title, exercises: [{ name, sets?, reps?, weight_kg?, duration_seconds?, rest_seconds?, notes? }] (1-40) }] (1-14) }`.
- التعديل والإنشاء بـ `FormDialog` أو شاشة نموذج كاملة فوق `AppFormCubit` بأسماء منقّطة (`days.0.exercises.2.name`) فتتوزع أخطاء 422 على الحقول تلقائياً.
- التفاصيل والأمثلة: `docs/api/player-app-api.yaml`.

## الرئيسية بقالب الهوية (`GET player/home`)

| الحقل | الاستعمال |
|---|---|
| `player.name` | تحية Changa حسب الوقت: "صباح الخير، أحمد" |
| `membership.days_remaining` | "باقي 21 يوم باشتراكك" (أو `sessions_remaining` لاشتراك الجلسات) |
| `attendance.streak_weeks` | "سلسلة حضورك: 3 أسابيع" بشارة فولت (0 = أخفها) |
| `alerts[]` | بطاقات تنبيه بترتيبها، اللون حسب `level`، والنص `message` كما هو |
| `access` | فرع بأوقات منفصلة: "أوقات قسمك" من `my_hours`، و `open_for_me_now` / `reason` |
| `qr.enabled` / `qr.active_keys` | إن كان `active_keys = 0`: سجّل مفتاح الجهاز تلقائياً |
| `unread_announcements` | عدّاد الإعلانات (فولت) |
| `due_usd` / `due_syp` | الدين (الدولار أولاً والليرة تحته) |
| `latest_measurement`، `active_workout_plan`، `next_membership` | بطاقات المحتوى |

**الإجراءات السريعة**: "دخول بالـ QR" (يفتح بطاقتي) · "برنامجي" (بدل "حجز حصة" غير الموجود بالباك اند) · "تجديد" (يعرض الخطط، والدفع من الاستقبال: "جدّد من استقبال النادي" مع الخطة المختارة؛ لا دفع إلكتروني).

## رمز الدخول QR (يعمل دون إنترنت)

التوقيع على الهاتف (Ed25519)، والتحقق على جهاز الاستقبال بالمفتاح العام، لذلك الدخول أوفلاين يعمل.

```dart
import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final _ed = Ed25519();
const _store = FlutterSecureStorage();

/// مرة واحدة لكل جهاز (أو إن رجع qr.active_keys = 0 أو QR_UNKNOWN_KEY).
Future<void> ensureQrKey(Dio api, String deviceName) async {
  if (await _store.read(key: 'qr_key_id') != null) return;
  final pair = await _ed.newKeyPair();
  final pub = await pair.extractPublicKey();
  final seed = await pair.extractPrivateKeyBytes(); // 32 بايت، لا يغادر الجهاز أبداً
  final res = await api.post('/player/qr-keys', data: {'public_key': base64.encode(pub.bytes), 'device_name': deviceName});
  await _store.write(key: 'qr_seed', value: base64.encode(seed));
  await _store.write(key: 'qr_key_id', value: res.data['data']['key']['key_id']);
}

/// يُستدعى كل 10 ثوانٍ لتحديث الرمز المعروض (صالح 30 ثانية).
Future<String> currentQr(DateTime serverNowUtc) async {
  final keyId = (await _store.read(key: 'qr_key_id'))!;
  final pair = await _ed.newKeyPairFromSeed(base64.decode((await _store.read(key: 'qr_seed'))!));
  final ts = serverNowUtc.millisecondsSinceEpoch ~/ 1000;
  final msg = 'UG1.$keyId.$ts';
  final sig = await _ed.sign(utf8.encode(msg), keyPair: pair);
  return '$msg.${base64Url.encode(sig.bytes).replaceAll('=', '')}';
}
```

- في الكود الفعلي: الطلب عبر `ApiClient` (لا Dio مباشرة بالميزة)، والتحديث كل 10 ثوانٍ بـ Cubit (`Timer` داخل Cubit يُلغى بـ `close`)، لا `setState`.
- اعرض الرمز بـ `qr_flutter`، وارفع سطوع الشاشة أثناء العرض بـ `screen_brightness` (وأرجعه عند الخروج)، والمعرّف `member_code` LTR تحته كباركود احتياطي.
- استعمل `serverNow()` دائماً (فرق `X-Server-Time`): ساعات الهواتف الخاطئة شائعة. للتجربة: `POST player/qr/verify { qr_token }` يرجع `valid` والسبب و `clock_drift_seconds`.
- المفتاح لحساب العضو فيعمل بكل نواديه؛ نفس اسم الجهاز يستبدل مفتاحه؛ أقصى 3 أجهزة.

## الإشعارات للعضو ← الشاشة

`membership_started`، `membership_frozen`، `membership_unfrozen`، `membership_cancelled`، `membership_reminder` (`subtype: expires_in_3 | expires_in_1 | expired`)، `session_used`، `session_restored` ← تفاصيل اشتراكي `player/memberships/{membership_id}`؛ `payment_received`، `payment_reversed` ← دفعاتي (مع إيصال `transaction_id` إن وُجد)؛ `measurement_added` ← تقدّمي؛ `workout_plan_assigned` ← البرنامج `workout_plan_id`؛ `club_announcement` ← الإعلان `announcement_id`.
إن كان `data.tenant_id` بإشعار push مختلفاً عن النادي الحالي: اعرض "الإشعار من نادٍ آخر" مع زر التبديل.
**Firebase لاحقاً**: `firebase_core` + `firebase_messaging` + `flutter_local_notifications` (+ `push_permission` و `app_settings` لتنبيه "الإشعارات مطفية"). دورة التوكن: إذن ← تسجيله بالخادم عند الدخول وعودة الاتصال وتجدده ← حذفه عند الخروج. `onOpen` يفتح صفحة الإشعارات بعد انتهاء البدء، و `onMessage` يحدّث العدّاد. حتى ذلك الحين الجرس يعمل من الخادم بـ `unread-count`.

## العمل دون اتصال

الكاش على مستوى HTTP (`OfflineCacheInterceptor` + `CacheStore io`) كما في engineering-rules §8: كل شاشة تعرض آخر نسخة دون اتصال تلقائياً مع "آخر تحديث قبل…"، والكتابة ترفض فوراً برسالة واضحة، و `OfflineBanner` فوق كل الشاشات. بطاقة الـ QR تعمل كاملاً دون إنترنت.

## الملفات

الفاتورة والإيصال PDF: `BlobOpener` يجلب الملف بالتوكن، يحفظه (`path_provider`) ويفتحه (`open_filex`). إن رجع `X-Document-Format: html-printable` اعرضه بـ `webview_flutter`. رفع الصورة بـ `file_picker` و `FormData` (3MB، `png, jpg, jpeg, webp`). `photo_url` مؤقت 30 دقيقة: لا تخزّن الرابط.

## الباكجات بهذا المشروع

القائمة المعتمدة (engineering-rules §13) للموبايل، + `cryptography` (Ed25519 للـ QR)، `qr_flutter`، `screen_brightness`. `app_settings` مثبّت على `^6.1.1` (9.x تتطلب Swift Package Manager).

## الأصول والمنصة

- `packages/ultragym_design`: حزمة الهوية (path dependency). **لا تعدّلها**.
- `assets/brand/` (الشعار + مصادر الأيقونة وشاشة البدء)، `assets/icons/`، `assets/ornaments/`.
- معرّف التطبيق الحالي `com.example.ultra_gym_player`: يجب تغييره (مثلاً `app.ultragym.member`) قبل ربط Firebase أو النشر.
- إعدادات Android المطلوبة من الإضافات (لا ترجعها لقيم القالب): AGP `8.9.1` (`android/settings.gradle.kts`)، و `compileSdk = 36`، `ndkVersion = "27.0.12077973"`، `minSdk = 23` (`android/app/build.gradle.kts`). `flutter build apk --debug` يعمل بها.

## حالة البناء

- **مبني ومختبر**: core (engineering-rules §16)، والدخول والجلسة والراوتر (§17): الدخول، اختيار النادي، تغيير كلمة السر الإجباري، استعادة الجلسة، الخروج، شاشات لا اتصال / حجب.
- يرسل `app: player_app` بالدخول، يسجّل الجهاز بعد الدخول وعند كل فتح، ويفحص `/app-version` عند التشغيل: `force_update` ← شاشة "تحديث مطلوب"، و `update_available` ← تنبيه قصير. تبديل النادي (`/player/clubs/switch`) لم يُبنَ بعد.
- **التالي**: الهيكل (Shell) ثم الشاشات حسب جدول الشاشات أعلاه. `features/home` مؤقتة وتُستبدل بالرئيسية الحقيقية.

## الـ Skills المتاحة (`.claude/skills/`)

`ultragym-feature` (**استعمله لكل ميزة**)، `bloc`، `testing`، `accessibility`، `animations`، `flutter-build-responsive-layout`، `flutter-fix-layout-issues`، `flutter-add-widget-test`، `flutter-add-integration-test`، `flutter-setup-declarative-routing`، `dart-run-static-analysis`، `dart-resolve-package-conflicts`، `dart-use-pattern-matching`.
**الأولوية**: هذا الملف ← `docs/engineering-rules.md` ← `docs/backend-contract.md` ← الـ Skills.

## قبل أن تنهي أي مهمة

1. `flutter analyze` نظيف.
2. لا `setState`، لا ملف فوق 300 سطر، لا لون/نمط/مسافة/مدة/مسار مكتوب.
3. الحالات الأربع، الثيم الداكن، RTL، والأرقام LTR، وشاشة 360px بلا overflow مع تكبير خط النظام.
4. جرّب بحسابات النادي التجريبي: فعّال عليه دين، أوقات منفصلة، مجمّد، سماح، منتهٍ، جلسات + تجديد قادم.
