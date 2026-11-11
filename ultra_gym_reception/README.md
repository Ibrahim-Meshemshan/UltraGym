# UltraGym · شاشة الاستقبال

محطة الاستقبال على كمبيوتر النادي: الدخول بالـ QR والكود، البيع، القبض، الصندوق، والعمل الكامل دون اتصال (حزمة بيانات الفرع + outbox + مزامنة). Flutter Web.

- **الخادم**: UltraGym API (Laravel) · مسارات `/club-admin/*` بدخول `app = reception_web` · التوثيق التفاعلي `http://127.0.0.1:8000/api/documentation`
- **الهوية**: حزمة `packages/ultragym_design` (نسخة محلية، path dependency)
- **التصميم المعتمد**: `docs/ui-prototype/index.html`

## التشغيل

```bash
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
```

## البناء

```bash
flutter build web --release --dart-define=API_BASE_URL=https://api.ultragym.app/api/v1
```

## الستراكشر والقواعد

- `CLAUDE.md`: يُقرأ قبل أي تعديل (وصف المشروع، الدخول، الشاشات، التدفقات).
- `docs/engineering-rules.md`: قواعد الهندسة من «منهجية العمل».
- `docs/backend-contract.md`: عقد الباك اند (الترويسات، الأخطاء، البيانات).
- `docs/api-map.md`: مسارات هذا المشروع.
- `docs/reference/`: الوثيقتان الأصليتان (PDF + نص قابل للبحث).
- `.claude/skills/`: مهارات Claude Code لهذا المشروع.

```
lib/
├── main.dart · app.dart
├── core/      core.dart (barrel) · config · di · error · router · theme · widgets · …
└── features/  <feature>/domain · data · presentation
```
