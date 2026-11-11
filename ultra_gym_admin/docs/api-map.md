# خريطة مسارات الـ API · لوحة النادي

مولّدة من ملفات OpenAPI الرسمية للباك اند (commit `32b0294`)، المحفوظة بـ `docs/api/`.
المسارات نسبية لـ `/api/v1`. **الأجسام والردود الحقيقية وحالات الخطأ لكل مسار**: افتح ملف الـ YAML نفسه بـ `docs/api/`، أو Swagger على `http://127.0.0.1:8000/api/documentation`.

## `club-player-shared-api.yaml` (11 مساراً)

### Club & Player Apps - Auth

| الطريقة | المسار | الوصف |
|---|---|---|
| POST | `/auth/login` | دخول عضو النادي (مالك، استقبال، لاعب) |
| GET | `/auth/me` | الحساب الحالي ونادي التوكن وأدواره |
| POST | `/auth/logout` | تسجيل الخروج (هذا الجهاز) |
| POST | `/auth/change-password` | تغيير كلمة السر |

### Club & Player Apps - Club & Device

| الطريقة | المسار | الوصف |
|---|---|---|
| GET | `/tenant` | النادي الحالي: الهوية والإعدادات وحالة الاشتراك |
| GET | `/tenant/entitlements` | حدود باقة النادي وميزاتها الفعلية |
| POST | `/devices` | تسجيل الجهاز ونسخة التطبيق (وتوكن الإشعارات) |
| GET | `/announcements` | إعلانات المنصة الموجهة لي |
| POST | `/announcements/{announcement_id}/read` | تعليم إعلان كمقروء |
| GET | `/app-version` | فحص نسخة التطبيق والتحديث الإجباري |
| GET | `/ping` | فحص اتصال الخادم |

## `club-admin-api.yaml` (139 مساراً)

### Club Admin - Dashboard

| الطريقة | المسار | الوصف |
|---|---|---|
| GET | `/club-admin/dashboard` | اللوحة الرئيسية |

### Club Admin - Club & Settings

| الطريقة | المسار | الوصف |
|---|---|---|
| GET | `/club-admin/archive` | أعداد الأرشيف بكل قسم |
| GET | `/club-admin/club` | بيانات النادي وإعداداته واستهلاك الخطة |
| PATCH | `/club-admin/club` | تعديل بيانات تواصل النادي |
| POST | `/club-admin/club/logo` | رفع شعار النادي |
| DELETE | `/club-admin/club/logo` | حذف شعار النادي |
| GET | `/club-admin/club/notification-types` | أنواع الإشعارات وحالتها (للإعدادات) |
| PATCH | `/club-admin/club/settings` | تعديل إعدادات التشغيل |

### Club Admin - Branches

| الطريقة | المسار | الوصف |
|---|---|---|
| POST | `/club-admin/branches` | إضافة فرع |
| GET | `/club-admin/branches` | قائمة الفروع |
| GET | `/club-admin/branches/{branch_id}` | تفاصيل فرع وإحصائياته |
| PATCH | `/club-admin/branches/{branch_id}` | تعديل فرع |
| DELETE | `/club-admin/branches/{branch_id}` | أرشفة فرع |
| POST | `/club-admin/branches/{branch_id}/status` | تفعيل أو إيقاف فرع |

### Club Admin - Players

| الطريقة | المسار | الوصف |
|---|---|---|
| POST | `/club-admin/players` | إضافة لاعب (أو ربط حساب موجود) |
| GET | `/club-admin/players` | قائمة اللاعبين مع اشتراكهم الحالي ودينهم |
| GET | `/club-admin/players/lookup` | بحث الاستقبال السريع مع إمكانية الدخول |
| PATCH | `/club-admin/players/{member_id}` | تعديل اللاعب وملفه |
| GET | `/club-admin/players/{member_id}` | ملف اللاعب الكامل |
| DELETE | `/club-admin/players/{member_id}` | أرشفة لاعب |
| POST | `/club-admin/players/{member_id}/activate` | تفعيل لاعب |
| POST | `/club-admin/players/{member_id}/photo` | رفع صورة اللاعب |
| POST | `/club-admin/players/{member_id}/reset-password` | كلمة سر مؤقتة للاعب |
| POST | `/club-admin/players/{member_id}/restore` | استرجاع لاعب من الأرشيف |
| POST | `/club-admin/players/{member_id}/suspend` | إيقاف لاعب |

### Club Admin - Measurements

