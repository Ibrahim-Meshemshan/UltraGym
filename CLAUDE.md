# UltraGym · الواجهات الأربع

هذا المجلد يحوي أربعة مشاريع Flutter **مستقلة** (كل منها بأصوله و pubspec ونسخة حزمة الهوية وقواعده):

| المجلد | الواجهة | المنصة |
|---|---|---|
| `ultra_gym_admin/` | لوحة النادي (المالك والاستقبال) | Flutter Web |
| `ultra_gym_reception/` | شاشة الاستقبال مع العمل دون اتصال | Flutter Web |
| `ultra_gym_super_admin/` | لوحة المنصة (فريق UltraGym) | Flutter Web |
| `ultra_gym_player/` | تطبيق العضو | Android / iOS |

**قبل أي تعديل على مشروع: اقرأ `CLAUDE.md` داخل مجلده** (يستورد `docs/engineering-rules.md` و `docs/backend-contract.md`)،
ونفّذ الأوامر من داخل مجلد ذلك المشروع. لا تنسخ كوداً بين المشاريع دون التأكد أنه يناسب منصة الهدف.
