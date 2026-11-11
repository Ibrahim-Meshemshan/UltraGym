# خريطة مسارات الـ API · لوحة المنصة

مولّدة من ملفات OpenAPI الرسمية للباك اند (commit `32b0294`)، المحفوظة بـ `docs/api/`.
المسارات نسبية لـ `/api/v1`. **الأجسام والردود الحقيقية وحالات الخطأ لكل مسار**: افتح ملف الـ YAML نفسه بـ `docs/api/`، أو Swagger على `http://127.0.0.1:8000/api/documentation`.

## `super-admin-api.yaml` (148 مساراً)

### Super Admin - Auth

| الطريقة | المسار | الوصف |
|---|---|---|
| POST | `/super-admin/auth/login` | تسجيل الدخول |
| POST | `/super-admin/auth/logout` | تسجيل الخروج |
| GET | `/super-admin/auth/me` | حسابي |
| PATCH | `/super-admin/auth/me` | تعديل حسابي |
| POST | `/super-admin/auth/change-password` | تغيير كلمة السر |
| POST | `/super-admin/auth/change-phone` | تغيير رقم موبايل حسابي |
| GET | `/super-admin/auth/sessions` | جلساتي النشطة |
| DELETE | `/super-admin/auth/sessions` | إنهاء كل جلساتي الأخرى |
| DELETE | `/super-admin/auth/sessions/{session_id}` | إنهاء جلسة من جلساتي |

### Super Admin - Search

| الطريقة | المسار | الوصف |
|---|---|---|
| GET | `/super-admin/search` | بحث شامل |

### Super Admin - Analytics

| الطريقة | المسار | الوصف |
|---|---|---|
| GET | `/super-admin/analytics/overview` | نظرة عامة على المنصة |
| GET | `/super-admin/analytics/tenants-summary` | ملخص النوادي |
| GET | `/super-admin/analytics/growth` | نمو المنصة |
| GET | `/super-admin/analytics/subscriptions` | تحليل الاشتراكات |
| GET | `/super-admin/analytics/revenue` | تحليل الإيرادات |
| GET | `/super-admin/analytics/usage` | استهلاك النوادي مقابل حدود خططها |
| GET | `/super-admin/analytics/activity` | نشاط المستخدمين والتطبيقات |
| GET | `/super-admin/analytics/tenants/{tenant_id}` | إحصائيات نادي واحد |
| POST | `/super-admin/analytics/exports` | طلب تصدير تقرير |
| GET | `/super-admin/analytics/exports/{export_id}` | حالة التصدير ورابط التحميل |
| GET | `/super-admin/analytics/operations` | المؤشرات التشغيلية على مستوى المنصة |

### Super Admin - Tenants

| الطريقة | المسار | الوصف |
|---|---|---|
| GET | `/super-admin/tenants` | قائمة النوادي |
| POST | `/super-admin/tenants` | إنشاء نادي |
| GET | `/super-admin/tenants/check-slug` | التحقق من توفر الـ slug |
| POST | `/super-admin/tenants/bulk-action` | إجراء جماعي على عدة نوادي |
| GET | `/super-admin/tenants/{tenant_id}` | تفاصيل نادي |
| PATCH | `/super-admin/tenants/{tenant_id}` | تعديل بيانات نادي |
| DELETE | `/super-admin/tenants/{tenant_id}` | أرشفة نادي |
| GET | `/super-admin/tenants/{tenant_id}/backup` | تنزيل نسخة بيانات نادي (Excel) |
| POST | `/super-admin/tenants/{tenant_id}/restore` | استرجاع نادي مؤرشف |
| POST | `/super-admin/tenants/{tenant_id}/purge` | حذف نهائي لنادي وكل بياناته |
| POST | `/super-admin/tenants/{tenant_id}/suspend` | إيقاف نادي |
| POST | `/super-admin/tenants/{tenant_id}/activate` | تفعيل نادي موقوف |
| GET | `/super-admin/tenants/{tenant_id}/status-history` | سجل تغييرات حالة النادي |
| POST | `/super-admin/tenants/{tenant_id}/logo` | رفع شعار النادي |
| DELETE | `/super-admin/tenants/{tenant_id}/logo` | حذف شعار النادي |
| POST | `/super-admin/tenants/{tenant_id}/owner/reset-password` | إعادة تعيين كلمة سر مالك النادي |
| GET | `/super-admin/tenants/{tenant_id}/settings` | إعدادات النادي |
| PATCH | `/super-admin/tenants/{tenant_id}/settings` | تعديل إعدادات النادي |
| POST | `/super-admin/tenants/{tenant_id}/data-export` | تصدير كل بيانات نادي |