| الطريقة | المسار | الوصف |
|---|---|---|
| POST | `/club-admin/players/{player_id}/measurements` | إضافة قياس |
| GET | `/club-admin/players/{player_id}/measurements` | قياسات اللاعب مع التقدم |
| PATCH | `/club-admin/players/{player_id}/measurements/{measurement_id}` | تعديل قياس |
| DELETE | `/club-admin/players/{player_id}/measurements/{measurement_id}` | حذف قياس |

### Club Admin - Membership Plans

| الطريقة | المسار | الوصف |
|---|---|---|
| POST | `/club-admin/membership-plans` | إضافة خطة |
| GET | `/club-admin/membership-plans` | خطط الاشتراك |
| PATCH | `/club-admin/membership-plans/{plan_id}` | تعديل خطة |
| GET | `/club-admin/membership-plans/{plan_id}` | تفاصيل خطة وإحصائياتها |
| DELETE | `/club-admin/membership-plans/{plan_id}` | أرشفة خطة |
| POST | `/club-admin/membership-plans/{plan_id}/restore` | استرجاع خطة |

### Club Admin - Coupons

| الطريقة | المسار | الوصف |
|---|---|---|
| POST | `/club-admin/coupons` | إضافة كوبون |
| GET | `/club-admin/coupons` | الكوبونات |
| PATCH | `/club-admin/coupons/{coupon_id}` | تعديل كوبون |
| GET | `/club-admin/coupons/{coupon_id}` | تفاصيل كوبون |
| DELETE | `/club-admin/coupons/{coupon_id}` | حذف كوبون |

### Club Admin - Memberships & Debts

| الطريقة | المسار | الوصف |
|---|---|---|
| POST | `/club-admin/memberships` | بيع اشتراك مع الدفعات |
| GET | `/club-admin/memberships` | الاشتراكات |
| GET | `/club-admin/memberships/debts` | الديون |
| POST | `/club-admin/memberships/quote` | تسعير اشتراك قبل البيع |
| GET | `/club-admin/memberships/{membership_id}` | تفاصيل اشتراك مع دفعاته وتجميداته |
| POST | `/club-admin/memberships/{membership_id}/cancel` | إلغاء اشتراك مع استرجاع |
| POST | `/club-admin/memberships/{membership_id}/freeze` | تجميد اشتراك |
| GET | `/club-admin/memberships/{membership_id}/invoice` | فاتورة الاشتراك (PDF) |
| POST | `/club-admin/memberships/{membership_id}/payments` | دفعة على اشتراك (سداد دين) |
| POST | `/club-admin/memberships/{membership_id}/renew` | تجديد اشتراك |
| POST | `/club-admin/memberships/{membership_id}/unfreeze` | فك التجميد |

### Club Admin - Attendance & Sessions

| الطريقة | المسار | الوصف |
|---|---|---|
| GET | `/club-admin/attendance` | سجل الحضور |
| POST | `/club-admin/attendance/check-in` | تسجيل دخول لاعب |
| GET | `/club-admin/attendance/today` | حضور اليوم بالفرع |
| POST | `/club-admin/memberships/{membership_id}/sessions` | استهلاك جلسة يدوياً |
| GET | `/club-admin/sessions` | سجل الجلسات المستهلكة |
| POST | `/club-admin/sessions/{consumption_id}/reverse` | إلغاء جلسة مستهلكة |

### Club Admin - Day Passes

| الطريقة | المسار | الوصف |
|---|---|---|
| POST | `/club-admin/day-passes` | بيع دخول يومي (زائر أو لاعب) |
| GET | `/club-admin/day-passes` | سجل الدخول اليومي |
| GET | `/club-admin/day-passes/price` | سعر الدخول اليومي بالفرع |
| GET | `/club-admin/day-passes/{pass_id}` | تفاصيل دخول يومي مع دفعاته |
| POST | `/club-admin/day-passes/{pass_id}/cancel` | إلغاء دخول يومي وعكس دفعاته |

### Club Admin - Reception Offline

| الطريقة | المسار | الوصف |
|---|---|---|
| POST | `/club-admin/reception/devices` | تسجيل جهاز استقبال |
| GET | `/club-admin/reception/devices` | أجهزة الاستقبال |
| POST | `/club-admin/reception/devices/{device_id}/revoke` | إيقاف جهاز |
| GET | `/club-admin/reception/offline-pack` | حزمة العمل أوفلاين |
| POST | `/club-admin/reception/sync` | مزامنة العمليات المسجلة أوفلاين |

### Club Admin - Cash Box

