# CLAUDE.md · ultra_gym_super_admin (لوحة المنصة)

> **اقرأ هذا الملف كاملاً، والملفين المستوردين أدناه، قبل أي تعديل أو إضافة على المشروع.**
> أي قاعدة هنا تغلب أي Skill أو عادة عامة. إن تعارض طلب مع قاعدة: نبّه صاحب المشروع قبل التنفيذ.

@docs/engineering-rules.md
@docs/backend-contract.md

## ما هو المشروع

- **لوحة فريق UltraGym** (صاحب المنصة) لإدارة كل النوادي. **Flutter Web فقط**.
- يكلّم مسارات `/super-admin/*` فقط (148 مساراً). الخريطة (بالطرق): `docs/api-map.md`، والعقد الدقيق: `docs/api/*.yaml`. **لا يستعمل** `/auth/*` ولا `/club-admin/*` ولا `/notifications` المشتركة (له جرسه الخاص تحت `/super-admin`).
- الحساب من جدول منفصل عن مستخدمي النوادي، بدورين: `owner` (مالك المنصة) و `admin` (مشرف). 13 مساراً لمالك المنصة فقط (إدارة الفريق، الحذف النهائي، الإعدادات الحساسة): المشرف يحصل على 403. **الدور من `me.role`: أخفِ أقسام المالك عن المشرف.**
- قالب الشاشات: `AppShell` = `UGSidebar` + `UGTopBar` + محتوى بأقصى عرض 1320 وهوامش 24 (≥1024 مفتوحة 264، 600-1024 مطوية 76، <600 درج). الجداول `PagedTable`، والتعديلات `FormDialog`.

## التشغيل والبناء

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
flutter build web --release --dart-define=API_BASE_URL=https://api.ultragym.app/api/v1
flutter analyze
```

## الدخول والجلسة

- `POST /super-admin/auth/login` بـ `{ phone, password, device_name? }`، `GET /super-admin/auth/me`، `POST /super-admin/auth/logout`، `POST /super-admin/auth/change-password`، والجلسات تحت `/super-admin/auth/sessions`.
- نفس قواعد القفل (5 محاولات = 15 دقيقة) والتوكن وتغيير كلمة السر الإجباري. مدة الجلسة حسب إعداد المنصة.
- التوكن بـ `shared_preferences` (الويب). لا اختيار نادٍ.
- حساب التطوير: `SUPER_ADMIN_OWNER_PHONE` (افتراضياً `+963911000001`)؛ كلمة السر من صاحب المشروع.

## الأقسام والشاشات والنموذج الأولي

النموذج الأولي المعتمد بـ `docs/ui-prototype/` (افتح `index.html`؛ كل صفحة لها `#dark`). **ابنِ كل شاشة مطابقة لصفحتها**.

| القسم (Swagger) | المسارات | الغرض | صفحة النموذج |
|---|---|---|---|
| Auth | 9 | الدخول، الملف، كلمة السر، الموبايل، الجلسات | `Login.html` |
| Analytics | 12 | نظرة عامة، نمو، إيرادات، استخدام الحدود، نشاط، تصدير غير متزامن | `POverview.html`، `PAnalytics.html` |
| Tenants | 19 | النوادي: إنشاء (مع المالك والفرع والتجربة)، تعديل، إيقاف، أرشفة، شعار، إعدادات، استثناءات الحدود، نسخة | `SuperTenants.html`، `PNewTenant.html`، `SuperTenantDetail.html` |
| Subscriptions | 14 | اشتراكات النوادي: تجديد، تغيير باقة، إيقاف، سجل | `PSubscriptions.html` |
| Finance | 14 | الفواتير والدفعات وكشف الحساب و PDF | `PInvoices.html` |
| Plans | 9 | الباقات وأسعارها وحدودها وميزاتها | `PPlans.html` |
| Users | 10 | مستخدمو النوادي عبر كل المنصة | `PUsers.html` |
| Impersonation | 3 | الدخول كمستخدم للدعم | `PUsers.html` |
| Support Tickets | 7 | تذاكر الدعم والردود | `PSupport.html` |
| Announcements | 11 | إعلانات المنصة للنوادي مع الاستهداف والجدولة | `PAnnouncements.html` |
| App Versions | 7 | نسخ التطبيقات والتحديث الإجباري | `PAppVersions.html` |
| Message Templates | 3 | قوالب رسائل واتساب | `PTemplates.html` |
| Audit Log | 5 | سجل التدقيق | `PAudit.html` |
| Admins (للمالك) | 12 | فريق المنصة | `PTeam.html` |
| System | 12 | صحة النظام، الصيانة، النسخ الاحتياطي | `PSystem.html` |
| Settings | 3 | إعدادات المنصة بالأقسام | `PSettings.html` |
| Search | 1 | بحث موحّد بالنوادي والمستخدمين والفواتير | `UGTopBar` / `SearchPill` |
| Notifications | 5 | جرس الفريق | `SystemStates.html` |

