# CLAUDE.md · ultra_gym_reception (شاشة الاستقبال)

> **اقرأ هذا الملف كاملاً، والملفين المستوردين أدناه، قبل أي تعديل أو إضافة على المشروع.**
> أي قاعدة هنا تغلب أي Skill أو عادة عامة. إن تعارض طلب مع قاعدة: نبّه صاحب المشروع قبل التنفيذ.

@docs/engineering-rules.md
@docs/backend-contract.md

## ما هو المشروع

- **محطة الاستقبال** على كمبيوتر الاستقبال: بحث، مسح QR، بيع، قبض، صندوق، و**العمل دون اتصال**. **Flutter Web فقط**.
- المستخدم: موظف الاستقبال (`receptionist`) والمالك. ليست باك اند منفصلاً: تستعمل مسارات `/club-admin/*` نفسها، محصورة بفروع الموظف. الخريطة (بالطرق): `docs/api-map.md`، والعقد الدقيق: `docs/api/*.yaml` (الاستقبال يستعمل منها: `reception/*`، `players/lookup`، `players`، `memberships/*`، `membership-plans`، `day-passes`، `attendance/*`، `sessions/*`، `cash-sessions/*`، `transactions`، `branches`، و `/notifications/*`).
- تتطلب ميزة الباقة `offline_reception` (`GET /tenant/entitlements`).
- لوحة الإدارة الكاملة مشروع منفصل: `ultra_gym_admin`. لا تبنِ هنا الإعدادات أو الموظفين أو التقارير.
- الشاشة سريعة ومكثفة للعمل اليومي: نظيفة بلا زخارف (الزخرفة فقط بشاشة الدخول والتجهيز والنجاح)، أهداف كبيرة، واختصارات لوحة مفاتيح (قارئ الباركود يكتب كلوحة مفاتيح ثم Enter).

## التشغيل والبناء

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
flutter build web --release --dart-define=API_BASE_URL=https://api.ultragym.app/api/v1
flutter analyze
```

## الدخول والجلسة

- `POST /auth/login` بـ `{ phone, password, tenant_id?, device_name, app: "reception_web" }` (`AppConfig.loginApp`) ← جلسة **90 يوماً تتجدد** مع الاستعمال (`X-Session-Expires-At`).
- التوكن بـ `localStorage` المتصفح (`shared_preferences` على الويب) لأن الجلسة طويلة.
- `device_name` مثل `الاستقبال 1 · Chrome`.
- لا تبديل نادٍ داخل الجلسة.

## الشاشات والنموذج الأولي

النموذج الأولي المعتمد بـ `docs/ui-prototype/` (افتح `index.html`؛ كل صفحة لها `#dark`). **ابنِ كل شاشة مطابقة لصفحتها**.

| الشاشة | المسارات (`/club-admin/…`) | صفحة النموذج |
|---|---|---|
| الدخول، اختيار النادي، تغيير كلمة السر | `/auth/*` | `Login.html` |
| تجهيز الجهاز (مرة لكل جهاز) | `POST reception/devices`، `GET reception/offline-pack` | `ReceptionSetup.html` |
| محطة الدخول: بحث سريع، مسح QR، كود العضو، بطاقة النتيجة | `GET players/lookup?q=&branch_id=`، `POST attendance/check-in`، `GET attendance/today` | `Reception.html` |
| بيع اشتراك / تجديد | `POST memberships/quote` ثم `POST memberships` | `SellMembership.html` |
| قبض دفعة على اشتراك، خصم جلسة | `memberships/{id}/payments`، `memberships/{id}/sessions` | `MembershipDetail.html` |
| الصندوق: الوردية الحالية، فتح، مصروف/إيراد، إغلاق بالجرد | `cash-sessions/*`، `transactions` | `ReceptionCash.html` |
| الدخول اليومي: بيع لزائر أو عضو بلا اشتراك صالح، سجل اليوم، تفاصيل، إلغاء مع عكس الدفعات (للمالك) | `GET day-passes/price?branch_id=`، `POST day-passes` (+ `Idempotency-Key`)، `GET day-passes`، `GET day-passes/{id}`، `POST day-passes/{id}/cancel` | `SellMembership.html` (بنفس نموذج الدفع) |
| المزامنة دون اتصال، العمليات المعلقة، "عمليات تحتاج مراجعة" | `POST reception/sync` | `ReceptionSync.html` |
| الحالات العامة والجرس | `/notifications/*` | `SystemStates.html` |