### Super Admin - Plans

| الطريقة | المسار | الوصف |
|---|---|---|
| GET | `/super-admin/plans` | قائمة الخطط |
| POST | `/super-admin/plans` | إنشاء خطة |
| GET | `/super-admin/plans/catalog` | كتالوج الحدود والميزات |
| GET | `/super-admin/plans/{plan_id}` | تفاصيل خطة |
| PATCH | `/super-admin/plans/{plan_id}` | تعديل خطة |
| DELETE | `/super-admin/plans/{plan_id}` | حذف خطة |
| POST | `/super-admin/plans/{plan_id}/activate` | تفعيل خطة |
| POST | `/super-admin/plans/{plan_id}/deactivate` | تعطيل خطة |
| POST | `/super-admin/plans/{plan_id}/duplicate` | نسخ خطة |

### Super Admin - Subscriptions

| الطريقة | المسار | الوصف |
|---|---|---|
| GET | `/super-admin/subscriptions` | قائمة الاشتراكات |
| POST | `/super-admin/subscriptions` | اشتراك جديد لنادي |
| GET | `/super-admin/subscriptions/{subscription_id}` | تفاصيل اشتراك |
| PATCH | `/super-admin/subscriptions/{subscription_id}` | تعديل ملاحظات اشتراك |
| POST | `/super-admin/subscriptions/{subscription_id}/renew` | تجديد اشتراك |
| POST | `/super-admin/subscriptions/{subscription_id}/extend` | تمديد مجاني |
| POST | `/super-admin/subscriptions/{subscription_id}/change-plan` | تغيير الخطة (ترقية أو تخفيض) |
| POST | `/super-admin/subscriptions/{subscription_id}/cancel` | إلغاء اشتراك |
| POST | `/super-admin/subscriptions/{subscription_id}/suspend` | تعليق اشتراك |
| POST | `/super-admin/subscriptions/{subscription_id}/resume` | استئناف اشتراك معلّق |
| GET | `/super-admin/subscriptions/{subscription_id}/history` | سجل أحداث الاشتراك |
| GET | `/super-admin/tenants/{tenant_id}/entitlements` | الحدود والميزات الفعلية لنادي |
| GET | `/super-admin/tenants/{tenant_id}/overrides` | تجاوزات نادي |
| PUT | `/super-admin/tenants/{tenant_id}/overrides` | ضبط تجاوزات نادي |

### Super Admin - Finance

| الطريقة | المسار | الوصف |
|---|---|---|
| GET | `/super-admin/finance/summary` | الملخص المالي |
| GET | `/super-admin/finance/invoices` | قائمة الفواتير |
| POST | `/super-admin/finance/invoices` | إصدار فاتورة |
| GET | `/super-admin/finance/invoices/{invoice_id}` | تفاصيل فاتورة |
| PATCH | `/super-admin/finance/invoices/{invoice_id}` | تعديل فاتورة |
| POST | `/super-admin/finance/invoices/{invoice_id}/cancel` | إلغاء فاتورة |
| GET | `/super-admin/finance/invoices/{invoice_id}/pdf` | تحميل الفاتورة PDF |
| POST | `/super-admin/finance/invoices/{invoice_id}/payments` | تسجيل دفعة على فاتورة |
| GET | `/super-admin/finance/payments` | قائمة كل الدفعات |
| GET | `/super-admin/finance/payments/{payment_id}` | تفاصيل دفعة |
| GET | `/super-admin/finance/payments/{payment_id}/pdf` | طباعة إيصال استلام دفعة |
| POST | `/super-admin/finance/payments/{payment_id}/reverse` | عكس دفعة (إبطال أو استرداد) |
| GET | `/super-admin/finance/tenants/{tenant_id}/statement` | كشف حساب نادي |
| GET | `/super-admin/finance/tenants/{tenant_id}/statement/pdf` | طباعة كشف حساب نادي |

