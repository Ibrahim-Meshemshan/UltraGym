# خريطة مسارات الـ API · تطبيق العضو

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

## `player-app-api.yaml` (34 مساراً)

### Player App - Home & Card

| الطريقة | المسار | الوصف |
|---|---|---|
| GET | `/player/card` | البطاقة الرقمية (المعرّف، الصورة، الاشتراك، إعدادات QR) |
| GET | `/player/home` | الرئيسية: اشتراكي، الدين، التنبيهات، الحضور، الإعلانات، آخر قياس، البرنامج |

### Player App - QR Keys

| الطريقة | المسار | الوصف |
|---|---|---|
| GET | `/player/qr-keys` | مفاتيح أجهزتي لرمز QR |
| POST | `/player/qr-keys` | تسجيل المفتاح العام لهذا الجهاز |
| DELETE | `/player/qr-keys/{key_id}` | إلغاء مفتاح جهاز |
| POST | `/player/qr/verify` | فحص رمز يولّده التطبيق (للتطوير وضبط الساعة) |

### Player App - Memberships & Payments

| الطريقة | المسار | الوصف |
|---|---|---|
| GET | `/player/memberships` | كل اشتراكاتي |
| GET | `/player/memberships/current` | اشتراكي الحالي بالتفاصيل والقادم |
| GET | `/player/memberships/{membership_id}` | تفاصيل اشتراك: الدفعات والتجميدات والجلسات |
| GET | `/player/memberships/{membership_id}/invoice` | فاتورة الاشتراك (PDF) |
| GET | `/player/payments` | دفعاتي |
| GET | `/player/payments/{transaction_id}/receipt` | إيصال دفعة (PDF) |

### Player App - Attendance

| الطريقة | المسار | الوصف |
|---|---|---|
| GET | `/player/attendance` | سجل دخولي |
| GET | `/player/attendance/stats` | إحصائيات الحضور: الأشهر وأيام الأسبوع والساعات |

### Player App - Progress & Training

| الطريقة | المسار | الوصف |
|---|---|---|
| GET | `/player/measurements` | قياساتي |
| GET | `/player/measurements/progress` | تقدّمي: الفرق بين أول وآخر قياس وسلسلة للرسوم |
| GET | `/player/workout-plans` | برامجي التدريبية |
| POST | `/player/workout-plans` | إضافة برنامج تدريب خاص فيني |
| GET | `/player/workout-plans/{plan_id}` | البرنامج بالأيام والتمارين |
| PATCH | `/player/workout-plans/{plan_id}` | تعديل برنامجي |
| DELETE | `/player/workout-plans/{plan_id}` | حذف برنامجي |
| POST | `/player/workout-plans/{plan_id}/copy` | نسخ برنامج (من النادي) لبرامجي لأعدّل عليه |

### Player App - Club & Plans

| الطريقة | المسار | الوصف |
|---|---|---|
| GET | `/player/club` | معلومات النادي وفروعه |
| GET | `/player/plans` | خطط التجديد |
| GET | `/player/plans/{plan_id}` | تفاصيل خطة مع تاريخ التجديد المتوقع |

### Player App - Announcements

| الطريقة | المسار | الوصف |
|---|---|---|
| GET | `/player/announcements` | إعلانات ناديّ |
| POST | `/player/announcements/read-all` | تعليم كل الإعلانات مقروءة |
| GET | `/player/announcements/{announcement_id}` | فتح إعلان (يعلّمه مقروءاً) |

### Player App - Account

| الطريقة | المسار | الوصف |
|---|---|---|
| GET | `/player/clubs` | نواديّ |
| POST | `/player/clubs/switch` | التبديل لنادٍ آخر |
| GET | `/player/profile` | ملفي |
| PATCH | `/player/profile` | تعديل ملفي |
| POST | `/player/profile/photo` | رفع صورتي |
| DELETE | `/player/profile/photo` | حذف صورتي |

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