| الطريقة | المسار | الوصف |
|---|---|---|
| POST | `/club-admin/cash-sessions` | فتح وردية صندوق |
| GET | `/club-admin/cash-sessions` | ورديات الصندوق |
| GET | `/club-admin/cash-sessions/current` | الوردية المفتوحة بالفرع |
| GET | `/club-admin/cash-sessions/{session_id}` | تفاصيل وردية مع التفصيل حسب النوع |
| POST | `/club-admin/cash-sessions/{session_id}/close` | إغلاق الوردية بالجرد |
| GET | `/club-admin/cash-sessions/{session_id}/report` | تقرير الوردية (PDF) |

### Club Admin - Ledger & Transactions

| الطريقة | المسار | الوصف |
|---|---|---|
| POST | `/club-admin/transactions` | تسجيل إيراد أو مصروف |
| GET | `/club-admin/transactions` | دفتر الحركات المالية |
| GET | `/club-admin/transactions/{transaction_id}` | تفاصيل حركة |
| GET | `/club-admin/transactions/{transaction_id}/receipt` | إيصال الحركة (PDF) |
| POST | `/club-admin/transactions/{transaction_id}/reverse` | عكس حركة |

### Club Admin - Exchange Rate & Categories

| الطريقة | المسار | الوصف |
|---|---|---|
| POST | `/club-admin/finance/categories` | إضافة تصنيف |
| GET | `/club-admin/finance/categories` | التصنيفات المالية |
| PATCH | `/club-admin/finance/categories/{category_id}` | تعديل تصنيف |
| DELETE | `/club-admin/finance/categories/{category_id}` | حذف تصنيف |
| GET | `/club-admin/finance/exchange-rate` | سعر الصرف الحالي وسجله |
| POST | `/club-admin/finance/exchange-rate` | تحديث سعر الصرف |

### Club Admin - Staff & Trainers

| الطريقة | المسار | الوصف |
|---|---|---|
| POST | `/club-admin/staff-members` | إضافة مدرب أو موظف |
| GET | `/club-admin/staff-members` | المدربون والموظفون |
| PATCH | `/club-admin/staff-members/{staff_id}` | تعديل موظف |
| GET | `/club-admin/staff-members/{staff_id}` | تفاصيل الموظف وسلفه ورواتبه |
| DELETE | `/club-admin/staff-members/{staff_id}` | أرشفة موظف |
| POST | `/club-admin/staff-members/{staff_id}/restore` | استرجاع موظف |

### Club Admin - Payroll

| الطريقة | المسار | الوصف |
|---|---|---|
| POST | `/club-admin/payroll/advances` | صرف سلفة |
| GET | `/club-admin/payroll/advances` | السلف |
| GET | `/club-admin/payroll/salaries` | الرواتب المدفوعة |
| GET | `/club-admin/payroll/staff/{staff_id}/preview` | معاينة راتب شهر مع العمولة |
| POST | `/club-admin/payroll/staff/{staff_id}/salary` | دفع راتب شهر |

### Club Admin - Receptionists

| الطريقة | المسار | الوصف |
|---|---|---|
| POST | `/club-admin/receptionists` | إضافة موظف استقبال |
| GET | `/club-admin/receptionists` | موظفو الاستقبال |
| GET | `/club-admin/receptionists/{member_id}` | تفاصيل موظف |
| PATCH | `/club-admin/receptionists/{member_id}` | تعديل موظف |
| DELETE | `/club-admin/receptionists/{member_id}` | أرشفة موظف |
| POST | `/club-admin/receptionists/{member_id}/activate` | تفعيل موظف |
| PUT | `/club-admin/receptionists/{member_id}/branches` | تعديل فروع الموظف |
| POST | `/club-admin/receptionists/{member_id}/reset-password` | كلمة سر مؤقتة لموظف |
| POST | `/club-admin/receptionists/{member_id}/restore` | استرجاع موظف |
| POST | `/club-admin/receptionists/{member_id}/suspend` | إيقاف موظف |

### Club Admin - Workout Plans

| الطريقة | المسار | الوصف |
|---|---|---|
| POST | `/club-admin/workout-plans` | إضافة برنامج أو قالب |
| GET | `/club-admin/workout-plans` | برامج التدريب |
| GET | `/club-admin/workout-plans/{plan_id}` | تفاصيل برنامج |
| PATCH | `/club-admin/workout-plans/{plan_id}` | تعديل برنامج |
| DELETE | `/club-admin/workout-plans/{plan_id}` | حذف برنامج |
| POST | `/club-admin/workout-plans/{plan_id}/assign` | إسناد برنامج للاعب |

### Club Admin - Announcements