### Super Admin - Users

| الطريقة | المسار | الوصف |
|---|---|---|
| GET | `/super-admin/users` | بحث بمستخدمي كل النوادي |
| GET | `/super-admin/users/{user_id}` | تفاصيل مستخدم |
| PATCH | `/super-admin/users/{user_id}` | تعديل مستخدم |
| POST | `/super-admin/users/{user_id}/reset-password` | إعادة تعيين كلمة سر مستخدم |
| POST | `/super-admin/users/{user_id}/suspend` | إيقاف مستخدم على مستوى النظام |
| POST | `/super-admin/users/{user_id}/activate` | تفعيل مستخدم موقوف |
| GET | `/super-admin/users/{user_id}/sessions` | جلسات مستخدم |
| DELETE | `/super-admin/users/{user_id}/sessions` | إنهاء كل جلسات مستخدم |
| POST | `/super-admin/users/reset-passwords` | إعادة تعيين كلمات السر لعدة حسابات دفعة واحدة |
| POST | `/super-admin/users/cards/pdf` | طباعة بطاقات الدخول (PDF) |

### Super Admin - Impersonation

| الطريقة | المسار | الوصف |
|---|---|---|
| POST | `/super-admin/tenants/{tenant_id}/impersonate` | الدخول كمستخدم بنادي |
| GET | `/super-admin/impersonations` | سجل جلسات الدخول كمستخدم |
| POST | `/super-admin/impersonations/{impersonation_id}/end` | إنهاء جلسة دخول كمستخدم |

### Super Admin - Support Tickets

| الطريقة | المسار | الوصف |
|---|---|---|
| GET | `/super-admin/support/tickets` | قائمة التذاكر |
| POST | `/super-admin/support/tickets` | فتح تذكرة نيابة عن نادي |
| GET | `/super-admin/support/tickets/{ticket_id}` | تفاصيل تذكرة وردودها |
| PATCH | `/super-admin/support/tickets/{ticket_id}` | تعديل تصنيف أو أولوية تذكرة |
| POST | `/super-admin/support/tickets/{ticket_id}/replies` | إضافة رد أو ملاحظة داخلية |
| PATCH | `/super-admin/support/tickets/{ticket_id}/status` | تغيير حالة تذكرة |
| POST | `/super-admin/support/tickets/{ticket_id}/assign` | إسناد تذكرة لمشرف |

### Super Admin - Announcements

| الطريقة | المسار | الوصف |
|---|---|---|
| GET | `/super-admin/announcements` | قائمة الإعلانات |
| POST | `/super-admin/announcements` | إنشاء إعلان |
| GET | `/super-admin/announcements/{announcement_id}` | تفاصيل إعلان |
| PATCH | `/super-admin/announcements/{announcement_id}` | تعديل إعلان |
| DELETE | `/super-admin/announcements/{announcement_id}` | حذف إعلان |
| POST | `/super-admin/announcements/{announcement_id}/publish` | نشر إعلان الآن |
| POST | `/super-admin/announcements/{announcement_id}/archive` | أرشفة إعلان |

### Super Admin - Message Templates

| الطريقة | المسار | الوصف |
|---|---|---|
| GET | `/super-admin/message-templates` | قوالب الرسائل |
| GET | `/super-admin/message-templates/{template_key}` | تفاصيل قالب |
| PATCH | `/super-admin/message-templates/{template_key}` | تعديل نص قالب |
| POST | `/super-admin/message-templates/{template_key}/reset` | استرجاع النص الافتراضي |
| POST | `/super-admin/message-templates/{template_key}/render` | تجهيز رسالة للإرسال اليدوي |

### Super Admin - Admins