## الإعداد مرة لكل جهاز

1. الدخول بـ `app = reception_web`.
2. ولّد `device_uuid` (UUID v4) **مرة واحدة** واحفظه دائماً بالجهاز.
3. `POST club-admin/reception/devices` بـ `{ device_uuid, name, branch_id }`.

## حزمة الأوفلاين (offline pack)

- أول مرة: `GET reception/offline-pack?device_uuid=&limit=1000` ← من الصفحة الأولى احفظ `branch`، `settings`، `plans`، `exchange_rate`، `qr`؛ ومن كل صفحة احفظ `players`، `memberships`، `qr_keys`. إن `meta.cursor.has_more` ← نفس الطلب مع `cursor=next_cursor`. احفظ `generated_at` من الصفحة الأولى = آخر تحديث.
- كل 5 دقائق وهو متصل: نفس الطلب بـ `updated_since=<آخر generated_at>` (مقسّم بنفس الطريقة)؛ طبّق: أضف/حدّث، واحذف `is_removed` والمفاتيح `is_revoked`.
- أشكال السجلات:
  - `players[]`: `{ id, name, phone, member_code, gender, home_branch_id, is_suspended, is_removed }`
  - `memberships[]`: `{ id, player_id, plan_name, type, branch_scope, branch_ids, starts_on, ends_on, status, frozen_until, sessions_total, sessions_used, due_usd }`
  - `qr_keys[]`: `{ player_id, key_id, public_key, is_revoked }`
  - `qr`: `{ prefix: "UG1", valid_seconds: 30, algorithm: "Ed25519" }`، و `mode`، `generated_at`.
  - `day_pass`: `{ enabled, price_usd, today_player_ids }` (سعر الدخول اليومي بالفرع، والأعضاء الذين اشتروا دخولاً يومياً اليوم فيدخلون مجدداً بنفس اليوم).
- **التخزين المحلي**: `sembast` + `sembast_web` (IndexedDB، بلا code generation) بـ `lib/core/offline/`، بمخازن: `players` (فهرس `member_code` و `phone`)، `memberships` (فهرس `player_id`)، `qr_keys` (مفتاح `key_id`)، `outbox` (العمليات المعلقة)، `meta` (device_uuid، generated_at، آخر مزامنة، clockOffset).

## التحقق من الدخول محلياً (نفس منطق الخادم، بالترتيب)

1. **QR**: الصيغة `UG1.{key_id}.{unix}.{sig}`، المفتاح موجود وغير ملغى، التوقيع صحيح، و `|serverNow - unix| ≤ 30` ثانية.
2. دخول مقبول لنفس العضو خلال `settings.duplicate_check_in_minutes` ← "مسجّل مسبقاً".
3. `is_suspended` ← مرفوض `SUSPENDED`.
4. اشتراكات العضو غير الملغاة: فعّال يشمل الفرع (`branch_scope = all` أو الفرع ضمن `branch_ids`)، ثم بأيام السماح (`ends_on + membership_grace_days`)، وإلا السبب: مجمّد (اليوم ≤ `frozen_until`)، قادم، جلسات منتهية، منتهٍ.
5. فرع بأوقات منفصلة: قارن جنس العضو بفترة `branch.gender_schedule` الحالية (بتوقيت النادي).
6. سجّل العملية بالـ `outbox` مع `client_uuid` جديد و `occurred_at = serverNow()`. **المرفوض يُسجَّل أيضاً.**

