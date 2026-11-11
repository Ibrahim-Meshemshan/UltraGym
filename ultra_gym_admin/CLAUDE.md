# CLAUDE.md · ultra_gym_admin (لوحة النادي)

> **اقرأ هذا الملف كاملاً، والملفين المستوردين أدناه، قبل أي تعديل أو إضافة على المشروع.**
> أي قاعدة هنا تغلب أي Skill أو عادة عامة. إن تعارض طلب مع قاعدة: نبّه صاحب المشروع قبل التنفيذ.

@docs/engineering-rules.md
@docs/backend-contract.md

## ما هو المشروع

- **لوحة إدارة النادي** لمالك النادي (`club_owner`) وموظف الاستقبال (`receptionist`) بالمتصفح. **Flutter Web فقط** (لا android/ios).
- يكلّم مسارات `/club-admin/*` (134 مساراً) + المسارات المشتركة. الخريطة (بالطرق): `docs/api-map.md`، والعقد الدقيق: `docs/api/*.yaml`.
- الاستقبال يستعمل هذه اللوحة أيضاً (محصوراً بفروعه)، أما **محطة الاستقبال بالعمل دون اتصال** فمشروع منفصل: `ultra_gym_reception`. لا تبنِ الأوفلاين هنا.
- قالب الشاشات: `AppShell` = `UGSidebar` + `UGTopBar` + محتوى بأقصى عرض 1320 وهوامش 24. ≥1024 قائمة مفتوحة (264)، 600-1024 مطوية (76، أيقونات + تلميحات)، <600 درج من زر والبحث يختفي والبطاقات عمود واحد. شبكة البطاقات: الأعمدة = العرض ÷ 230 بفراغ 12. عناصر القائمة من `nav_config.dart`، وطيّها بـ `ToggleCubit`.

## التشغيل والبناء

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
flutter build web --release --dart-define=API_BASE_URL=https://api.ultragym.app/api/v1
flutter analyze
```

## الدخول والجلسة

- `POST /auth/login` بـ `{ phone, password, tenant_id?, device_name? }` **بلا `app`** (`AppConfig.loginApp` فارغ) ← جلسة 24 ساعة.
- التوكن بـ `sessionStorage` المتصفح (عبر `package:web`)، والتفضيلات بـ `shared_preferences`.
- لا تبديل نادٍ داخل الجلسة: اخرج وادخل مجدداً واختر النادي (`requires_tenant_selection`).
- **جلسة الدعم**: صفحة `/impersonate` تقرأ `#token=` من الرابط، تحفظه بـ sessionStorage فقط، تمسحه من الرابط، وتفتح اللوحة. خلالها `auth/me.is_impersonated = true` ← شريط ثابت "جلسة دعم من فريق UltraGym" (30 دقيقة، وتغيير كلمة السر أو الموبايل ممنوع).
- جلساتي: `GET /club-admin/profile/sessions`، `DELETE …/sessions/{id}`، `DELETE …/sessions` (كل الأخرى).

## الأدوار والقائمة الجانبية

| القسم | المالك | الاستقبال | شرط الإظهار |
|---|---|---|---|
| الرئيسية | ✓ | ✓ (فروعه، بلا الأرقام المالية الشاملة) | — |
| الأعضاء، الاشتراكات والديون، الحضور | ✓ | ✓ | — |
| الصندوق والحركات | ✓ | ✓ (فروعه، بلا الرواتب والسلف) | `can_view_finance` للمالية |
| الخطط والكوبونات | ✓ | قراءة الخطط | `roles` فيها `club_owner` للكوبونات |
| المدربون والموظفون، الرواتب والسلف | ✓ | — | `can_manage_staff`؛ الرواتب ميزة `advanced_finance` |
| موظفو الاستقبال، الحسابات وبطاقات الدخول | ✓ | — | `can_manage_staff` |
| التقارير | كلها | غير المالية | `GET reports` يرجع المتاح فقط |
| الإعدادات، الفروع، سعر الصرف، التصنيفات | ✓ | — | — |
| الإعلانات وبرامج التدريب والقياسات | ✓ | قراءة البرامج والقياسات | نشر الإعلان للمالك |
| اشتراك النادي بالمنصة، الدعم، سجل النشاط | ✓ | — | — |
| أجهزة الاستقبال | ✓ (الإلغاء للمالك) | — | ميزة `offline_reception` |

