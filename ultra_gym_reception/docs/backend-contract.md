# عقد الباك اند (UltraGym API)

المصدر: `docs/reference/UltraGym-Backend-Documentation.pdf` (الفصول 2-4 و 9؛ نص قابل للبحث: `docs/reference/UltraGym-Backend-Documentation.txt`).
Laravel 13 · PHP 8.3 · PostgreSQL 16 · Sanctum · OpenAPI 3. خريطة مسارات هذا المشروع (بالطرق): `docs/api-map.md`. **العقد الدقيق** (الأجسام، الردود، أمثلة كل حالة): ملفات OpenAPI بـ `docs/api/*.yaml` (من مستودع الباك اند، commit `32b0294`، 2026-11-06).
**التوثيق التفاعلي**: `http://127.0.0.1:8000/api/documentation` (Swagger: كل مسار بمعاملاته وردوده الحقيقية لكل رمز حالة).

## العناوين

| البيئة | عنوان الـ API |
|---|---|
| جهاز التطوير (متصفح) | `http://127.0.0.1:8000/api/v1` |
| محاكي Android | `http://10.0.2.2:8000/api/v1` (الخادم بـ `php artisan serve --host=0.0.0.0`) |
| موبايل حقيقي بنفس الشبكة | `http://<IP-جهازك>:8000/api/v1` |
| الإنتاج (لم يُنشر) | `https://api.ultragym.app/api/v1` |

العنوان من `--dart-define=API_BASE_URL=...` فقط (`AppConfig.apiBaseUrl`)، لا يُكتب بالكود.

## القواعد الذهبية للباك اند

1. اعتمد على `code` لا على نص الرسالة.
2. اعرض `message` كما هي (عربية جاهزة؛ أخطاء التحقق في `errors` لكل حقل).
3. **لا تحسب أي حالة أو مبلغ بنفسك**: حالة الاشتراك، الأيام المتبقية، الدين، التنبيهات، الجلسات، `can_freeze`، `freezes_left` كلها تأتي جاهزة.
4. كل قائمة مقسّمة لصفحات (`meta.pagination`). لا تفترض أن الصفحة الأولى كل البيانات.
5. الأوقات `*_at` بتوقيت UTC (حوّلها للعرض بتوقيت النادي `tenant.timezone`، افتراضياً `Asia/Damascus`). التواريخ `*_on` و `business_date` أيام النادي: **لا تحوّلها**.
6. أي عملية مال أو دخول تُرسل مع `Idempotency-Key`.
7. كل شاشة بأربع حالات.
8. الصلاحيات من الخادم: أخفِ ما لا يُسمح به حسب `roles` و `permissions`، والخادم يرفض على أي حال (403).

## الترويسات

| ترسلها | متى | القيمة |
|---|---|---|
| `Accept` | دائماً | `application/json` (بدونها قد يرجع HTML عند الخطأ) |
| `Content-Type` | طلبات بجسم | `application/json` أو `multipart/form-data` للرفع |
| `Authorization` | بعد الدخول | `Bearer <token>` |
| `Idempotency-Key` | كل عملية لا يجوز تكرارها | UUID v4 جديد عند ضغط الزر، ونفسه عند إعادة المحاولة |
| `If-None-Match` | GET تحتفظ بنسخته | قيمة `ETag` السابقة |

| تصلك | معناها | ماذا تفعل |
|---|---|---|
| `X-Server-Time` | وقت الخادم (UTC) بكل رد | احسب فرق ساعة الجهاز واستعمل `serverNow()` (QR، الأوفلاين، وقت العمليات) |
| `X-Session-Expires-At` | انتهاء جلسة التطبيق بعد تجديدها تلقائياً | حدّث المحفوظ |
| `ETag` | بصمة رد GET | أرسلها بـ `If-None-Match`؛ 304 = اعرض المحفوظ |
| `Retry-After` | مع 429 | انتظر هذا العدد من الثواني |
| `Content-Disposition` | مع الملفات | اسم الملف للحفظ |
| `X-Document-Format: html-printable` | الخادم بلا محرك PDF | المحتوى HTML جاهز للطباعة (WebView/iframe) |
| `Idempotent-Replayed: true` | رد محفوظ لطلب سبق تنفيذه | لا شيء: العملية لم تتكرر |

```dart
final serverTime = DateTime.parse(response.headers.value('x-server-time')!);
clockOffset = serverTime.difference(DateTime.now().toUtc());
DateTime serverNow() => DateTime.now().toUtc().add(clockOffset);
```