## التدفقات التي تحتاج انتباهاً

- **إنشاء نادٍ** `POST /super-admin/tenants`: ينشئ النادي ومالكه (بكلمة سر مؤقتة تظهر **مرة واحدة** مع رسالة واتساب) وفرعه الرئيسي واشتراكاً تجريبياً. اعرض كلمة السر ورسالة واتساب بنافذة واحدة (`CredentialsDialog`) مع زر نسخ.
- **فحص المعرّف المختصر** `GET /super-admin/tenants/check-slug` أثناء الكتابة بـ `Debouncer` (400ms من `AppConfig`/ثابت، لا رقم بالشاشة).
- **مراحل اشتراك النادي**: `trial → active → grace → expired → locked` (+ `suspended`، `cancelled`). اعرض المرحلة (شارة حسب `backend-contract.md`) والأيام المتبقية لكل نادٍ.
- **الفواتير**: الدفع يدوي (تحويل/نقد) يسجله الفريق `POST …/payments` مع `Idempotency-Key`، والإلغاء بالعكس لا بالحذف. المتأخرة = غير مدفوعة بعد `due_date` (danger).
- **التصدير غير متزامن**: `POST …/exports` ثم `GET …/exports/{id}` حتى `status = completed`، ثم افتح `download_url` (رابط موقّع مؤقت، بلا توكن). استعلم عند فتح النافذة وبزر "تحديث"، لا polling سريع.
- **الحذف النهائي لنادٍ (`purge`)**: لمالك المنصة فقط، بتأكيد مزدوج بالواجهة (`FormDialog` بـ `danger: true` + كتابة اسم/معرّف النادي).
- **جلسة الدعم**: `POST /super-admin/tenants/{tenant_id}/impersonate` بـ `{ user_id, reason }` ← `token` و `dashboard_url`. افتح `{dashboard_url}#token={token}` بتبويب جديد (التوكن بعد `#` فلا يصل لسجلات الخوادم). سبب إلزامي.
- **رفع الشعار**: `POST super-admin/tenants/{id}/logo` (`png, jpg, jpeg, webp`).
- **حدود الطلبات**: 300/دقيقة لفريق المنصة.

## الباكجات بهذا المشروع

القائمة المعتمدة (engineering-rules §13) للويب: + `web`. لا باكجات موبايل أو أوفلاين.

## الأصول

- `packages/ultragym_design`: حزمة الهوية (path dependency). **لا تعدّلها**.
- `assets/brand/`، `assets/icons/`، `assets/ornaments/`.

## حالة البناء

- **مبني ومختبر**: core (engineering-rules §16)، والدخول والجلسة والراوتر (§17): الدخول، اختيار النادي، تغيير كلمة السر الإجباري، استعادة الجلسة، الخروج، شاشات لا اتصال / حجب.
- مسارات الدخول تحت `/super-admin/auth` (`AppConfig.authBase`)، ولا خطوة اختيار نادٍ. الدور من `me.role` يصل كـ `session.roles` (`owner` / `admin`): `session.isPlatformOwner`.
- **التالي**: الهيكل (Shell) ثم الشاشات حسب جدول الشاشات أعلاه. `features/home` مؤقتة وتُستبدل بالرئيسية الحقيقية.

## الـ Skills المتاحة (`.claude/skills/`)

`ultragym-feature` (**استعمله لكل ميزة**)، `bloc`، `testing`، `accessibility`، `animations`، `flutter-build-responsive-layout`، `flutter-fix-layout-issues`، `flutter-add-widget-test`، `flutter-setup-declarative-routing`، `dart-run-static-analysis`، `dart-resolve-package-conflicts`، `dart-use-pattern-matching`.
**الأولوية**: هذا الملف ← `docs/engineering-rules.md` ← `docs/backend-contract.md` ← الـ Skills.

## قبل أن تنهي أي مهمة

1. `flutter analyze` نظيف.
2. لا `setState`، لا ملف فوق 300 سطر، لا لون/نمط/مسافة/مدة/مسار مكتوب.
3. الحالات الأربع، الثيم الداكن، RTL، والأرقام LTR.
4. عرض 360px و 600 و 1024 بلا overflow.
5. جرّب بدور `admin` (المشرف): أقسام المالك مخفية، و 403 معالج.