الميزات من `GET /tenant/entitlements`؛ ميزة غير مشمولة ← أخفِ القسم أو "غير متاح بباقتك".

## اختيار الفرع

كل عملية تشغيلية (بيع، قبض، دخول، صندوق، مصروف) لها `branch_id`. فرع واحد ← يُستنتج تلقائياً، وإلا محدد الفرع بالشريط العلوي (من `GET branches`؛ الاستقبال يرى فروعه فقط)، يُحفظ ويُرسل مع كل طلب. فرع خارج الصلاحية ← `403 BRANCH_FORBIDDEN`.

**مبني** (`features/branches`): `BranchScopeCubit` يُنشأ بـ `AppShell` ويعيش بعمر الجلسة. أي قسم تحت الهيكل يقرأ `context.read<BranchScopeCubit>().state.branchId` (null = كل الفروع) ويرسله بنفسه مع طلباته (لا interceptor يضيفه تلقائياً). القوائم: null = بلا فلتر. العمليات التي تحتاج فرعاً و `branchId` = null: اطلب اختيار الفرع بالنموذج من `state.active`. بعد فتح أو إغلاق وردية: `context.read<BranchScopeCubit>().refresh()` ليتحدث شريط الصندوق. الاختيار محفوظ بـ shared_preferences بمفتاح `branch.<tenant>.<user>`، والفروع الموقوفة لا تظهر بالمحدد.

## الشاشات والمسارات والنموذج الأولي

النموذج الأولي (UI/UX المعتمد) بـ `docs/ui-prototype/` (افتح `index.html`؛ كل صفحة لها `#dark`). **ابنِ كل شاشة مطابقة لصفحتها** بمكونات الحزمة والتوكنز.

| الشاشة | المسارات (`/club-admin/…`) | صفحة النموذج |
|---|---|---|
| الدخول، اختيار النادي، تغيير كلمة السر | `/auth/*` | `Login.html` |
| الحالات العامة (إشعارات، جلسة دعم، أخطاء، قفل) | — | `SystemStates.html` |
| الرئيسية | `GET dashboard` (+ `branch_id`) | `Dashboard.html` |
| الأعضاء (فلاتر: حالة الاشتراك، الدين، الفرع، الجنس) | `GET/POST players`، `GET/PATCH players/{id}` | `Members.html` |
| ملف العضو، كلمة سر، إيقاف | `players/{id}`، `players/{id}/photo` | `MemberProfile.html` |
| إضافة عضو: الرد فيه `temporary_password` و `whatsapp_message` مرة واحدة ← نافذة نسخ + زر واتساب | `POST players` | `Members.html` |
| البحث السريع (من حرفين، مع `can_enter` وسبب الرفض) | `GET players/lookup?q=&branch_id=` | — |
| الاشتراكات والديون (`meta.summary` للمجاميع) | `GET memberships`، `GET memberships/debts` | `Memberships.html` |
| تفاصيل الاشتراك، تجميد، فك، تجديد، إلغاء (للمالك مع استرجاع اختياري)، فاتورة | `memberships/{id}` و `…/payments`، `…/freeze`، `…/unfreeze`، `…/renew`، `…/cancel`، `…/invoice` | `MembershipDetail.html` |
| بيع اشتراك | `POST memberships/quote` ثم `POST memberships` | `SellMembership.html` |
| سجل الحضور وتسجيل الدخول | `POST attendance/check-in`، `GET attendance/today`، `GET attendance` | `Attendance.html` |
| الجلسات | `POST memberships/{id}/sessions`، `POST sessions/{id}/reverse` | `MembershipDetail.html` |
| الصندوق والورديات، الإغلاق بالجرد (وردية لكل فرع، `totals` حية) | `cash-sessions/*` | `CashSessions.html` |
| دفتر الحركات، تسجيل مصروف/إيراد بتصنيف، عكس (للمالك) | `GET/POST transactions`، `…/receipt`، `…/reverse` | `Transactions.html` |
| سعر الصرف والتصنيفات | الإعدادات المالية (Swagger) | `FinanceSettings.html` |
| الرواتب (معاينة ثم دفع؛ العمولة والسلف محسوبة) | `payroll/*`، `staff-members/*` | `Payroll.html` |
| السلف | `staff-members/*` | `Advances.html` |
| التقارير: عارض واحد يرسم أي تقرير (`summary` بطاقات، `sections` جداول `{title, columns, rows, numeric}`، `data` رسوم) + زرّا PDF و Excel (ميزة `reports_export`) | `GET reports`، `GET reports/{report}?format=json|pdf|xlsx&from&to&branch_id` | `Reports.html` |
| الخطط والكوبونات | `membership-plans/*`، الكوبونات (Swagger) | `Plans.html` |
| خطط التمارين والقياسات | Swagger (Training) | `Training.html` |
| الإعلانات | `announcements/*` | `Announcements.html` |
| الموظفون والحسابات (إعادة كلمات السر فردياً وجماعياً، بطاقات الدخول PDF، معرّف جديد، إنهاء الجلسات) | `staff-members/*`، `receptionists/*`، `accounts/*` | `Staff.html` |
| الدخول اليومي: بيع لزائر أو عضو بلا اشتراك صالح، سجل اليوم، تفاصيل، إلغاء مع عكس الدفعات (للمالك) | `GET day-passes/price?branch_id=`، `POST day-passes` (+ `Idempotency-Key`)، `GET day-passes`، `GET day-passes/{id}`، `POST day-passes/{id}/cancel` | — (جديد، لا صفحة بالنموذج: اتبع `SellMembership.html`) |
| أجهزة الاستقبال | `reception/devices` | `ReceptionDevices.html` |
| إعدادات الفرع ومحرر أقسام الذكور والإناث | `branches/*` | `BranchSettings.html` |
| إعدادات النادي والإشعارات (للمالك: مفتاح لكل نوع للنادي كله) | `GET/PATCH club`، `PATCH club/settings`، `club/logo`، `GET club/notification-types` | `ClubSettings.html` |
| اشتراك النادي، الدعم، سجل النشاط | `billing/*`، الدعم، `activity-log` | `ClubBilling.html` |
| الجرس وإعدادات إشعاراتي | `/notifications/*` | `SystemStates.html` |