CORS مضبوط لـ Flutter Web وكل هذه الترويسات مكشوفة. المصادقة بالتوكن لا بالكوكيز.

## شكل الرد

```json
{ "success": true, "message": "…", "data": { } }
{ "success": true, "message": "…", "data": [ ],
  "meta": { "pagination": { "current_page": 1, "per_page": 15, "total": 2, "last_page": 1, "from": 1, "to": 2 },
            "summary": { }, "period": { "is_default": true }, "unread_count": 2 } }
{ "success": false, "message": "البيانات المدخلة غير صالحة", "code": "VALIDATION_ERROR",
  "errors": { "payments.0.amount": ["…"] } }
{ "success": false, "message": "هذه الميزة غير مشمولة بخطة اشتراك النادي", "code": "FEATURE_NOT_AVAILABLE",
  "data": { "feature": "qr_attendance" } }
```

## معاملات القوائم

`page` (من 1)، `per_page` (افتراضي 15، أقصى 100)، `search`، `sort_by` + `sort_dir` (asc/desc، الحقول المسموحة بـ Swagger)، `from` / `to` بصيغة `YYYY-MM-DD` (سجلات الحضور والحركات بلا فترة = آخر 31 يوماً، `meta.period.is_default`).
التمرير اللانهائي: اطلب `page + 1` حتى `current_page == last_page`. القوائم تقبل `branch_id` فلتراً اختيارياً.

## معالجة الأخطاء بمكان واحد

| HTTP | الرمز | ماذا تفعل الواجهة |
|---|---|---|
| 401 | `UNAUTHENTICATED` | امسح التوكن وانتقل للدخول |
| 401 | `INVALID_CREDENTIALS` | الموبايل/المعرّف أو كلمة السر خطأ (بالنموذج) |
| 403 | `PASSWORD_CHANGE_REQUIRED` | افتح تغيير كلمة السر إجبارياً ولا تسمح بغيرها |
| 403 | `TEMPORARY_PASSWORD_EXPIRED` | "اطلب كلمة سر جديدة من النادي" |
| 403 | `ACCOUNT_SUSPENDED` | رسالة وخروج |
| 403 | `NO_ACTIVE_MEMBERSHIP` | لا عضوية فعّالة بأي نادٍ |
| 403 | `APP_NOT_ALLOWED_FOR_ROLE` | الدور لا يخص هذا التطبيق |
| 403 | `TENANT_SUSPENDED` / `SUBSCRIPTION_INACTIVE` / `SUBSCRIPTION_LOCKED` | شاشة حجب تعرض الرسالة |
| 403 | `SUBSCRIPTION_EXPIRED` | قراءة فقط: أوقف أزرار التعديل واعرض شريطاً |
| 403 | `FEATURE_NOT_AVAILABLE` | أخفِ القسم أو "غير متاح بباقتك" (`data.feature`) |
| 403 | `FORBIDDEN` / `BRANCH_FORBIDDEN` | تنبيه قصير (غالباً زر كان يجب إخفاؤه) |
| 403 | `PLAN_LIMIT_REACHED` | حد الباقة (أعضاء، موظفون، فروع) |
| 404 | `NOT_FOUND` | حالة "غير موجود" وارجع للقائمة |
| 405 | `METHOD_NOT_ALLOWED` | خطأ برمجي |
| 409 | `CONFLICT` وباقي رموز الأعمال | اعرض `message`؛ بعضها له فعل خاص (أدناه) |
| 422 | `VALIDATION_ERROR` وغيره | `errors` تحت كل حقل و `message` أعلى النموذج |
| 429 | `TOO_MANY_REQUESTS` | انتظر `Retry-After` ثم أعد (بالدخول اعرض المدة) |
| 503 | `MAINTENANCE` | شاشة صيانة مع إعادة محاولة كل دقيقة |
| 500 | `SERVER_ERROR` | رسالة عامة وزر إعادة المحاولة |