```dart
import 'dart:convert';
import 'package:cryptography/cryptography.dart';

final _ed = Ed25519();

/// يرجع null إن كان صالحاً، أو رمز السبب.
Future<String?> verifyQr(String token, Map<String, String> publicKeysById, DateTime serverNowUtc) async {
  final p = token.trim().split('.');
  if (p.length != 4 || p[0] != 'UG1' || int.tryParse(p[2]) == null) return 'QR_MALFORMED';
  final ts = int.parse(p[2]);
  if ((serverNowUtc.millisecondsSinceEpoch ~/ 1000 - ts).abs() > 30) return 'QR_EXPIRED';
  final pub = publicKeysById[p[1]]; // غير الملغاة من qr_keys
  if (pub == null) return 'QR_UNKNOWN_KEY';
  final sig = base64Url.decode(base64Url.normalize(p[3]));
  final ok = await _ed.verify(utf8.encode('${p[0]}.${p[1]}.${p[2]}'),
      signature: Signature(sig, publicKey: SimplePublicKey(base64.decode(pub), type: KeyPairType.ed25519)));
  return ok ? null : 'QR_INVALID';
}
```

## المزامنة

`POST club-admin/reception/sync` بـ `{ device_uuid, operations: [...] }` (حتى 500 عملية بالطلب، بترتيب حدوثها). كل عملية `{ client_uuid, type, occurred_at, data }`:

| type | data |
|---|---|
| `check_in` | `{ player_id, method: qr|code|manual, consume_session? }` |
| `consume_session` | `{ membership_id, note? }` |
| `membership_payment` | `{ membership_id, payments: [{ currency, amount }] }` |
| `create_membership` | `{ player_id, plan_id, payments, starts_on?, coupon_code?, trainer_id?, previous_membership_id? }` |
| `day_pass` | `{ player_id? \| visitor_name + visitor_phone?, gender?, payments, price_usd? (المالك فقط), notes? }` |

الرد: نتيجة لكل عملية بنفس `client_uuid`، و `summary { applied, duplicate, rejected, failed }`، و `server_time`:

| status | ماذا تفعل |
|---|---|
| `applied` | احذفها من الـ outbox (وحدّث المحلي بالبيانات الراجعة) |
| `duplicate` | سبق تطبيقها: احذفها |
| `rejected` | لن تنجح أبداً (`code` و `message`): احذفها واعرضها بقائمة "عمليات تحتاج مراجعة" للموظف |
| `failed` | خطأ مؤقت: أبقها وأعد إرسالها لاحقاً بنفس `client_uuid` |

- الدفعات أوفلاين تُقبل حتى لو الصندوق مغلق (المال قُبض فعلاً)، وتُربط بالوردية المفتوحة إن وُجدت.
- وقت مستقبلي (ساعة جهاز خاطئة) يُقص لوقت الخادم: استعمل `serverNow()` دائماً (من `X-Server-Time`).
- بعد المزامنة اطلب `updated_since` لتصحيح أي اختلاف.
- `409 DEVICE_REVOKED` (ألغاه المالك): أوقف الوضع الأوفلاين واطلب تسجيل الجهاز من جديد.

## حالة الاتصال بالواجهة

- شارة دائمة بالشريط العلوي: **متصل** أو **دون اتصال · 12 عملية معلقة** مع وقت آخر مزامنة (`ConnectionCubit` بـ `connectivity_plus` + `internet_connection_checker_plus`).
- **لا تمنع العمل عند الانقطاع**؛ امنع فقط ما لا يعمل أوفلاين: فتح وإغلاق الصندوق، التقارير، الإعدادات (برسالة واضحة).
- متصلاً: العمليات تذهب مباشرة للمسارات العادية مع `Idempotency-Key`؛ عند الانقطاع أو فشل الشبكة تتحول للـ outbox.

## نتيجة الدخول (البطاقة)