## التدفقات التي تحتاج انتباهاً

**فتح اللوحة / الصندوق**: `GET cash-sessions/current` ← لا وردية؟ نافذة فتح الصندوق (الرصيد الافتتاحي مقترح) ← `POST cash-sessions` (مع `Idempotency-Key`) ← العمل ← `POST cash-sessions/{id}/close` بالجرد الفعلي لكل عملة ← تقرير الوردية PDF. أي قبض أو صرف بلا وردية يرجع `409 CASH_SESSION_REQUIRED`: اعرض زر "فتح الصندوق" بنفس الرسالة بدل خطأ عام.

**بيع اشتراك**:
1. اختر العضو (البحث السريع) والخطة (`GET membership-plans?status=active&branch_id=`).
2. مع كل تغيير (خطة، تاريخ بداية، كوبون، خصم) نادِ `POST memberships/quote`: يرجع `price_usd`، `discount_usd`، `net_usd`، `net_syp`، `exchange_rate`، `starts_on`، `ends_on`، `coupon`، `allow_partial_payment`. كوبون خاطئ ← `422 COUPON_INVALID` مع السبب.
3. نموذج الدفع: سطر أو أكثر `{ currency: USD|SYP, amount }` (قد يدفع بالعملتين معاً). اعرض المجموع بالدولار بسعر اليوم والمتبقي.
4. الخصم اليدوي `discount_usd` للمالك فقط؛ خطة تدريب خاص تحتاج `trainer_id`.
5. `POST memberships` مع `Idempotency-Key`. الرد: الاشتراك + الحركات + أرقام الإيصالات ← "طباعة الإيصال".
6. دفع جزئي (إن سمح `allow_partial_payment`): الباقي دين يظهر بالديون.