| الطريقة | المسار | الوصف |
|---|---|---|
| POST | `/club-admin/announcements` | نشر إعلان أو حفظه مسودة |
| GET | `/club-admin/announcements` | إعلانات النادي |
| PATCH | `/club-admin/announcements/{announcement_id}` | تعديل إعلان |
| DELETE | `/club-admin/announcements/{announcement_id}` | حذف إعلان |

### Club Admin - Reports

| الطريقة | المسار | الوصف |
|---|---|---|
| GET | `/club-admin/reports` | التقارير المتاحة |
| GET | `/club-admin/reports/{report}` | توليد تقرير (JSON أو PDF أو Excel) |

### Club Admin - Accounts

| الطريقة | المسار | الوصف |
|---|---|---|
| GET | `/club-admin/accounts` | كل حسابات النادي وحالة تفعيلها |
| POST | `/club-admin/accounts/cards/pdf` | بطاقات الدخول للطباعة (PDF) |
| GET | `/club-admin/accounts/options` | خيارات صفحة الحسابات |
| POST | `/club-admin/accounts/reset-passwords` | إعادة كلمات السر (فردي أو جماعي) |
| POST | `/club-admin/accounts/{user_id}/force-password-change` | إجبار تغيير كلمة السر |
| POST | `/club-admin/accounts/{user_id}/regenerate-code` | معرّف دخول جديد |
| DELETE | `/club-admin/accounts/{user_id}/sessions` | إنهاء كل جلسات الحساب |

### Club Admin - Platform Billing

| الطريقة | المسار | الوصف |
|---|---|---|
| GET | `/club-admin/billing/invoices` | فواتير المنصة |
| GET | `/club-admin/billing/invoices/{invoice_id}` | تفاصيل فاتورة |
| GET | `/club-admin/billing/invoices/{invoice_id}/pdf` | فاتورة المنصة (PDF) |
| GET | `/club-admin/billing/subscription` | اشتراك النادي بالمنصة |

### Club Admin - Support

| الطريقة | المسار | الوصف |
|---|---|---|
| POST | `/club-admin/support/tickets` | فتح تذكرة |
| GET | `/club-admin/support/tickets` | تذاكر الدعم |
| GET | `/club-admin/support/tickets/{ticket_id}` | تفاصيل تذكرة مع الردود |
| POST | `/club-admin/support/tickets/{ticket_id}/replies` | رد على تذكرة |

### Club Admin - Activity Log

| الطريقة | المسار | الوصف |
|---|---|---|
| GET | `/club-admin/activity-log` | سجل النشاط |
| GET | `/club-admin/activity-log/{log_id}` | تفاصيل نشاط |

### Club Admin - Profile

| الطريقة | المسار | الوصف |
|---|---|---|
| GET | `/club-admin/profile` | ملفي |
| PATCH | `/club-admin/profile` | تعديل ملفي |
| GET | `/club-admin/profile/sessions` | جلساتي النشطة |
| DELETE | `/club-admin/profile/sessions` | إنهاء جلساتي الأخرى |
| DELETE | `/club-admin/profile/sessions/{session_id}` | إنهاء جلسة |

## مسارات مشتركة غير موثقة بملفات OpenAPI (من `routes/api.php`)

موجودة بالخادم وبالـ PDF (الفصل 3) لكن ليست في أي ملف YAML: الأجسام والردود من الـ PDF أو Swagger المولّد على الخادم.

| الطريقة | المسار | الوصف |
|---|---|---|
| GET | `/notifications` | إشعاراتي بالنادي الحالي (`?unread_only=1&type=a,b&page=`، و `meta.unread_count`) |
| GET | `/notifications/unread-count` | عدّاد الجرس |
| POST | `/notifications/{id}/read` | تعليم إشعار كمقروء |
| POST | `/notifications/read-all` | تعليم الكل كمقروء |
| DELETE | `/notifications/{id}` | حذف إشعار |
| DELETE | `/notifications` | حذف كل إشعاراتي |
| GET | `/notifications/preferences` | أنواع إشعاراتي وحالة كل نوع |
| PUT | `/notifications/preferences` | كتم أنواع لنفسي `{ muted: [...] }` |
| POST | `/notifications/device-token` | تسجيل توكن Firebase للجهاز |
| DELETE | `/notifications/device-token` | إلغاء توكن الجهاز عند الخروج |
| GET | `/profile` | الملف الشخصي |
| PUT | `/profile` | تعديل الملف الشخصي |
| POST | `/profile/change-password` | تغيير كلمة السر |
| POST | `/profile/revoke-all-tokens` | الخروج من كل الأجهزة |
| POST | `/media/upload` | رفع ملف أو صورة (المالك والاستقبال) |
| DELETE | `/media` | حذف ملف مرفوع (المالك) |