رموز الأعمال (409 ما لم يُذكر): `CASH_SESSION_REQUIRED` (اعرض زر "فتح الصندوق" بنفس الرسالة)، `CASH_SESSION_ALREADY_OPEN`، `EXCHANGE_RATE_MISSING` (المالك يحدده من الإعدادات المالية)، `COUPON_INVALID` (422، السبب بالرسالة)، `PLAN_INACTIVE`، `NOTHING_DUE`، `MEMBERSHIP_CANCELLED` / `MEMBERSHIP_NOT_ACTIVE` / `MEMBERSHIP_NOT_FROZEN`، `FREEZE_LIMIT_REACHED`، `NOT_SESSIONS_MEMBERSHIP` / `NO_SESSIONS_LEFT`، `SALARY_ALREADY_PAID` / `ALREADY_REVERSED`، `DEVICE_NOT_REGISTERED` / `DEVICE_REVOKED`، `BRANCH_INACTIVE`. الدخول اليومي: `DAY_PASS_DISABLED` (409)، `DAY_PASS_PRICE_MISSING` (422: يحدده المالك من الإعدادات)، `HAS_ACTIVE_MEMBERSHIP` (409: سجّل دخوله العادي)، `DAY_PASS_EXISTS` (409)، `ALREADY_CANCELLED` (409).
الدخول للنادي: `ALREADY_CHECKED_IN` (200، ليس خطأ: يرجع السجل السابق)، أسباب الرفض (409): `UPCOMING · FROZEN · EXPIRED · NO_MEMBERSHIP · SUSPENDED · BRANCH_NOT_ALLOWED · NO_SESSIONS · GENDER_UNKNOWN · GENDER_HOURS`، رمز QR (422): `QR_MALFORMED · QR_EXPIRED · QR_INVALID · QR_UNKNOWN_KEY`.
منع التكرار: `IDEMPOTENCY_KEY_REUSED` (422: نفس المفتاح بجسم مختلف)، `IDEMPOTENCY_IN_PROGRESS` (409: انتظر ثانيتين وأعد).

## منع التكرار (Idempotency-Key)

أرسله مع: البيع والتجديد، الدفعات، الاسترجاع، الحركات المالية، فتح وإغلاق الصندوق، الرواتب والسلف، تسجيل دخول الأعضاء، وأي POST يُنشئ شيئاً.
ولّد UUID عند ضغط الزر واحفظه حتى ينجح الطلب. انقطع الاتصال؟ أعد بنفس المفتاح.

## الملفات (PDF / Excel) والرفع

- مسارات الملفات (الفواتير، الإيصالات، تقارير الصندوق، بطاقات الدخول، التقارير بـ `format=pdf|xlsx`) تتطلب التوكن: لا تفتحها برابط مباشر؛ نزّل البايتات ثم احفظها أو اعرضها (`BlobOpener`).
- **Flutter Web**: أضف `?as=base64` لأي مسار ملف ← `{ filename, content_type, base64 }`.
- تصديرات لوحة المنصة الكبيرة غير متزامنة: `POST …/exports` ثم `GET …/exports/{id}` حتى `status = completed` وافتح `download_url` (رابط موقّع مؤقت بلا توكن).
- الرفع `multipart/form-data`: صور `png, jpg, jpeg, webp` (`club-admin/club/logo` 2MB، `club-admin/players/{id}/photo` 3MB، `player/profile/photo` 3MB، `super-admin/tenants/{id}/logo`، ومرفقات الدعم حسب Swagger).
- روابط الصور الخاصة `photo_url` مؤقتة (30 دقيقة): اعرضها مباشرة ولا تخزّن الرابط.

## حدود الطلبات

120 طلباً/دقيقة لكل مستخدم (فريق المنصة 300)، 60/دقيقة بلا توكن لكل IP، 1500/دقيقة لكل نادٍ، الدخول: 5 محاولات خاطئة للرقم = قفل 15 دقيقة، والثقيلة: التقارير 30/دقيقة، حزمة الأوفلاين 30، المزامنة 60، الفواتير والإيصالات 20.
**لا polling.** حدّث عند فتح الشاشة، وبالسحب للتحديث، وبعد الإشعارات. الاستثناء الوحيد: `unread-count` كل 60 ثانية بينما الواجهة ظاهرة.

## الدخول والجلسة (المشترك)

| الواجهة | المسار | الجسم |
|---|---|---|
| لوحة المنصة | `POST /super-admin/auth/login` | `{ phone, password, device_name? }` |
| لوحة النادي | `POST /auth/login` | `{ phone, password, tenant_id?, device_name? }` |
| شاشة الاستقبال | `POST /auth/login` | `{ phone, password, tenant_id?, device_name, app: "reception_web" }` |
| تطبيق العضو | `POST /auth/login` | `{ phone, password, tenant_id?, device_name, app: "player_app" }` |