**تسجيل الدخول للنادي**: `POST attendance/check-in` بواحد من `player_id` (اختيار) أو `member_code` (كتابة/باركود) أو `qr_token` (مسح)، مع `branch_id` و `consume_session` اختياري، و `Idempotency-Key`.
201 مقبول ← بطاقة خضراء بالاسم والصورة والأيام المتبقية، وتحذير عنبري إن `record.in_grace`. 200 + `ALREADY_CHECKED_IN` (خلال 120 دقيقة) ← بطاقة "مسجّل منذ…" بلا صوت خطأ. 409 + السبب ← بطاقة حمراء بالرسالة + زر "تجديد" أو "دفع". 422 `QR_*` ← "اطلب من العضو تحديث الرمز".

**محرر أقسام الذكور والإناث**: `PATCH branches/{id}` بـ `gender_policy` (`mixed` | `time_split`) و `gender_schedule: [{ days: [...], from: "08:00", to: "14:00", gender: "female|male|mixed" }]`. الواجهة: مفتاح "مختلط / أوقات منفصلة" ثم قائمة فترات (الأيام كشرائح، من، إلى، القسم). `to` قبل `from` = تمتد بعد منتصف الليل: اكتب تحتها "(حتى اليوم التالي)". الرد يرجع `days_label` و `gender_label` جاهزين.

**الجداول**: `PagedTable<T>` = `SliceView` + `TableShimmer` + `AppDataTable` + `PaginationBar`. أي تغيير (صفحة، ترتيب، بحث، فلاتر، مسح) يخرج بـ `onQuery(ListQuery)` ليطلبه الـ Bloc. فارغ مع فلاتر = "لا نتائج" بزر مسح. كامل على الكمبيوتر، تمرير أفقي على التابلت، بطاقات على الموبايل. `FilterBar`: بحث بـ `Debouncer` + فلاتر + مسح. الإجراءات: `RowActions`، `DetailDialog` (يجلب العنصر عند الفتح)، `FormDialog` لكل تعديل، `CredentialsDialog` (بيانات دخول تُعرض مرة واحدة)، `ExportDialog`.
**المكونات**: `StatCard`، `HeroBanner` (المكان المزخرف الوحيد بالرئيسية)، `InfoGrid`، `AppTabs`، `StatusBadge`، الرسوم `TrendChart` / `BarsChart` / `ChartLegend` فوق `fl_chart` (و `RepBarChart` من الحزمة). البحث الشامل والتنبيهات تفتح الصفحات بفلتر أولي عبر query parameters.

**الدخول اليومي** (منذ 2026-11-06): يُفعَّل بإعداد النادي `day_pass_enabled` وسعره `day_pass_price_usd` (للنادي أو الفرع). `POST day-passes` بـ `{ branch_id, player_id? | visitor_name + visitor_phone? + gender?, payments: [{currency, amount}], price_usd? (للمالك فقط), notes? }`. الأخطاء: `DAY_PASS_DISABLED`، `DAY_PASS_PRICE_MISSING`، `HAS_ACTIVE_MEMBERSHIP` (اعرض "سجّل دخوله العادي")، `DAY_PASS_EXISTS`، `GENDER_UNKNOWN` (حدد جنس الزائر بفرع أوقات منفصلة)، `GENDER_HOURS`. الإلغاء للمالك ويعكس الدفعات. التفاصيل بـ `docs/api/club-admin-api.yaml`.

**إشعارات المالك ← الشاشة**: `membership` ← `memberships/{membership_id}`، `player` ← `players/{player_id}`، `payment`/`transaction` ← `transactions/{transaction_id}`، `cash_session` ← `cash-sessions/{cash_session_id}`، `memberships` ← الاشتراكات (تنتهي قريباً) والديون بفلتر `branch_id`، `reception_sync` ← "عمليات تحتاج مراجعة"، `reception_devices` ← أجهزة الاستقبال، `billing` / `billing_invoice` / `support_ticket` ← اشتراك النادي / الفاتورة / تذكرة الدعم. إشعارات المنصة للمالك لا تُطفأ ولا تُكتم.

## الباكجات بهذا المشروع

القائمة المعتمدة (engineering-rules §13) للويب: + `web`، و `mobile_scanner` (مسح QR بالكاميرا بنافذة تسجيل الدخول، بموافقة صاحب المشروع 2026-11-11). لا `flutter_secure_storage` ولا باكجات الأوفلاين هنا.