| الطريقة | المسار | الوصف |
|---|---|---|
| GET | `/super-admin/admins` | قائمة مشرفي المنصة |
| POST | `/super-admin/admins` | إنشاء مشرف |
| GET | `/super-admin/admins/{admin_id}` | تفاصيل مشرف |
| PATCH | `/super-admin/admins/{admin_id}` | تعديل مشرف |
| DELETE | `/super-admin/admins/{admin_id}` | حذف مشرف |
| POST | `/super-admin/admins/{admin_id}/restore` | استرجاع مشرف محذوف |
| POST | `/super-admin/admins/{admin_id}/suspend` | إيقاف مشرف |
| POST | `/super-admin/admins/{admin_id}/activate` | تفعيل مشرف موقوف |
| POST | `/super-admin/admins/{admin_id}/reset-password` | إعادة تعيين كلمة سر مشرف |
| GET | `/super-admin/admins/{admin_id}/sessions` | جلسات المشرف النشطة |
| DELETE | `/super-admin/admins/{admin_id}/sessions` | إنهاء كل جلسات المشرف |
| DELETE | `/super-admin/admins/{admin_id}/sessions/{session_id}` | إنهاء جلسة واحدة |

### Super Admin - Audit Log

| الطريقة | المسار | الوصف |
|---|---|---|
| GET | `/super-admin/audit-logs` | سجل التدقيق |
| GET | `/super-admin/audit-logs/actions` | قائمة الإجراءات المسجّلة |
| GET | `/super-admin/audit-logs/{audit_log_id}` | تفاصيل قيد |

### Super Admin - Notifications

| الطريقة | المسار | الوصف |
|---|---|---|
| GET | `/super-admin/notifications` | إشعارات المشرف |
| GET | `/super-admin/notifications/unread-count` | عدد غير المقروء |
| POST | `/super-admin/notifications/{notification_id}/read` | تعليم إشعار كمقروء |
| POST | `/super-admin/notifications/read-all` | تعليم الكل كمقروء |

### Super Admin - Settings

| الطريقة | المسار | الوصف |
|---|---|---|
| GET | `/super-admin/settings` | إعدادات النظام |
| PATCH | `/super-admin/settings` | تعديل إعدادات النظام |
| PUT | `/super-admin/settings/maintenance` | تشغيل أو إيقاف وضع الصيانة |

### Super Admin - App Versions

| الطريقة | المسار | الوصف |
|---|---|---|
| GET | `/super-admin/app-versions` | إصدارات التطبيقات |
| POST | `/super-admin/app-versions` | تسجيل إصدار جديد |
| GET | `/super-admin/app-versions/{version_id}` | تفاصيل إصدار |
| PATCH | `/super-admin/app-versions/{version_id}` | تعديل إصدار |
| DELETE | `/super-admin/app-versions/{version_id}` | حذف إصدار |

### Super Admin - System

| الطريقة | المسار | الوصف |
|---|---|---|
| GET | `/super-admin/system/health` | صحة النظام |
| GET | `/super-admin/system/failed-jobs` | المهام الفاشلة |
| POST | `/super-admin/system/failed-jobs/retry-all` | إعادة محاولة كل المهام الفاشلة |
| POST | `/super-admin/system/failed-jobs/{job_id}/retry` | إعادة محاولة مهمة |
| DELETE | `/super-admin/system/failed-jobs/{job_id}` | حذف مهمة فاشلة |
| GET | `/super-admin/system/backups` | النسخ الاحتياطية |
| POST | `/super-admin/system/backups` | نسخة احتياطية الآن |
| GET | `/super-admin/system/backups/{backup_id}/download` | رابط تحميل نسخة |
| DELETE | `/super-admin/system/backups/{backup_id}` | حذف نسخة احتياطية |
| GET | `/super-admin/files/exports/{export_id}` | تحميل ملف تصدير (رابط موقّع) |
| GET | `/super-admin/files/backups/{backup_id}` | تحميل نسخة احتياطية (رابط موقّع) |
| GET | `/super-admin/files/private` | عرض ملف خاص (شعار، إيصال، مرفق) برابط موقّع |