- `phone` يقبل الموبايل بأي صيغة (`0944123456`، `+963944123456`) أو معرّف العضو (`DMO-482913`). اكتب على الحقل: "الموبايل أو معرّف العضو".
- `device_name` لقائمة "جلساتي" (مثلاً `Samsung A54` أو `الاستقبال 1 · Chrome`).
- **اختيار النادي**: حساب بأكثر من نادٍ دون `tenant_id` يرجع `requires_tenant_selection: true` و `tenants: [{ tenant: {id, name, slug, logo_url}, roles }]`. اعرضها ثم أعد نفس الطلب مع `tenant_id`.
- **رد الدخول**: `token`، `token_type`، `expires_at` (UTC)، `must_change_password` (true ← تغيير كلمة السر قبل أي شيء)، `user`، `member_code`، `tenant` (الاسم والشعار للرأس)، `roles` (`player` / `receptionist` / `club_owner`)، `permissions` (`can_view_finance`، `can_manage_staff`)، `other_tenants_count` (> 0 ← "تبديل النادي").
- **كلمة السر المؤقتة** (7 أيام): ما دام `must_change_password` كل الطلبات ترجع `403 PASSWORD_CHANGE_REQUIRED` إلا `POST /auth/change-password` (`{ current_password, new_password, new_password_confirmation }`، 8 أحرف على الأقل؛ نفس التوكن يبقى صالحاً)، `POST /auth/logout`، `GET /auth/me`.
- **استعادة الجلسة**: `GET /auth/me` (المستخدم، النادي، الأدوار، الصلاحيات، `is_impersonated`، `session.expires_at`). 401 ← الدخول.
- **الخروج**: `POST /auth/logout` مع `{ fcm_token }` إن كان مسجلاً، ثم امسح التوكن والكاش محلياً.
- **الجلسات**: `POST /profile/revoke-all-tokens` (كل المستخدمين).

## الإشعارات (الجرس)

المسارات نفسها بلوحة النادي والاستقبال وتطبيق العضو:
`GET /notifications?unread_only=1&type=a,b&page=` (الأحدث أولاً، `meta.unread_count`)، `GET /notifications/unread-count`، `POST /notifications/{id}/read`، `POST /notifications/read-all`، `DELETE /notifications/{id}`، `DELETE /notifications`، `GET /notifications/preferences`، `PUT /notifications/preferences { muted: [...] }`.

- اعرض `title` و `body` كما هما، والوقت نسبياً ("قبل 5 دقائق") من `created_at`.
- الضغط: علّمه مقروءاً ثم افتح الشاشة حسب `screen` والمعرّفات في `data`. `screen = none` لا يفتح شيئاً.
- اطلب `unread-count` عند فتح التطبيق، عند عودته من الخلفية، بعد أي عملية، وكل 60 ثانية فقط بينما الواجهة ظاهرة.
- الإشعارات خاصة بالنادي الحالي، ومنفّذ العملية لا يُشعَر بما فعله.
- لاحقاً مع Firebase يصل نفس الإشعار push بنفس `data` دون تغيير بالواجهة غير معالجة الضغط.

## تمثيل البيانات

| النوع | الصيغة | العرض |
|---|---|---|
| المعرّفات | أعداد صحيحة (`id`)، عدا `key_id` و `client_uuid` نصية | — |
| `*_at` | ISO 8601 UTC `2026-11-04T12:30:00Z` | حوّل لتوقيت النادي |
| `*_on`، `business_date` | `YYYY-MM-DD` بتوقيت النادي | كما هي |
| `*_usd` | رقم بخانتين | `$25.00` (LTR) |
| `*_syp` | رقم صحيح بسعر صرف اليوم | `325,000 ل.س` |
| `currency` | `USD` أو `SYP` | الدولار بخانتين، الليرة بلا كسور |
| الموبايل | يرجع موحّداً `+963944123456` | LTR، ويُرسل بأي صيغة |
| `member_code` | `PREFIX-123456` | LTR، قابل للنسخ والمسح كباركود |
| القيم الفارغة | `null` (المفاتيح لا تُحذف) | "—" أو أخفِ السطر |

- العملة الأساسية الدولار، والليرة بسعر صرف النادي: اعرض الدولار أولاً والليرة تحته.
- يوم العمل ينتهي 2 فجراً: اعرض `business_date` للتجميع لا تاريخ `occurred_at`.
- **لا حذف للمال**: زر "عكس" (للمالك) مع سبب إلزامي، والحركة تبقى ظاهرة مشطوبة.