## الأصول

- `packages/ultragym_design`: حزمة الهوية (path dependency). **لا تعدّلها**.
- `assets/brand/` الشعار PNG، `assets/icons/` 21 أيقونة SVG للهوية (`SvgPicture.asset('assets/icons/dumbbell.svg')` بلون `currentColor` عبر `colorFilter`)، `assets/ornaments/` خلفية الدخول وفن الحالة الفارغة. الزخارف الأخرى مرسومة بالكود في الحزمة.
- `web/` الأيقونات و favicon و manifest من الهوية.

## حالة البناء

- **مبني ومختبر**: core (engineering-rules §16)، والدخول والجلسة والراوتر (§17): الدخول، اختيار النادي، تغيير كلمة السر الإجباري، استعادة الجلسة، الخروج، شاشات لا اتصال / حجب.
- **جلسة الدعم**: `main.dart` يستدعي `Impersonation.consume(...)` (`core/storage/impersonation.dart`) قبل `AuthStarted`: يقرأ `#token=` من الرابط، يحفظه بـ sessionStorage، ويمسحه من الرابط.
- **الهيكل** (engineering-rules §18): `core/layout` = `AppShell` (ShellRoute) + `AppSidebar` + `AppTopBar` + `SupportBanner` + `AppPage`. أقسام القائمة وشروط إظهارها بـ `nav_config.dart` (`AdminNav`)، وكل قسم له ثابت بـ `Routes` ومسار تحميه `sectionGuard`. الأقسام غير المبنية تعرض `PendingSection`؛ الرئيسية مبنية (أدناه).
- **الشريط العلوي**: محدد الفرع (`BranchPicker`) وحالة الصندوق (`CashStatusBadge`، من `cash_session_open` لكل فرع، تفتح الصندوق) مبنيان. بالموبايل المحدد أيقونة فقط والشارة مخفية.
- **البحث السريع والجرس** مبنيان (`features/quick_search`، `features/notifications`، engineering-rules §18): Ctrl K، عدّاد كل 60 ثانية بينما الواجهة ظاهرة، فتح الإشعار حسب `screen`. أي عملية تغيّر ما يُشعَر به تستدعي بعدها `context.read<UnreadCountCubit>().refresh()`.
- **الرئيسية** مبنية (`features/dashboard`، engineering-rules §19): `GET dashboard` + `GET memberships?expiring_within_days=7` بالتوازي، Cubit لكل فرع مختار. المال ورصيد الصناديق للمالك فقط (الخادم لا يرسلهما للاستقبال). أي شاشة تحتاج رقم مال مع كسور تستعمل `AppStatCard(decimals: 2)` لا `StatCard`.
- **الأعضاء** مبنية (`features/members`، engineering-rules §20): الجدول بالفلاتر والصفحات والأرشيف، وإضافة عضو مع بيانات الدخول مرة واحدة، وملف العضو `/members/{id}` (بيانات، تعديل، إيقاف/تفعيل، كلمة سر، صورة، سجل الاشتراكات والحضور والدفعات). ومعها بـ core: `PagedTable` / `AppDataTable` / `PaginationBar` / `FilterBar` / `AppTabs` / `CredentialsDialog` / `IdempotencyKeeper` (§16).
- **الاشتراكات والديون** مبنية (`features/memberships`، engineering-rules §21): أرقام الرأس، تبويبات الكل / الديون / تنتهي خلال 7 أيام، فلاتر الحالة والخطة والفرع والبحث، وروابط الرئيسية بفلتر أولي.
- **تفاصيل الاشتراك** مبنية (`/memberships/{id}`، engineering-rules §22): السداد، التجميد وفكه، التجديد بعرض السعر، الإلغاء للمالك مع استرجاع، تسجيل جلسة، الفاتورة والإيصالات، وتبويبات الدفعات والتجميدات والحضور.
- **بيع اشتراك** مبني (`/memberships/new` و `?player_id=` من ملف العضو، engineering-rules §23): اختيار العضو بالبحث السريع، الخطة، التسعير مع كل تغيير، الكوبون والخصم اليدوي للمالك، المدرب لخطة التدريب الخاص، الدفع بالعملتين والمتبقي تقديراً، تنبيه الصندوق المغلق، والإيصالات بعد البيع.
- **الحضور** مبني (`/attendance`، engineering-rules §24): أرقام اليوم ورسم الساعات لفرع الشريط (أو الرئيسي)، السجل بالبحث والفترة والطريقة والحالة، وتسجيل الدخول اليدوي بالمعرّف أو البحث أو مسح QR بالكاميرا مع بطاقة النتيجة (مقبول، سماح، مكرر، مرفوض) وفعل المتابعة (بيع، فتح الاشتراك، سداد الدين).
- **باقة النادي** مبنية (`features/club_plan`، engineering-rules §25): الأقسام خارج الباقة مخفية وروابطها تعرض "ليست ضمن باقتك"، وشريط فترة السماح أو القراءة فقط تحت الشريط العلوي.
- **الدخول اليومي** مبني (`/day-passes`، engineering-rules §26): سعر فرع الشريط (أو الرئيسي) وأرقام الفترة والسجل بالفلاتر، البيع لزائر أو عضو بالبحث (السعر للمالك، 0 = يوم تجربة، الجنس بفرع الأوقات المنفصلة، دفع كامل) مع الإيصالات، والتفاصيل بنافذة مع الإلغاء للمالك.
- **الصندوق** مبني (`/cash-sessions` و `/cash-sessions/{id}`، engineering-rules §27): صندوق فرع الشريط (أو كل فرع) بأرصدته الحية و "حسب النوع"، فتح الصندوق بالرصيد المقترح، الإغلاق بالجرد مع الفرق التقديري ثم النتيجة والتقرير، والورديات السابقة بالفترة والفرع و "بفرق فقط".
- **دفتر الحركات** مبني (`/cash-sessions/transactions`، تبويب بقسم "الصندوق والحركات"، engineering-rules §28): مجاميع الفلتر (الداخل، الخارج، الصافي، العدد)، الدفتر بالبحث والفترة والنوع والعملة والفرع و "بلا المعكوسة"، تسجيل مصروف أو إيراد بتصنيف (من الدفتر أو من بطاقة الوردية المفتوحة)، التفاصيل بنافذة، الإيصال، والعكس للمالك بسبب إلزامي.
- **سعر الصرف والتصنيفات** مبنية (`/cash-sessions/exchange-rate` و `/cash-sessions/categories`، تبويبان بنفس القسم، engineering-rules §29): السعر المعتمد ومن حدّثه، اعتماد سعر جديد للمالك، السجل بالفرق عن السابق، والتصنيفات بمجموعتين (إضافة، تعديل الاسم والحالة، حذف غير المستعمل للمالك؛ الاستقبال يقرأ).
- **الخطط والكوبونات** مبنية (`/plans`، engineering-rules §30): بطاقات الخطط (للاستقبال قراءة)، وللمالك إضافة وتعديل خطة بالمدة أو الحصص ولكل الفروع أو بعضها مع حدود التجميد، الأرشفة والاسترجاع، وجدول الكوبونات بالإضافة والتعديل وحذف غير المستعمل.
- **الرواتب والسلف** مبنية (`/payroll`، engineering-rules §31): الشهر وقائمة الموظفين بحالة راتبه (مصروف / مستحق)، معاينة الراتب (الأساسي، العمولة، السلف المفتوحة) مع المكافأة والخصومات وخصم السلف والصافي التقديري ثم الصرف من الصندوق بتأكيد، الراتب المصروف بأسطره وإيصاله، والسلف بأرقامها وجدولها وفلاتر الحالة والموظف و "صرف سلفة".
- **التقارير** مبنية (`/reports`، engineering-rules §32): عارض واحد لأي تقرير من الخادم (الملخص بطاقات، الأقسام جداول، رسم للصندوق اليومي والحضور)، القائمة الجانبية أو حبة "التقرير" بالعرض الضيق، الفترة والفرع حسب التقرير، الصفحات لتقارير القوائم، وتصدير PDF و Excel حسب الباقة.
- **المدربون والتدريب** مبني (`/training`، engineering-rules §33): خطط التمارين (لأعضاء / قوالب عامة، المحرر بالأيام والتمارين، الحفظ، الإسناد لعضو بنسخة، الحذف) والقياسات (العضو بالبحث أو من ملفه، آخر القيم والفرق منذ البداية، رسم الوزن، الجدول، الإضافة والتعديل والحذف). التعديل للمالك والاستقبال يقرأ. لا `fl_chart` (لا يُبنى على Flutter 3.32).
- **الإعلانات** مبنية (`/announcements`، engineering-rules §34): القائمة بفلتر الحالة، النشر الفوري أو المسودة، الجمهور والفرع والانتهاء، إشعار مرة واحدة، المعاينة، التعديل وإيقاف النشر والحذف. للمالك فقط؛ لا جدولة بالخادم.
- **الإعدادات والفروع** مبنية (`/settings`، engineering-rules §35): تبويب النادي (التواصل والشعار، التشغيل، الاشتراكات والدخول، الدخول اليومي وبرامج الأعضاء، مفتاح لكل نوع إشعار بالجمهور؛ الحفظ يرسل المتغيّر فقط) وتبويب الفروع (`?tab=branches`: القائمة بحد الباقة، الإضافة والتعديل، أقسام الذكور والإناث بالفترات، الإيقاف والتفعيل والأرشفة). للمالك فقط.
- **الموظفون والحسابات** مبنية (`/staff`، engineering-rules §36): حد الموظفين بالباقة، تبويب حسابات الاستقبال (الإضافة بالفروع وكلمة السر مرة واحدة، التعديل، الفروع، الإيقاف والتفعيل، الأرشفة)، تبويب المدربين والعمال (`?tab=staff`: الراتب والعمولة للمدرب)، وتبويب كل الحسابات (`?tab=accounts`: الحالات بعدّاداتها)؛ كلمة سر جديدة فردياً أو لمجموعة مع بطاقات الدخول PDF، معرّف جديد، وإنهاء الجلسات.
- **أجهزة الاستقبال** مبنية (`/reception-devices`، engineering-rules §37): خطوات التجهيز، الأجهزة المسجلة بآخر تحميل ومزامنة والحالة، فلتر الفرع والحالة، والإيقاف للمالك.
- **اشتراك النادي والدعم وسجل النشاط** مبنية (`/billing`، engineering-rules §38): الاشتراك والاستخدام والفواتير مع PDF، تذاكر الدعم بالمحادثة والرد والمرفقات (`?tab=support`، `&ticket_id=`)، وسجل النشاط بفلاتره وتفاصيل التغيير (`?tab=activity`)؛ `?invoice_id=` يفتح الفاتورة.
- **التالي**: كل أقسام اللوحة مبنية. الفجوات الصغيرة بأقسام "لم يُبنَ" بالقواعد، ثم المشاريع الأخرى حسب `CONTEXT_HANDOFF.md`.

