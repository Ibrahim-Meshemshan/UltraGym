# ultragym_design

حزمة Flutter لهوية UltraGym البصرية: الثيمان، الخطوط المضمّنة، الشعار، العناصر الحركية المرسومة بالكود، الحركات، والمكونات.

التوصيف الكامل وأمثلة الاستخدام في `../../docs/identity-spec.md` (القسمان 9 و 13).

```dart
import 'package:ultragym_design/ultragym_design.dart';

MaterialApp(theme: UltraGymTheme.light, darkTheme: UltraGymTheme.dark, ...);

final c = UGColors.of(context);
Text('مرحباً', style: UType.h2(color: c.ink));
```

تطبيق العرض في `example/` يشغّل كل شيء: الرئيسية، الأعضاء (حالة فارغة)، مكتبة العناصر، المكونات، تطبيق المدرّب، وشاشة الدخول.
على الويب تفتح أي صفحة مباشرة: `?page=home|members|ornaments|components|coach|login&theme=light|dark`.

فُحص بـ `flutter analyze` (بلا ملاحظات) وبُني للويب على Flutter 3.47.6.

`lib/src/tokens.dart` مولّد من `studio/engine.js` بالأمر `node tools/build-flutter.js`. لا تعدّله يدوياً.