201 مقبول ← بطاقة خضراء بالاسم والصورة والأيام المتبقية، وعنبرية إن `in_grace`. `ALREADY_CHECKED_IN` (200) ← "مسجّل منذ…" بلا صوت خطأ. 409 + السبب ← بطاقة حمراء بالرسالة + زر "تجديد" أو "دفع". `QR_*` (422) ← "اطلب من العضو تحديث الرمز". المسح بالكاميرا بـ `mobile_scanner`، وقارئ الباركود/كود العضو بحقل كتابة دائم التركيز.

## الصندوق

`GET cash-sessions/current` عند الفتح ← لا وردية؟ نافذة فتح الصندوق (الرصيد الافتتاحي مقترح) ← `POST cash-sessions` ← العمل ← `POST cash-sessions/{id}/close` بالجرد الفعلي لكل عملة ← تقرير الوردية (PDF بـ `?as=base64`). أي قبض متصل بلا وردية ← `409 CASH_SESSION_REQUIRED`: زر "فتح الصندوق" بنفس الرسالة.

## إشعارات الاستقبال ← الشاشة

`club_membership_cancelled`، `club_reversal`، `club_cash_left_open`، `club_daily_summary` (9:10 صباحاً بتوقيت دمشق)، `club_sync_rejected` (← "عمليات تحتاج مراجعة")، للفرع المسموح فقط (`data.branch_id`).

## الباكجات بهذا المشروع

القائمة المعتمدة (engineering-rules §13) للويب: + `web`، `connectivity_plus`، `internet_connection_checker_plus`، `sembast` + `sembast_web` (القاعدة المحلية)، `cryptography` (Ed25519)، `mobile_scanner` (QR بالكاميرا).

## الأصول

- `packages/ultragym_design`: حزمة الهوية (path dependency). **لا تعدّلها**.
- `assets/brand/`، `assets/icons/` (منها `qr.svg`، `id-card.svg`)، `assets/ornaments/`.

## حالة البناء

- **مبني ومختبر**: core (engineering-rules §16)، والدخول والجلسة والراوتر (§17): الدخول، اختيار النادي، تغيير كلمة السر الإجباري، استعادة الجلسة، الخروج، شاشات لا اتصال / حجب.
- يرسل `app: reception_web` بالدخول (جلسة 90 يوماً)، ويسجّل الجهاز بـ `POST /devices` بعد الدخول وعند كل فتح.
- **مبني ومختبر**: الهيكل (`ReceptionShell`) ومحطة الدخول متصلة (§18): الحقل الدائم التركيز لقارئ الباركود، **مسح QR بكاميرا المتصفح** (`mobile_scanner`)، البحث بالاسم أو الموبايل، بطاقة النتيجة، و "دخول اليوم".
- **التالي**: العمل دون اتصال (تجهيز الجهاز، الحزمة، التحقق المحلي، الـ outbox، المزامنة)، ثم البيع والقبض والصندوق حسب جدول الشاشات.

## الـ Skills المتاحة (`.claude/skills/`)

`ultragym-feature` (**استعمله لكل ميزة**)، `bloc`، `testing`، `accessibility`، `animations`، `flutter-build-responsive-layout`، `flutter-fix-layout-issues`، `flutter-add-widget-test`، `flutter-setup-declarative-routing`، `dart-run-static-analysis`، `dart-resolve-package-conflicts`، `dart-use-pattern-matching`.
**الأولوية**: هذا الملف ← `docs/engineering-rules.md` ← `docs/backend-contract.md` ← الـ Skills.

## قبل أن تنهي أي مهمة

1. `flutter analyze` نظيف.
2. لا `setState`، لا ملف فوق 300 سطر، لا لون/نمط/مسافة/مدة/مسار مكتوب.
3. الحالات الأربع، الثيم الداكن، RTL، والأرقام LTR.
4. جرّب منطق التحقق المحلي بحسابات النادي التجريبي: فعّال، دين، مجمّد، سماح، منتهٍ، جلسات، أوقات منفصلة، و QR منتهٍ.
5. جرّب الانقطاع: العمل يستمر، الـ outbox يمتلئ، والمزامنة تفرغه.