## الـ Skills المتاحة (`.claude/skills/`)

`ultragym-feature` (قائمة الميزة الجديدة لهذا المشروع، **استعمله لكل ميزة**)، `bloc`، `testing`، `accessibility`، `animations` (Very Good Ventures)، `flutter-build-responsive-layout`، `flutter-fix-layout-issues`، `flutter-add-widget-test`، `flutter-setup-declarative-routing` (فريق Flutter)، `dart-run-static-analysis`، `dart-resolve-package-conflicts`، `dart-use-pattern-matching` (فريق Dart).
**الأولوية**: هذا الملف ← `docs/engineering-rules.md` ← `docs/backend-contract.md` ← الـ Skills. مثلاً: الـ Skills تقترح `TypedGoRoute` أو حالات sealed أو `RepositoryProvider` أو ثوابت حركة Material: هنا نستعمل `Routes` و `Slice` و `get_it` و `AppMotion`.

## قبل أن تنهي أي مهمة

1. `flutter analyze` نظيف.
2. لا `setState`، لا ملف فوق 300 سطر، لا لون/نمط/مسافة/مدة/مسار مكتوب.
3. الحالات الأربع، الثيم الداكن، RTL، والأرقام LTR.
4. عرض 360px و 600 و 1024 بلا overflow.
5. الصلاحيات: ما لا يُسمح مخفي، و 403 معالج.