### ربط القيم بشارات الهوية (`UTone`)

| القيمة | الشارة |
|---|---|
| اشتراك `active` فعّال | `success` |
| `grace` بفترة السماح | `warning` |
| `frozen` مجمّد (حتى `frozen_until`) | `info` |
| `upcoming` لم يبدأ (`starts_on`) | `info` |
| `expired` منتهٍ | `danger` |
| `cancelled` ملغى | `neutral` |
| تنبيهات تطبيق العضو `level` | `info / warning / danger` |
| الدخول | `accepted` ← `success`، `rejected` ← `danger`، و `in_grace` ← `warning` |
| الحركة | `in` ← `success`، `out` ← `danger`، `is_reversed` ← `neutral` مع شطب |
| الصندوق | `open` ← `accent` (فولت = مباشر)، الفرق السالب `danger` والموجب `warning` |
| اشتراك النادي بالمنصة | `trial` accent · `active` success · `grace` warning · `expired` warning (قراءة فقط) · `locked` danger · `suspended` danger · `cancelled` neutral |
| الفواتير | `pending` info · `partially_paid` warning · `paid` success · `cancelled` / `refunded` neutral · المتأخرة (غير مدفوعة بعد `due_date`) danger |
| الدور `club_owner` | `primary` |
| جديد، سلسلة حضور، تجريبي | `accent` |

الخادم يرجع `status` (محسوبة اليوم) و `status_label` (النص العربي): اعرض `status_label` واربط اللون بـ `status` عبر `Labels`.

## ما ليس موجوداً بالباك اند (لا تبنه)

| بالهوية / الـ UI | الوضع | ماذا تفعل |
|---|---|---|
| دور "مدير الفرع" ولوحة المدير | غير موجود (الأدوار: مالك، استقبال، عضو) | لا تبنه، المالك يرى كل الفروع |
| تطبيق المدرّب | المدربون سجلات بلا حساب دخول | لا تبنه |
| حجز الحصص وجدولها | غير موجود | أخفِ "حجز حصة"، ضع "برنامجي" مكانه |
| الدفع الإلكتروني من التطبيق | غير موجود | "جدّد من استقبال النادي" |
| تسجيل العضو لنفسه | غير موجود (النادي ينشئ الحسابات) | لا شاشة "إنشاء حساب"، فقط دخول |
| نسيت كلمة السر | غير موجود ذاتياً | "اطلب كلمة سر جديدة من استقبال النادي" |
| العضو يضيف قياساته | القياسات يسجلها النادي | عرض فقط |

## الحسابات التجريبية

`php artisan db:seed --class=DemoClubSeeder` (جهاز التطوير فقط). كلمة السر لكل الحسابات `Demo@2026` (أو `DEMO_PASSWORD`).

| الدخول (phone) | الحساب | app |
|---|---|---|
| `0933100001` | مالك النادي (فرعان، صندوقان مفتوحان، تقارير بأسابيع بيانات) | — |
| `0933100002` | موظف استقبال (الفرع الرئيسي فقط، بلا المالية والرواتب) | `reception_web` أو — |
| `0944100001` | عضو فعّال عليه دين 20$، تدريب خاص، قياسات وبرنامج، سلسلة حضور | `player_app` |
| `0944100002` | عضوة بفرع أوقات منفصلة (قسم الإناث صباحاً، تنبيه "ليس وقت قسمك" بعد الظهر) | `player_app` |
| `0944100003` | عضو مجمّد (اشتراك 3 أشهر بكوبون، مجمّد 10 أيام) | `player_app` |
| `0944100004` | عضو بأيام السماح (انتهى قبل يوم ويُسمح له بالدخول) | `player_app` |
| `0944100005` | عضو منتهٍ (ومحاولة دخول مرفوضة بسجله) | `player_app` |
| `0944100006` | عضو اشتراك 12 جلسة يُستهلك + تجديد مسبق (`next_membership`) | `player_app` |

حساب لوحة المنصة: يُنشأ بـ `php artisan migrate --seed` من `SUPER_ADMIN_OWNER_PHONE` (افتراضياً `+963911000001`) و `SUPER_ADMIN_OWNER_PASSWORD`: اطلب كلمة السر من صاحب المشروع.
