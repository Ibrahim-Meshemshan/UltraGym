# مصادر الـ Skills

| Skill | المصدر | الرخصة |
|---|---|---|
| ultragym-feature | مكتوبة لهذا المشروع من «منهجية العمل» | — |
| bloc, testing, accessibility, animations | https://github.com/VeryGoodOpenSource/very_good_ai_flutter_plugin (`skills/`) | MIT · Very Good Ventures |
| flutter-build-responsive-layout, flutter-fix-layout-issues, flutter-add-widget-test, flutter-add-integration-test, flutter-setup-declarative-routing | https://github.com/flutter/agent-plugins (`skills/`) | BSD-3 · The Flutter Authors |
| dart-run-static-analysis, dart-resolve-package-conflicts, dart-use-pattern-matching | https://github.com/dart-lang/skills (`skills/`) | BSD-3 · The Dart project authors |

استُبعدت عمداً لتعارضها مع المنهجية: `flutter-implement-json-serialization` (code generation)، `flutter-use-http-package` (المعتمد dio)،
`flutter-apply-architecture-best-practices` (ChangeNotifier/freezed)، VGV `layered-architecture` (حزم منفصلة + RepositoryProvider بدل get_it)،
VGV `navigation` (TypedGoRoute بدل Routes)، VGV `internationalization` (ARB؛ الواجهة عربية فقط).
عند أي تعارض بين Skill وقواعد المشروع: `CLAUDE.md` و `docs/engineering-rules.md` يغلبان.
