# قواعد الهندسة (من «منهجية العمل» مطبّقة على UltraGym)

المصدر: `docs/reference/flutter-methodology-guide.pdf` (نص قابل للبحث: `docs/reference/flutter-methodology-guide.txt`).
قيم الهوية الفعلية من حزمة `packages/ultragym_design` و `docs/brand/identity-spec.md`. عند أي تعارض بين قيمة رقمية بالمنهجية وقيمة بالحزمة: **الحزمة تغلب** (هي المولّدة من tokens الهوية).

## 1. القرارات الثابتة (لا استثناء)

1. **لا `setState` بأي مكان.** كل حالة (حتى إظهار كلمة السر أو التبويب المحدد) بـ Cubit أو Bloc. الحالة المحلية البسيطة بـ `ValueCubit<T>` / `ToggleCubit`.
   الاستثناء الوحيد: `StatefulWidget` داخل ويدجتس البنية (OnInit، Hover، الجدول، Splash) لإدارة دورة الحياة والـ controllers، لا لحالة الشاشة.
2. **لا ملف فوق 300 سطر.** ويدجتس الشاشة تُنقل لـ `widgets/`، الأحداث والحالة بملفات `part`، والمسارات بملفات حسب المجال.
3. **إدارة الحالة `flutter_bloc` فقط.** ممنوع: Provider، GetX، Riverpod، hydrated_bloc (للبيانات)، freezed، json_serializable، retrofit.
4. **لا قيمة تصميم مكتوبة بالواجهة:**
   - لا `Color(0x...)` ← `context.colors.primary` (أو `context.scheme` لما يدخل بالـ ColorScheme).
   - لا `TextStyle(...)` من الصفر ← `UType.body(color: c.ink)`، وأي نمط جديد بـ `copyWith` أو `.weight(600)`.
   - لا أرقام مسافات عشوائية ← `AppSpace.s4` / `AppSpace.gap4`.
   - لا `Duration(milliseconds: ...)` ← `AppMotion.normal`.
   - لا زوايا يدوية ← `AppRadius.*`، والبطاقة دائماً `CutCard` / `CutCardBorder`.
5. **لا مسار مكتوب نصاً داخل شاشة**: كل المسارات من `Routes`.
6. **كل شاشة بأربع حالات**: تحميل بهياكل (Shimmer بشكل المحتوى)، خطأ مع إعادة محاولة، فارغة كدعوة (`EmptyState`)، ومحتوى.
7. **لا استثناء يصل للواجهة**: كل طلب يرجع `ApiResult<T>` (نجاح أو `Failure`).
8. **الواجهة تتصرف حسب `FailureType` / `code`** وليس نص الرسالة.
9. **كل التعديلات من مكان واحد**: `FormDialog` / `AppForm` فوق `AppFormCubit` (تحميل + أخطاء حقول 422 موحّدة).
10. **الميزات تستورد من core ملفاً واحداً**: `import '../../../../core/core.dart';` (الـ barrel يصدّر أيضاً `ultragym_design` و `flutter_bloc` و `equatable`).
11. **عربي فقط، RTL، ثيمان (فاتح وداكن)، الأرقام لاتينية**، والأرقام والمبالغ والهواتف والمعرّفات باتجاه LTR داخل النص (`textDirection: TextDirection.ltr`).
12. **"تقليل الحركة" يُحترم دائماً**: كل حركة تفحص `AppMotion.reduced(context)` (= `UMotion.reduced`).
13. **لا overflow بأي مقاس**: تكبير الخط محصور (`MediaQuery.withClampedTextScaling` في `app.dart`)، وكل شاشة تُجرَّب على عرض 360px.

## 2. الهوية البصرية بالكود

| المنهجية | بهذا المشروع | المصدر بالحزمة |
|---|---|---|
| `context.colors` | `context.colors` (`UGPalette`) | `UGColors.of(context)` |
| `context.scheme` | `context.scheme` | `Theme.of(context).colorScheme` |
| `TType` | `UType.displayXl/displayMd/h1/h2/h3/stat/bodyLg/body/label/caption` | `UType` |
| `AppSpace` | `AppSpace.s1..s16`, `gap1..gap8` | `USpace` |
| `AppRadius` | `AppRadius.xs/sm/field/card/hero/full` + `smAll/fieldAll/cardAll/fullAll` | `URadius` |
| `AppSize` | `control 42 / controlSm 34 / controlLg 50 / topBar 64 / sidebar 264 / sidebarCollapsed 76 / bottomNav 68 / tableRow 52 / maxContent 1320 / minTap 48` | `USize` |
| `AppMotion` | `instant 90 / fast 140 / normal 220 / slow 380 / entrance 520 (+60 لكل عنصر)`، `curve`, `emphasized`, `exit`, `reduced()` , `of()` | `UMotionValues` |
| `Breakpoints` | `UBreakpoints.mobile 600 / tablet 1024 / desktop 1320` | `UBreakpoints` |

- **الألوان (منذ 2026-11-11، بطلب صاحب المشروع)**: ألوان لوحة "Ignara" الدافئة بدل ألوان الهوية، بكل الواجهات الأربع. `core/theme/app_palette.dart` (`AppPalette.light/dark`: قيم الديمو، و `roles` أدوار `UGPalette` معتمة، و `ornaments` ألوان الزخارف بالبرتقالي والعنبري) و `app_theme_data.dart` (نفس بناء `UltraGymTheme` بالحزمة بهذه الأدوار؛ `_build` بالحزمة خاصة). **الحزمة لم تُعدَّل**، والملفان متطابقان بالمشاريع الأربعة (عدّل الأربعة معاً). الزخارف: مرّر `colors: AppPalette.dark.ornaments` (أرضية داكنة) أو `AppPalette.of(context).ornaments`، ولا `UOrnColors.light/dark` (ألوان الهوية القديمة). الحالة الفارغة `AppEmptyState` (`core/widgets`) بدل `EmptyState` الحزمة لأن الحزمة ترسم زخرفتها بلا معامل ألوان. `HeroBanner` الحزمة يرسم زخرفته بألوان الهوية: لا تستعمله. القائمة الجانبية فاتحة بالوضع الفاتح (`sidebar`)، فالشعار عليها `onDark: context.isDark`؛ شاشة البدء والدخول على `hero` الداكنة بالثيمين. التراجع: `AppTheme` يرجع لـ `UltraGymTheme` (نسخة ما قبل التغيير بأول commit بالمستودع).

- **الأدوار اللونية**: `bg`، `surface/surfaceAlt`، `line/lineStrong`، `ink/inkMuted/inkFaint`، `sidebar/sidebarInk/hero` (لون الهيكل)، `primary(+Hover/Soft/Ink/onPrimary)` = الفعل، `accent(+Soft/Ink/onAccent)` = اللمعة/المحدد/الإنجاز، `success/warning/danger/info` بثلاث درجات (قوي، Soft خلفية، Ink نص).
- **لون واحد لكل معنى.** زر أساسي واحد بكل شاشة. الخطر مختلف بوضوح عن الفعل.
- **الشارة دائماً**: خلفية هادئة + نص بالحبر + نقطة (`StatusBadge(label, tone: UTone.x)`). اللون وحده لا يكفي.
- النص فوق البرتقالي **فحمي** (`onPrimary`). الفولت لا يُكتب كنص على الفاتح: `accentInk`.
- **الخطوط**: Changa (`UType.displayXl/displayMd/stat`) للتحيات وشاشة الدخول وعناوين الحالات الفارغة والنجاح والأرقام الكبيرة فقط؛ لا لعناوين الصفحات ولا الأزرار ولا الجداول. Readex Pro لكل شيء آخر. الخطوط مضمّنة بالحزمة. **`AppTheme` يكمّل `textTheme`**: الحزمة تضبط `fontFamily: 'ReadexPro'` بلا بادئة `packages/ultragym_design/`، فالأنماط التي لا تعرّفها (`headlineLarge` برأس منتقي التاريخ، `titleSmall`، `labelSmall`...) كانت تظهر مربعات بالويب؛ `_withPackageFonts` يعطيها خط الحزمة المسجّل، ورأس منتقي التاريخ بـ `UType.h1` (32 يقطع الشهر بالوضع العرضي) (`test/core/theme/app_theme_test.dart`). لا تلفّ الثيم بـ `ThemeData(fontFamily:)` جديد.
- **الزخرفة بمكانها فقط**: الدخول والبدء، بانر الرئيسية (`HeroBanner`)، رأس التطبيق، الحالات الفارغة، النجاح. شاشات العمل (القوائم، الجداول، الفورمات) نظيفة. **مكان مزخرف واحد بالشاشة على الأكثر.**
- **الظلال**: البطاقة بلا ظل ساكنة، ظل خفيف عند المرور (`HoverLift`)، ظل عائم للنوافذ وبطاقة الدخول فقط.
- **الحركة**: لا ارتداد ولا اهتزاز، لا حركة فوق 1.2 ثانية إلا الدائمة البطيئة. مكونات جاهزة: `Entrance(index:)`، `CountUp`، `HoverLift`، `PressScale`، `Shine` (الزر الأساسي)، `PingDot` (الإشعار)، `Breathe`، `SlowSpin`. مع "تقليل الحركة": القيم النهائية فوراً والدائمة تقف.
- **التفاعلات (ماوس/داشبورد)**: مرور + ضغط + تركيز لوحة مفاتيح (حلقة 2px بلون `focus`) + محدد + معطّل (شفافية 45%) لكل عنصر تفاعلي.
- **التفاعلات (لمس/موبايل)**: لا مرور. `PressScale` (0.97) على كل ما يُضغط، `HapticFeedback.selectionClick()` للأفعال المهمة وتبديل التبويب، أهداف ضغط ≥ 48px.
- **إمكانية الوصول**: تباين 4.5:1 للنص و 3:1 للكبير والأيقونات بالثيمين، كل زر أيقونة له `Tooltip`، كل شعار له `semanticsLabel`، الأيقونات الاتجاهية تنعكس، و `EdgeInsetsDirectional` بدل `EdgeInsets.only(left/right)`.
- **مكونات الحزمة أولاً** قبل كتابة أي ويدجت: `UltraGymLogo`، `UGButton`، `StatusBadge`، `SlantTag`، `IconSlab`، `CutCard`، `StatCard`، `SectionCard`، `MemberTile`، `UGSidebar`+`UNavItem`، `UGTopBar`، `SearchPill`، `NotificationBell`، `HeroBanner`، `RepBarChart`، `EmptyState`، `PageHeader`، والزخارف `OrnamentPattern`، `PlateRing`، `TimerDial`، `PulseDivider`، `ChevronDivider`، `TrackBand`، `CornerBracket`.
- **لا تعدّل ملفات `packages/ultragym_design`** (`tokens.dart` مولّد). أي حاجة جديدة تُبنى بـ `lib/core/widgets/` فوق الحزمة.

## 3. اللغة (Microcopy)

- عربية فصحى مبسطة وقصيرة. الأزرار فعل مباشر: "إضافة"، "تسجيل دفعة"، "تجديد"، "حفظ".
- الخطأ: ماذا حدث ثم ماذا تفعل. "رقم الموبايل مسجّل لعضو آخر. ابحث عنه أو استخدم رقماً مختلفاً."
- النجاح قصير بالماضي: "تم الحفظ." (`AppSnackbar.show`).
- الفارغة دعوة لا اعتذار: "لا يوجد أعضاء بعد. أضف أول عضو."
- التحية تحسب الوقت: صباح الخير / مساء الخير (بخط Changa).
- المصطلحات ثابتة: **عضو** (الخادم يسميه `player`)، **اشتراك**، **حصة**، **مدرّب/كابتن**، **فرع**، **تجميد**، **وردية** (= `cash_session`)، **يوم العمل** (`business_date`).
- رسائل الخادم (`message`) عربية جاهزة: تُعرض كما هي.

## 4. ستراكشر المشروع

```
lib/
├── main.dart        GlobalErrorGuard → (موبايل: edge-to-edge، عمودي) → DI → runApp، وأي فشل = StartupFailureApp
├── app.dart         MaterialApp.router: الثيمان، العربية، RTL، ThemeCubit، builder العام
├── core/
│   ├── core.dart    barrel: الميزات تستورد هذا فقط
│   ├── bloc/        Slice، LoadCubit، ListCubit، ValueCubit/ToggleCubit، AppFormCubit، pullRefresh
│   ├── config/      app_config.dart: API_BASE_URL (dart-define)، المهلات، حدود الخط، العنوان، قيمة app
│   ├── di/          injection.dart (البنية) + feature_injection.dart (الميزات)
│   ├── error/       failure، error_handler، validation_translator، global_error_guard
│   ├── layout/      هيكل ما بعد الدخول (AppShell+Sidebar+Topbar أو MobileShell+TabBar)
│   ├── models/      موديلات مشتركة صغيرة (مرجع: id + name)
│   ├── networking/  dio_factory، api_client، api_result، auth_interceptor، list_query، paged
│   ├── network/     (موبايل/استقبال) connection_cubit، connectivity_interceptor، offline_cache_interceptor
│   ├── push/        (موبايل) push_service، push_permission
│   ├── responsive/  Breakpoints، context.isMobile/responsive()، ResponsiveGrid
│   ├── router/      app_router، routes (الثوابت)، nav (open/back)، ملفات مسارات حسب المجال
│   ├── storage/     session_storage، response_cache + cache_store (io/web)
│   ├── theme/       app_theme، app_colors (context.colors)، app_tokens، theme_cubit، (موبايل) system_ui
│   ├── utils/       formatters، json_x، labels، validators، debouncer، launcher، file_pick، blob_opener
│   └── widgets/     كل الويدجتس المشتركة + charts/
└── features/<feature>/
    ├── domain/models/<feature>_models.dart          كل موديلات الميزة (يُقسَّم إن كبر)
    ├── data/repo/<feature>_repository.dart          العقد: abstract interface class
    ├── data/datasources/<feature>_remote_datasource.dart   التنفيذ عبر ApiClient
    └── presentation/
        ├── bloc/     <feature>_bloc.dart + _event.dart + _state.dart (part of)
        ├── screens/
        └── widgets/
```

- ميزة بلا خادم تكتفي بـ `presentation/`.
- ملفات تختلف بين الويب والجهاز بـ conditional export:
  `export 'cache_store_io.dart' if (dart.library.js_interop) 'cache_store_web.dart';`
- **حالة التنفيذ الحالية**: core مبني ومختبر (القسم 16)، والدخول والجلسة والراوتر (القسم 17)، والهيكل (القسم 18). الباقي: الجداول، والميزات.

## 5. الطبقات: من الـ API إلى الشاشة

```
Screen ──event──▶ Bloc ──▶ Repository (interface) ◀── implements ── RemoteDataSource ──▶ ApiClient ──▶ Dio
   ▲                                                                                        │
   └── BlocBuilder ◀──────────── ApiResult<T> (ApiSuccess | ApiFailure(Failure)) ◀──────────┘
```

```dart
abstract interface class ProfileRepository {
  Future<ApiResult<Profile>> get();
  Future<ApiResult<void>> update(Json body);
}

class ProfileRemoteDataSource implements ProfileRepository {
  ProfileRemoteDataSource(this._api);
  final ApiClient _api;
  static const _base = '/profile';

  @override
  Future<ApiResult<Profile>> get() => _api.getObject(_base, fromJson: Profile.fromJson);

  @override
  Future<ApiResult<void>> update(Json body) => _api.put(_base, body: body, parse: Parse.none);
}
```

- **الموديل**: كلاس عادي يمتد `Equatable` مع `factory X.fromJson(Json json)` مكتوب يدوياً (لا code generation). القراءة الآمنة عبر امتداد `json_x`: `json.intv('id')`، `str`، `strOrNull`، `strList`، `date`، `obj`، `asList(raw, fromJson)`. غياب حقل أو تغيّر نوعه لا يرمي استثناء.
- **الحقن (`get_it`)**: `final sl = GetIt.instance;` فقط.
  - `registerSingleton` (يُجهَّز قبل runApp): التخزين، الاتصال، الكاش.
  - `registerLazySingleton`: Dio، ApiClient، ThemeCubit، PushService، المستودعات `registerLazySingleton<XRepository>(() => XRemoteDataSource(sl()))`، وحالة الجلسة (AuthBloc، عدّاد الإشعارات، الشارات).
  - `registerFactory`: Bloc الشاشة (نسخة لكل شاشة، تُغلق مع خروجها).

## 6. إدارة الحالة بلا setState

```dart
enum LoadStatus { initial, loading, success, failure }

class Slice<T> extends Equatable {
  final LoadStatus status; final T? data; final Failure? failure;
  bool get isFirstLoad => (isLoading || isInitial) && data == null; // هياكل رمادية
  bool get isRefreshing => isLoading && data != null;                // المحتوى يبقى ظاهراً
  Slice<T> toLoading(); Slice<T> toSuccess(T v); Slice<T> toFailure(Failure f);
  Slice<T> fromResult(ApiResult<T> r); Slice<T> mapData(T Function(T) f);
}
```

| متى | الأداة |
|---|---|
| قسم يقرأ قيمة واحدة: `load()`، `refresh()` صامت، `patch()` تعديل محلي بعد الحفظ | `LoadCubit<T>(fetch)` |
| قائمة موبايل: الصفحة الأولى، `more()` "عرض المزيد"، `filter(key, value)` يعيد من الأول | `ListCubit<T>(fetch)` |
| بديل `setState` لأي حالة واجهة محلية | `ValueCubit<T>` / `ToggleCubit` |
| أي نموذج أو تأكيد | `AppFormCubit` |
| شاشة فيها أكثر من شريحة أو منطق: أحداث `sealed` + `final class`، وحالة بـ `copyWith` | `Bloc` كامل |
| طلب أول تحميل من Bloc موجود أعلى الشجرة عند دخول الشاشة | `OnInit` |
| السحب للتحديث ينتظر حتى تهدأ حالة الـ Bloc | `pullRefresh(bloc, trigger)` |
| متابعة مرور الماوس وبناء العنصر حسبه | `Hover` |

```dart
class AdminsBloc extends Bloc<AdminsEvent, AdminsState> {
  AdminsBloc(this._repo) : super(const AdminsState()) {
    on<AdminsListRequested>(_onList);
    on<AdminsListRefreshed>((e, emit) => _onList(AdminsListRequested(state.query), emit));
  }
  Future<void> _onList(AdminsListRequested e, Emitter<AdminsState> emit) async {
    emit(state.copyWith(query: e.query, list: state.list.toLoading()));
    emit(state.copyWith(list: state.list.fromResult(await _repo.list(e.query))));
  }
}
```

- كل حالة Bloc تتكون من شريحة أو أكثر (`Slice<Details> details`، `Slice<Paged<Item>> list`). البيانات السابقة تبقى أثناء إعادة التحميل.
- الأحداث بصيغة الماضي: `XRequested`، `XRefreshed`، `XSubmitted`.
- لا Bloc يعتمد على Bloc آخر مباشرة: التواصل عبر الواجهة أو المستودع.

## 7. الشبكة والأخطاء (الجانب الذي يبنيه التطبيق)

- **Dio واحد** (`DioFactory`): `BaseOptions` من `AppConfig` (الرابط، المهلات)، `Accept: application/json`، و `listFormat: ListFormat.multiCompatible` (مصفوفات لارافيل `ids[]=1`).
- **ترتيب interceptors**: موبايل/استقبال: الكاش ← فحص الاتصال ← التوكن. الداشبورد: التوكن فقط. بالـ debug سطر واحد لكل طلب: `[API] GET /path -> 200`.
- **`ApiClient` واجهة الطلبات الوحيدة**: `get / post / put / patch / delete / upload` مع `parse`، ومختصرات `getObject`، `getList`، `getPaged` (يرجع `Paged<T>` = عناصر + `Pagination` + `summary` + `meta`)، `getWithMeta`، و `getBytes / postBytes` للملفات (بالويب `?as=base64`). محوّلات `Parse.none`، `Parse.json`، `Parse.object`، `Parse.field`، `Parse.intField`.
- ```dart
  sealed class ApiResult<T> { dataOrNull; failureOrNull; when(success:, failure:); map(); }
  final class ApiSuccess<T> extends ApiResult<T> { final T data; final String? message; }
  final class ApiFailure<T> extends ApiResult<T> { final Failure failure; }
  ```
- `FailureType` يطابق حقل `code` الثابت بالباك (جدول `docs/backend-contract.md`) مع احتياط من رقم الحالة (401، 403، 404، 409، 422، 429، 503، 5xx) وأخطاء الشبكة المحلية (network، timeout، cancelled).
- `ErrorHandler.handle` يحوّل أي استثناء (Dio، Format، Type) لـ `Failure` برسالة عربية.
- `validation_translator` يترجم رسائل لارافيل الإنجليزية الافتراضية للعربية. `failure.fieldError('owner')` يدعم المفاتيح المتداخلة.
- `AuthInterceptor`: يضيف `Bearer`، ويحوّل أخطاء الجلسة (401، حساب موقوف، تغيير كلمة سر إجباري) لأحداث `SessionEvent` يستمع لها `AuthBloc` فيعيد الراوتر التوجيه فوراً. أخطاء طلب الدخول نفسه تُعرض بالنموذج.
- `GlobalErrorGuard`: أي خطأ غير ملتقط يُسجَّل ويرى المستخدم رسالة عربية.

## 8. الكاش والجلسة

- الكاش على مستوى HTTP (interceptor) وليس الـ Bloc. لا `hydrated_bloc` لبيانات الخادم.
- `OfflineCacheInterceptor` (للقراءة فقط): يخزّن `GET` بـ JSON فقط (ليس فيه `extra[skip]` ولا `as=base64`)؛ المفتاح بصمة FNV-1a لـ `token | uri`؛ يرسل `If-None-Match` بالـ ETag، و 304 = النسخة المحفوظة؛ دون اتصال يرجع آخر نسخة كـ 200 مع `extra[fromCache]=true` ويسجّل "آخر تحديث قبل..."؛ الكتابة تحتاج اتصالاً (`ConnectivityInterceptor` يرفضها فوراً برسالة واضحة).
- `CacheStore (io)`: ملف JSON لكل رد بـ `getApplicationSupportDirectory()/api_cache`، حد 400 رد ويحذف الأقدم كل 40 كتابة، لا يحفظ رداً أكبر من 1.5MB، وأي خطأ قرص يُتجاهل. `CacheStore (web)`: localStorage للمعاينة فقط.
- الكاش يُمسح مع الجلسة (خروج، انتهاء، إيقاف حساب) عبر `SessionStorage(onClear: cache.clear)`.
- `ConnectionCubit`: `connectivity_plus` لتغيّر الشبكة فوراً + `internet_connection_checker_plus` للتأكد من الإنترنت الفعلي، يعيش طوال عمر التطبيق، وأي فشل شبكة يطلب `recheck()`. `OfflineBanner` فوق كل الشاشات، وعودة الاتصال تحدّث الشاشات وحدها.
- التوكن: موبايل `flutter_secure_storage` ويُقرأ قبل runApp؛ الويب `shared_preferences` (والتفاصيل حسب الواجهة بـ CLAUDE.md). التفضيلات (الثيم) بـ `shared_preferences`.

## 9. الراوتر والتنقل

- `go_router` مع `refreshListenable` من stream الـ `AuthBloc`، و `redirect` حسب `AuthStatus`: `unknown` ← splash، `unauthenticated` ← login، `offline`، `passwordChangeRequired` ← تغيير كلمة السر إجبارياً، `authenticated`.
- الصفحة المطلوبة تُحفظ بـ `?from=` أثناء التحقق أو الدخول ويعود لها المستخدم بعده.
- `Routes`: ثوابت + دوال للمسارات ذات المعرّف (`Routes.child(base, id)`، `Routes.isoDate`).
- `blocRoute<B>(path, create:, child:)`: صفحة مع Bloc خاص يُنشأ عند فتحها ويُغلق عند مغادرتها، مع `idOf(state)` و `paramOf(state, name)`.
- الانتقال العام `fadePage` (تلاشٍ بمدة `AppMotion.slow`، موجود بـ `core/router/app_router.dart`).

## 10. التحميل والحالات الأربع

```dart
SliceView<T>(
  slice: state.details,
  loading: const DetailsShimmer(),   // هيكل بنفس شكل المحتوى
  onRetry: () => bloc.add(const DetailsRequested()),
  isEmpty: (d) => d.items.isEmpty,
  empty: EmptyState(...),            // دعوة لا اعتذار
  builder: (context, data) => DetailsView(data),
)
```

- أول تحميل: هياكل رمادية مطابقة لشكل المحتوى (`AppShimmer` يحرك كل `ShimmerBox` بلون `surfaceAlt`، والبطاقة الهيكلية حدّ بلا تعبئة). **لا `CircularProgressIndicator` بوسط الشاشة.**
- إعادة التحميل: المحتوى يبقى بشفافية 0.55 + شريط تقدّم رفيع 2px بالأعلى، والضغط معطّل مؤقتاً.
- خطأ بلا بيانات: `ErrorState(failure, onRetry)` (وحالة "لا اتصال" الموحّدة إن كان السبب الشبكة). خطأ مع بيانات سابقة: تبقى البيانات.
- التبديل بين الحالات `AnimatedSwitcher` بمدة `AppMotion.normal`، والمحتوى يدخل بـ `fadeIn` من `flutter_animate`.

## 11. النماذج والتحقق

- أسماء الحقول بصيغة لارافيل المنقّطة (`owner.phone`) لتطابق مفاتيح أخطاء 422، و `form.payload` / `apiBody()` يحوّلها لشكل متداخل.
- `AppFormCubit`: controllers النصوص تُنشأ عند الطلب (`form.text(name)`) وتُتلف معه، وغير النصية بـ `set(name, value)`. `submit(send)`: تحقق محلي ← إرسال ← توزيع أخطاء 422 على الحقول، وأخطاء حقول غير ظاهرة أعلى النموذج (`orphanErrors`)، والفشل العام (409، شبكة) أعلاه.
- `apiBody(keepNulls:, dateTimes:, except:)`: التواريخ `2026-10-07` أو ISO كامل لحقول محددة، واستبعاد حقول.
- الحقول: `FormText`، `FormPassword` (إظهار/إخفاء بـ Cubit)، `FormDropdown`، منتقي التاريخ، الاختيار المتعدد برقائق، `FormFile`، داخل `FormColumn`. خيارات القوائم من الخادم بـ `OptionsLoader`.
- `Validators` برسائل تقول المطلوب مباشرة: `required('اكتب اسمك.')`، `email()`، `newPassword()`.
- نوافذ التأكيد (حذف، إيقاف، خروج من كل الأجهزة، عكس حركة) = `FormDialog` بلا حقول مع `danger: true`.
- بعد الحفظ: `AppSnackbar` ثم تحديث صامت (`XRequested(silent: true)`).

```dart
final done = await FormDialog.show<void>(
  context,
  title: 'تعديل بياناتي',
  icon: Icons.person_rounded,
  initial: {'name': profile.name, 'email': profile.email},
  fields: (_) => FormColumn(children: [
    FormText('name', label: 'الاسم', required: true, validator: Validators.required('اكتب اسمك.')),
    FormText('email', label: 'البريد الإلكتروني', ltr: true, validator: Validators.email()),
  ]),
  onSubmit: (form) => sl<ProfileRepository>().update(form.apiBody(keepNulls: true)),
);
if (done != null && context.mounted) context.read<ProfileBloc>().add(const ProfileRequested(silent: true));
```

## 12. التسمية والكود

- الملفات `snake_case` بلاحقة دورها: `_screen`، `_bloc`، `_event`، `_state`، `_cubit`، `_repository`، `_remote_datasource`، `_models`.
- الكلاسات المساعدة الثابتة `abstract final class` (Routes، AppSpace، ErrorHandler، Parse...).
- تعليقات التوثيق `///` بالعربية بأعلى كل كلاس: ماذا يفعل ولماذا، وليس كيف.
- `Labels`: ترجمة قيم الـ API الثابتة (الحالات والأنواع) لنص عربي + لون (`UTone`) + أيقونة بمكان واحد، والمصطلحات ثابتة بكل الواجهات.
- `Formatters`: الأرقام لاتينية، والتواريخ `2026-10-07`.
- بعد أي `await` بالشاشة: `if (!context.mounted) return;`، وبالـ Cubit: `if (isClosed) return;`.
- `analysis_options.yaml`: `flutter_lints` + `page_width: 120`. `flutter analyze` يجب أن يبقى نظيفاً.

## 13. الباكجات المعتمدة

كل المشاريع: `flutter_bloc` + `equatable`، `get_it`، `go_router`، `dio`، `shared_preferences`، `shimmer`، `flutter_animate`، `fl_chart`، `flutter_svg`، `intl` + `flutter_localizations`، `file_picker`، `url_launcher`، `uuid` (Idempotency-Key)، `timezone` (توقيت النادي)، `flutter_lints`.
الويب: `web` (blob والتنزيل). الموبايل: `flutter_secure_storage`، `path_provider` + `open_filex`، `connectivity_plus` + `internet_connection_checker_plus`، `webview_flutter`، `app_settings`، `flutter_launcher_icons` / `flutter_native_splash`، ولاحقاً `firebase_core` + `firebase_messaging` + `flutter_local_notifications`.
**لا تضف باكجاً خارج هذه القائمة (وقائمة CLAUDE.md للمشروع) دون سؤال صاحب المشروع.** إن ظهر تعارض نسخ بالأندرويد: ثبّت النسخة بـ `dependency_overrides`.

## 14. قائمة البدء: ميزة جديدة

1. `domain/models/x_models.dart`: الموديلات بـ `fromJson` عبر `json_x`.
2. `data/repo/x_repository.dart`: العقد.
3. `data/datasources/x_remote_datasource.dart`: التنفيذ عبر `ApiClient`.
4. التسجيل بـ `feature_injection.dart` (المستودع lazySingleton، الـ Bloc factory).
5. `presentation/bloc/`: Bloc بشرائح `Slice` (أو `LoadCubit` / `ListCubit` إن كفى).
6. المسار بـ `Routes` + `blocRoute`.
7. الشاشة: `AppPage` + `SliceView` / `PagedTable` بحالاتها الأربع، والهيكل الرمادي بشكل المحتوى.
8. التعديلات بـ `FormDialog`، والتحديث بعدها صامت.
9. مراجعة: لا `setState`، لا ملف فوق 300 سطر، لا قيمة تصميم أو مسار مكتوب، الثيم الداكن، شاشة 360px بلا overflow، و `flutter analyze` نظيف.

## 15. قائمة البدء: البنية (قبل أول ميزة، مرة واحدة)

`core/networking` (DioFactory، ApiClient، ApiResult، AuthInterceptor، ListQuery، Paged) ← `core/error` (Failure، FailureType، ErrorHandler، validation_translator) ← `core/storage` (SessionStorage) ← `core/bloc` (Slice وأدواته) ← `core/utils` (json_x، formatters، labels، validators، debouncer) ← `core/widgets` (SliceView، AppShimmer، ErrorState، FormDialog...) ← ميزة auth (splash، login، change password، offline) ← الهيكل (Shell) ← الميزات.

## 16. مرجع core الفعلي (استعمله كما هو، لا تعِد كتابته)

كل ما يلي يصدّره `core/core.dart`. الاختبارات في `test/core/` تثبّت سلوكه؛ أي تعديل بـ core يتبعه `flutter test`.

**الشبكة**
- `sl<ApiClient>()`: `get<T>(path, parse:, query:)`، `post / put / patch (path, parse:, body:, idempotencyKey:)`، `delete`، `upload(path, form:, parse:)`، `getObject(path, fromJson:)`، `getList`، `getPaged(path, fromJson:, query: ListQuery, extra:)` ← `Paged<T>`، `getWithMeta` ← `(T, Json meta)`، `getBytes / postBytes` ← `FileBlob` ثم `BlobOpener.open(file)`.
- `Parse.none`، `Parse.json`، `Parse.object(fromJson)`، `Parse.list(fromJson)`، `Parse.field('membership', Membership.fromJson)`، `Parse.intField('id')`، `Parse.strField('token')`.
- `Idempotency.newKey()`: ولّده عند ضغط الزر واحفظه بحالة الـ Bloc/النموذج حتى ينجح الطلب.
- `ApiSuccess(data, message, meta, cachedAt)` (`fromCache` = من الكاش دون اتصال)، `ApiFailure(failure)`، و `result.when(success:, failure:)`.
- `Failure`: `type` (`FailureType`)، `code` (رمز الأعمال كما هو: `failure.hasCode('CASH_SESSION_REQUIRED')`)، `message`، `fieldErrors`، `fieldError('owner')`، `feature`، `retryAfter`، `isNetwork`، `isSession`.
- `RequestFlags.skipAuth` / `authRequest` / `skipCache` عبر `Options(extra: {...})` (طلب الدخول يرسل `authRequest: true`).
- `sl<SessionEvents>().stream` ← `SessionEvent.expired / passwordChangeRequired / accountSuspended / tenantBlocked` (يستمع لها AuthBloc).
- `sl<ServerClock>().now()` = `serverNow()` (QR، الأوفلاين، وقت العمليات).
- `sl<SessionStorage>()`: `token`، `hasToken`، `save(token)`، `clear()` (يمسح الكاش معه بالموبايل).
- (موبايل/استقبال) `sl<ConnectionCubit>()`: `isOnline / isOffline`، `recheck()`، `onReconnected` (يفحص `/ping` بالخادم نفسه).

**الحالة**
- `Slice<T>` + `LoadCubit<T>(fetch)` (`load / refresh / patch`) + `ListCubit<T>((query) => repo.list(query))` (`load / refresh({keepPage}) / more / goTo(page) / filter / search / clearFilters / query / patchItems`؛ `more` للموبايل و `goTo` للجدول، والحالة `ListState`: `slice`، `query`، `loadingMore`، `moreFailure`، `canLoadMore`).
- `ValueCubit<T>` (`set / update`)، `ToggleCubit` (`toggle`)، `pullRefresh(bloc, () => bloc.add(...), busy: (s) => s.list.isLoading)`.
- `AppFormCubit(initial:)` (كل القيم الأولية بالحالة، فالقائمة المنسدلة بقيم نصية كالجنس تظهر بقيمتها، والحقل النصي يغلبها بالجسم): `text(name)`، `set(name, v)`، `value(name)`، `apiBody(keepNulls:, dateTimes:, except:)`، `payload`، `orphanErrors`، `submit((form) => repo.x(form.apiBody()))`.

**الواجهة**
- `SliceView<T>(slice:, loading:, builder:, onRetry:, isEmpty:, empty:, frame:)`، `ErrorState(failure:, onRetry:, compact:)`.
- الهياكل: `AppShimmer` + `ShimmerBox` / `ShimmerBox.circle` / `ShimmerCard`، وجاهزة: `ListShimmer`، `TableShimmer`، `StatsShimmer`، `DetailsShimmer`.
- النماذج: `FormDialog.show<R>(context, title:, fields: (form) => FormColumn(...), onSubmit:, initial:, icon:, submitLabel:, successMessage:, danger:)` يرجع `ApiSuccess<R>?`، و `FormDialog.confirm(context, title:, message:, confirmLabel:, onConfirm:)`. الحقول: `FormText(name, label:, required:, validator:, ltr:)` (`ltr` يجعل النص والتلميح LTR)، `FormPassword`، `FormDropdown<T>(name, label:, options: [(value: 1, label: '...')])`، `FormDate`، `FormChips<T>`.
- الجداول: `PagedTable<T>(state: ListState, columns: [TableCol('العضو', flex:, width:, cell: (c, row) => ...)], onPage: cubit.goTo, onRetry:, empty: EmptyState(...), header: FilterBar(...), mobileItem:, onRowTap:, onClearFilters:, noun: 'عضوًا')` = بطاقة `CutCard` فيها الفلاتر + `SliceView` + `AppDataTable` (تمرير أفقي تحت `AppSize.tableMin` 980) + `PaginationBar` ("عرض 1–15 من N"، أرقام مع … عبر `pageWindow`، والموبايل سابق/تالي بأهداف 48). فارغ مع فلاتر = `NoResults` بزر مسح.
- الفلاتر: `FilterBar(search:, onSearch:, hint:, filters: [...], chips:, onClear:)` (البحث `SearchField` بـ `Debouncer` 400ms، و "مسح الفلاتر" يظهر فقط مع فلتر)، `FilterMenu<T>(label:, options:, value:, onChanged:, showAll:)` ("الفرع: الكل ▾"؛ `showAll: false` بلا "الكل")، `FilterToggle` ("عليه دين")، `FilterChoiceChips<T>` (رقائق `.chip`، "الكل" = null). `AppTabs(tabs: [(label:, count:)], selected:, onSelect:)`.
- `CredentialsDialog.show(context, title:, lines: [(label:, value:)], note:, validUntil:, whatsappPhone:, whatsappText:)` (`validUntil` سطر مستقل LTR: تاريخ داخل جملة عربية قد ينكسر بين سطرين): بيانات دخول مرة واحدة، نسخ لكل سطر و "نسخ الكل" وزر واتساب برسالة الخادم.
- `IdempotencyKeeper().keyFor(body)`: نفس الجسم = نفس المفتاح، وجسم معدّل بعد 422 = مفتاح جديد (الخادم يحفظ رد 422 ويرفض نفس المفتاح بجسم مختلف `IDEMPOTENCY_KEY_REUSED`). استعمله بكل نموذج إنشاء.
- `FormErrorBanner` (أعلى كل `FormDialog`): فشل بـ `CASH_SESSION_REQUIRED` يعرض زر "فتح الصندوق" تحت الرسالة (يغلق النافذة إن كان داخل نافذة، ويفتح `Routes.cashSessions`)، فلا حاجة لمعالجته بكل نموذج قبض أو صرف.
- `OnInit(onInit: (context) => ..., child:)`، `LtrText('$25.00')`، `AppSnackbar.show('تم الحفظ.')`.
- `context.isMobile / isTablet / isDesktop`، `context.responsive(mobile:, tablet:, desktop:)`، `context.pagePadding`، `ResponsiveGrid(children:)`.

**الأدوات**
- `Formatters`: `usd`، `syp`، `money(v, currency)`، `number`، `date(d, fromUtc:)`، `time`، `dateTime`، `relative(utc, now: sl<ServerClock>().now())`، `days(n)`، `count(n, one, two, few, many:)`، `greeting(utc)`، `dayTitle(d)` ("الأحد 8 تشرين الثاني")، `dayMonth(d)` ("23 تشرين الثاني")، `weekday(d)`، `ltr(v)` (يعزل تاريخاً أو `#12` داخل جملة عربية فلا ينقلب)، و `Formatters.setTimezone(tenant.timezone)` بعد الدخول. السالب بالدولار `-$1.62`.
- `Labels.membershipStatus(status).tone` (و `attendance`، `direction`، `cashSession`، `difference`، `tenantSubscription`، `invoice`، `alertLevel`، `role`، `gender`، `currency`).
- `Validators.required / email / phone / minLength / newPassword / matches / amount / all`، `Debouncer`، `Launcher.url / phone / whatsapp`، `FilePick.image()` ← `PickedUpload` (`form('photo')` أو `error`).

**لم يُبنَ بعد (الخطوة التالية)**: `blocRoute`، `RowActions` / `DetailDialog` / `ExportDialog`، `OptionsLoader`، `FormFile`، والرسوم (`TrendChart`، `BarsChart`).

## 17. الدخول والجلسة (مبني ومختبر)

`features/auth/` + `core/router/app_router.dart`. الاختبارات في `test/features/auth/`.

- **`AuthBloc`** (lazySingleton، مُقدَّم أعلى `MaterialApp`): مصدر حالة الجلسة الوحيد. `AuthStarted` عند التشغيل (من `main.dart`) ← فحص النسخة (تطبيق العضو) ← لا توكن = `unauthenticated` ← `GET {authBase}/me`.
  - الحالات: `unknown` (splash)، `updateRequired`، `unauthenticated`، `passwordChangeRequired`، `offline` (تعذّر الخادم والتوكن باقٍ)، `blocked` (النادي أو اشتراكه موقوف)، `authenticated`.
  - يستمع لـ `SessionEvents`: 401 ← مسح محلي + الدخول برسالة "انتهت الجلسة"، حساب موقوف ← مسح + رسالة، تغيير كلمة سر إجباري ← شاشته، نادٍ محجوب ← شاشة الحجب.
  - الأحداث: `AuthStarted`، `AuthLoggedIn(session)`، `AuthPasswordChanged`، `AuthRefreshed` (تحديث `me` بصمت)، `AuthLogoutRequested`.
  - الجلسة: `context.select<AuthBloc, Session?>((b) => b.state.session)` ثم `session.isClubOwner / isReceptionist / isPlatformOwner / canViewFinance / canManageStaff / can('...') / tenant / memberCode / isImpersonated / canSwitchTenant`. **أخفِ ما لا يُسمح به حسبها.**
- **الراوتر**: `buildRouter(authBloc)` بـ `refreshListenable` و `authRedirect(status, uri)` (دالة نقية مختبرة). الصفحة المطلوبة تُحفظ بـ `?from=` (مسارات داخلية فقط). أي مسار جديد بعد الدخول يُضاف للـ `routes` ولا يحتاج حماية إضافية: الحماية مركزية بالـ redirect.
- **`AuthRepository`** (`AuthRemoteDataSource`): `login(phone, password, tenantId?)` يحفظ التوكن ويرجع `LoginSucceeded(session)` أو `LoginNeedsTenant(tenants)`، `me()`، `changePassword(body)`، `logout()` (الخادم ثم مسح محلي دائماً)، `clearLocal()`، `registerDevice()` (`POST /devices` حين `AppConfig.platformApp` غير فارغ)، `checkVersion()` (`/app-version`، تطبيق العضو فقط). طلبات الدخول تُرسل بـ `RequestFlags.authRequest` فأخطاؤها تبقى بالنموذج.
- **`AppConfig`**: `authBase` (`/auth` أو `/super-admin/auth`)، `loginApp` (`app` بطلب الدخول)، `platformApp` (`/devices` و `/app-version`)، `appVersion`، `persistentWebSession`.
- **الشاشات** (`presentation/screens`): `LoginScreen` (+ `LoginCubit` factory: البيانات ← اختيار النادي)، `ChangePasswordScreen` (إجبارية)، `OfflineScreen`، `BlockedScreen`، `UpdateRequiredScreen`. كلها فوق `AuthScaffold` (أرضية داكنة بالثيمين + نقش السرعة + قرص + شريط، بطاقة `SlantFrameBorder` بظل عائم) و `GateMessage` لشاشات البوابة. النصوص الخاصة بالواجهة في `presentation/auth_copy.dart`.
- بعد الدخول يذهب المستخدم لـ `Routes.dashboard` (أو `from`).
- **اختبار ويدجت فيه زخارف دائمة**: لُف التطبيق بـ `MediaQuery(disableAnimations: true)` حتى يستقر `pumpAndSettle`، ولا تنتظر `bloc.stream` داخل `testWidgets` (لا يكتمل بالزمن الوهمي): افحص `bloc.state` بعد `pumpAndSettle`.

## 18. الهيكل (مبني ومختبر)

`core/layout/` + `ShellRoute` في `app_router.dart`. الاختبارات في `test/core/layout/app_shell_test.dart`.

- **`AppShell(location, child)`**: ≥1024 قائمة 264 تُطوى لـ 76 بزر الشريط (`ToggleCubit`)، 600-1024 مطوية دائماً (أيقونات + تلميحات)، <600 درج يفتحه زر "القائمة" ويُغلق بعد الاختيار. فوق المحتوى: `AppTopBar` ثم `SupportBanner` (جلسة دعم، ثابت لا يُخفى).
- **`nav_config.dart`**: `AdminNav.groups` (الرئيسية، التشغيل، المالية، النادي، الإدارة كما بـ `Dashboard.html`)، `NavEntry(route, label, icon, allowed:, receptionLabel:)`، `visibleFor(session)` (يخفي المجموعات الفارغة)، `entryFor(path)` (يطابق الصفحات الفرعية `/members/12`). **قسم جديد** = ثابت بـ `Routes` + `NavEntry` هنا + شاشته بـ `_sectionPage` في `app_router.dart`.
- **الحماية**: `sectionGuard(auth, entry)` على كل مسار قسم: لا تسمح الجلسة ← `Routes.dashboard`.
- **`AppSidebar`**: داكنة بالثيمين، الشعار، عناوين المجموعات، `NavTile` (مرور، تركيز، محدد بشريط برتقالي)، والحساب بالأسفل (الاسم، الدور، الخروج). لا نستعمل `UGSidebar` لأنه بلا مجموعات ولا تمرير. ألوانها بـ `SidebarInk`.
- **`AppTopBar(title, leading, actions)`**: العنوان من القسم الحالي، ثم `actions`، ثم `ThemeToggle`. الأزرار `TopBarIconButton` بتلميح إلزامي، والحبوب `TopBarPill(icon, label, dropdown:, compact:)`. الـ `actions` الآن: `BranchPicker` + `CashStatusBadge` (من `features/branches`) + `QuickSearchButton` + `NotificationsButton`. الموبايل: محدد الفرع (أيقونة) + الجرس فقط.
- **البحث السريع** (`features/quick_search`): حبة "ابحث عن عضو..." (`TopBarPill(muted:, maxWidth:, trailing:)`) داخل `Flexible` على الكمبيوتر، تصير زر أيقونة إن ضاق الشريط أو على التابلت، ومخفية بالموبايل. Ctrl K / ⌘ K من أي مكان بالهيكل (`QuickSearchHotkey` يلف الهيكل بمعالج `HardwareKeyboard`، **لا `CallbackShortcuts`**: بالويب قد لا يكون أي عنصر مركّزاً فلا يصل الاختصار؛ ولا يعمل والنافذة فوق الهيكل). النافذة `QuickSearchDialog` + `QuickSearchCubit` (factoryParam بـ `branchId` الحالي، انتظار `AppConfig.searchDebounce`، حرفان على الأقل، يتجاهل رداً قديماً) ← `GET club-admin/players/lookup?q=&branch_id=`. النتيجة `LookupTile`: الحالة والدين وسبب منع الدخول كما من الخادم؛ الضغط (أو Enter لأول نتيجة) يفتح `/members/{id}`. `QuickSearch.pick(context)` يفتح النافذة نفسها لاختيار عضو (يرجع `LookupPlayer?` بدل فتح الملف).
- **الجرس** (`features/notifications`): `UnreadCountCubit` بعمر الهيكل (`start()`: طلب فوري + كل `AppConfig.unreadPollInterval` + `AppLifecycleListener` يوقفه حين تختفي الواجهة؛ `refresh()` بعد أي عملية، `decrement()`، `clear()`). `NotificationsButton` بعدّاد فولت يفتح قائمة عائمة تحته (`showDialog` بلا تعتيم؛ **لا `MenuAnchor`**: يقيس ارتفاع المحتوى ولا يقبل قائمة). `NotificationsPanel` + `NotificationsListCubit` (يُنشأ مع كل فتح، 10 بالصفحة، "عرض المزيد"، `markRead` / `markAllRead`). فتح الإشعار: يعلّمه مقروءاً ثم `NotificationLinks.route` (`screen` + معرّفات `data`)، والأيقونة والنغمة `NotificationLinks.look` حسب `type`.
- **صفحة العنصر**: كل قسم له مسار فرعي `:id` (`/members/12`) يعرض `PendingSection` حتى تُبنى شاشة التفاصيل (`_itemPage` في `app_router.dart`؛ الأعضاء مبنية).
- **الفرع الحالي**: `BranchScopeCubit` (factoryParam بمفتاح `branch.<tenant>.<user>`) يقدّمه `AppShell` ويحمّل `GET club-admin/branches?per_page=100`. الحالة `BranchScope`: `active`، `selected`، `branchId` (null = كل الفروع)، `canChoose`، `openCashCount`. `select(id)` يحفظ، و `refresh()` صامت. اختبار أي ويدجت تحت `AppShell` يسجّل `BranchScopeCubit` بـ GetIt مع `FakeBranchesRepository` (`test/features/branches/`).
- **`AppPage(children:, scroll:)`** (من `core.dart`): أقصى عرض 1320 من طرف البداية، هوامش `pagePadding`، فراغ 20 بين الأجزاء. عنوان القسم بالشريط فلا تكرره. `PendingSection(title:)` للأقسام غير المبنية.

## 19. الرئيسية (مبنية ومختبرة)

`features/dashboard/`. الاختبارات في `test/features/dashboard/` (النموذج والـ Cubit، والشاشة عبر `ShellHarness` بـ `at: Routes.dashboard`).

- **البيانات**: `DashboardRepository.summary(branchId:)` ← `GET club-admin/dashboard` (`DashboardData`: `players`، `memberships`، `attendance`، `debts`، `cashBoxes`، `finance?` للمالك فقط، `alerts`)، و `expiring(branchId:)` ← `GET club-admin/memberships?expiring_within_days=7&sort_by=ends_on&sort_dir=asc&per_page=5`.
- **`DashboardCubit`** (factoryParam بـ `branchId`): شريحتان `summary` و `expiring` بطلبين متوازيين، وفشل القائمة لا يُسقط الصفحة؛ `load()`، `refresh()` صامت، `retryExpiring()`. `DashboardScreen` ينتظر استقرار `BranchScopeCubit` (لا طلب مرتين) ثم ينشئ Cubit بمفتاح الفرع (تغيير الفرع = Cubit جديد).
- **الترتيب** (`Dashboard.html`): `DashboardHero` (يوم العمل `Formatters.dayTitle`، التحية، أرقام اليوم؛ الأزرار فقط حين العرض ≥ `AppSize.heroActions` لأن `HeroBanner` ثابت الارتفاع ويحجز 230 للزخرفة) ← `DashboardStats` (4 `AppStatCard`) ← `DashboardSplit(first:, second:)` (متجاورتان من `AppSize.splitMin`): `FinanceCard` + `CashBoxesCard`، ثم `AlertsCard` + `ExpiringCard`. الغائبة (لا `finance` للاستقبال، لا تنبيهات) تترك الأخرى بكامل العرض.
- **`AppStatCard`** (`core/widgets`): `StatCard` الحزمة مع `decimals` و `note` / `noteTone`، لأن المبالغ تُعرض بخانتين.
- **`RevenueBars`** (داخل الميزة) بدل `RepBarChart`: الحزمة تخفي القيم حتى المرور ويفيض أطول عمود 4px. هنا القيم ظاهرة دائماً والعمود يأخذ الباقي (`Flexible` + `FractionallySizedBox`).
- **التنبيهات**: `dashboardAlertLook(type, owner:)` ← أيقونة ونغمة ورابط (`exchange_rate_missing` للمالك ← سعر الصرف `Routes.exchangeRate`، `cash_session_closed` ← الصندوق، `memberships_expiring` ← `DashboardLinks.expiring`)، والنص `message` كما هو. نوع جديد يظهر كمعلومة بلا رابط.
- **روابط بفلتر أولي**: `DashboardLinks.debts` (`/memberships?has_debt=1`) و `DashboardLinks.expiring` (`/memberships?expiring_within_days=7`): شاشة الاشتراكات تقرؤها حين تُبنى.
- **أسلوب "Ignara" بالرئيسية** (2026-11-11، بطلب صاحب المشروع): `presentation/demo/`. الألوان من `AppPalette` (ألوان التطبيق كله، §2)، و `DemoShape` (`demo_shape.dart`) ما بقي خاصاً بالرئيسية: زوايا 20/14/10، منحنى `Cubic(.22, 1, .36, 1)`، أحجام الرسم. `DemoCard` (بدل `SectionCard`: ظل طويل، تفتح عند المرور)، `DemoButton` (تدرج + توهج / زجاجي)، `DemoSegmented`، `DemoKpi` و `DemoHeroKpi` (بطاقة التدرج للاشتراكات الفعّالة مع شريط فعّالة / مجمّدة / بالسماح)، و `LollipopChart` (رسم "الخرز" بدل `RevenueBars`: المرور أو الضغط يظلّل اليوم ويرسم خط قيمته، حلقة اليوم "تتنفس" `DemoShape.breaths` مرات ثم تسكن كي لا تبقى الصفحة ترسم و `pumpAndSettle` يستقر، تبويب 7 / 14 يوماً لأن الخادم يرسل 14). الرأس `DashboardHero` نص كبير بلا `HeroBanner`. للتراجع: أرجع `SectionCard` / `AppStatCard` / `RevenueBars` / `HeroBanner` (نسخة أول commit) واحذف `demo/`.
- **خطوط الاختبار**: `loadAppFonts()` (`test/helpers/app_fonts.dart`) يحمّل خطّي الهوية، فاختبارات الفيض بعرض 360 / 800 / 1024 تطابق المتصفح. استدعه بأي اختبار ويدجت يفحص التخطيط.

## 20. الأعضاء (مبنية ومختبرة)

- `features/members`: `MembersScreen` (`Members.html`) = `AppTabs` (الأعضاء / الأرشيف بعدّادين) + "إضافة عضو" + `MembersTable` (`PagedTable`).
- المسار `GET club-admin/players` بـ `search` (الاسم، الموبايل، المعرّف) و `membership_status` (`active · expiring · grace · frozen · expired · none`؛ **لا فلتر "لم يبدأ" بالخادم**، فرقاقة "تنتهي قريباً" مكانها) و `has_debt` و `gender` و `branch_id`، و `archived=only` للأرشيف. العدّادان طلبان بصف واحد (`per_page=1`) بالتوازي.
- **الفرع**: فرع الشريط العلوي يُرسل مع كل طلب ويغلب فلتر الجدول؛ حبة "الفرع" داخل الجدول تظهر فقط حين يكون الشريط على "كل الفروع" وللنادي أكثر من فرع. تغيير الفرع أو التبويب ينشئ Cubit جديداً (`MembersListCubit(repo, (tab:, branchId:, query:))`).
- **فلتر أولي من الرابط**: `/members?membership_status=expired&has_debt=1&gender=female&branch_id=2&search=...` (`membersQueryFrom`؛ القيم غير المقبولة بالخادم تُهمل). روابط الرئيسية والبحث والتنبيهات تفتح القائمة هكذا.
- الصف: `MemberIdentity` (حروف + الاسم + "حساب موقوف" لـ `status = suspended` + المعرّف)، الموبايل LTR، الفرع، `MembershipCell` (الخطة + `membershipDetail` من حقول الخادم: `days_remaining`، `sessions_remaining`، `frozen_until`، `starts_on`، `ends_on`)، `MembershipBadge` (`status_label` بلون `Labels`)، `DueText` (عنبري)، وقائمة ⋯ (فتح الملف؛ أرشفة/استرجاع **للمالك فقط**: `DELETE players/{id}` و `POST players/{id}/restore`، والخادم يرفض أرشفة من عليه دين باشتراك فعّال برسالة تظهر بالنافذة). الضغط على الصف يفتح `/members/{id}` (ملف العضو، أدناه).
- **إضافة عضو**: `FormDialog` (الاسم، الموبايل، الجنس، الفرع إن تعدد، تاريخ الميلاد قبل اليوم، جهة الطوارئ، ملاحظات) ← `POST players` مع `IdempotencyKeeper` ← `CredentialsDialog`: الموبايل والمعرّف وكلمة السر المؤقتة (مرة واحدة) + "إرسال بواتساب" بـ `whatsapp_message`. رقم له حساب مسبقاً (`is_existing_account`) ← رسالة الربط بلا كلمة سر. رقم مسجّل أو مؤرشف ← 409 `CONFLICT`، وحد الباقة ← `PLAN_LIMIT_REACHED`: الرسالة أعلى النموذج كما هي.
- بعد أي تغيير: `refreshMembers(context)` (الصفحة الحالية بـ `refresh(keepPage: true)` + العدّادان).
- **ملف العضو** `/members/{id}` (`MemberProfile.html`، `MemberProfileScreen`): `MemberProfileCubit` (factoryParam بالمعرّف، `LoadCubit<MemberProfile>`) ← `GET players/{id}` (يشمل المؤرشف). الترتيب: تنبيه (موقوف بسببه وتاريخه، أو بالأرشيف) ← `ProfileHeader` (الصورة 72 وزر تغييرها، الاسم والشارات، سطر التعريف، الأفعال) ← عمودان من `AppSize.profileSplit` (960): `CurrentMembershipCard` + `MemberHistoryCard` | `MemberDataCard` (تعديل) + `ActivityCard` + `TrainingCard` (إن وُجد مدرب أو قياس) + `NotesCard`. أضيق: عمود واحد والسجل بالأسفل. معرّف غير رقمي = "العضو غير موجود" بلا طلب.
- **الأفعال** (`profile_actions.dart`، المالك والاستقبال؛ المؤرشف بلا أفعال): تعديل `PATCH players/{id}` بـ `apiBody(keepNulls: true)` (الحقل الممسوح يُرسل null)، إيقاف بسبب إلزامي `POST …/suspend {reason}`، تفعيل `…/activate`، كلمة سر جديدة بعد تأكيد `…/reset-password` ← `CredentialsDialog` (يخرج العضو من أجهزته)، صورة `FilePick.image()` ← `POST …/photo` (`photo`، 3MB). بعد كل فعل: تحديث صامت للملف.
- **السجل** `MemberHistoryCard`: `AppTabs` (الاشتراكات / الحضور / الدفعات) + `PagedTable` لكل تبويب بـ `MemberHistoryCubit<T>` (10 بالصفحة، factoryParam بالمعرّف لكل نوع): `GET memberships?player_id=` (الأحدث بدءاً)، `GET attendance?player_id=`، `GET transactions?player_id=` (الخادم يخفي الرواتب عمّن لا يرى المالية). الأعمدة `HistoryColumns`، وأدنى عرض `AppSize.historyTableMin` (600).
- الاختبارات: `test/features/members/` (موديلات من رد حقيقي، `membershipDetail`، `membersQueryFrom`، `pageWindow`، `IdempotencyKeeper`، الـ Cubit، والشاشة: الفلاتر والبحث المؤجل، الفارغ بفلاتر وبدونها، الخطأ، الأرشيف، صلاحية الأرشفة، الإضافة وكلمة السر، الصفحات، الموبايل، و 360/800/1024 بلا overflow؛ وملف العضو: الموديلات، الـ Cubits، الشاشة والتبويبات، الإيقاف والتفعيل، كلمة السر، التعديل، الأرشيف، الخطأ، و 360–1440). `ShellHarness` يعرض `MembersScreen` الحقيقية على `/members` و `MemberProfileScreen` على `/members/:id`، فاختبارات الهيكل التي لا تخص الأعضاء تفتح قسماً غير مبني (`Routes.billing` منذ بناء الإعلانات).

## 21. الاشتراكات والديون (مبنية ومختبرة)

- `features/memberships`: `MembershipsScreen` (`Memberships.html`) = `MembershipStatsRow` (4 `AppStatCard`: الفعّالة، المجمّدة، تنتهي خلال 7 أيام، مجموع الديون بخانتين؛ الأخيرتان تفتحان تبويبيهما) ← `AppTabs` (كل الاشتراكات / عليها ديون / تنتهي خلال 7 أيام، والعدّادان من الأرقام) ← `MembershipsTable` (`PagedTable<MembershipRow>`).
- **التبويبات**: الكل `GET club-admin/memberships` بفلاتر `status` (`active · upcoming · frozen · grace · expired · cancelled`) و `plan_id` (من `GET membership-plans`، فشلها يخفي الفلتر فقط) و `branch_id` و `search` (اسم العضو، الموبايل، الخطة؛ **لا يبحث بالمعرّف**). الديون `GET memberships/debts?sort_by=due&sort_dir=desc`. القريبة `expiring_within_days=7&sort_by=ends_on&sort_dir=asc` (الخادم لا يعرف "المنتهية حديثاً"، فالتبويب للقادمة فقط). الفلاتر بتبويب "الكل" وحده.
- **الأرقام** (`MembershipStatsCubit`، factoryParam بالفرع): ثلاثة طلبات بصف واحد (`per_page=1`، المجموع من `pagination.total`) + `debts.meta.summary` (`total_due_usd`، `memberships_count`) بالتوازي؛ فشلها يخفي البطاقات وعدّادي التبويبين ولا يوقف الجدول.
- **الرابط**: `membershipsArgsFrom` ← `?has_debt=1` تبويب الديون، `?expiring_within_days=…` القريبة، وإلا الكل بـ `status`/`plan_id`/`branch_id`/`search`. مفتاح الحالة `(branchId, initial)`: رابط جديد وأنت بالصفحة (من إشعار مثلاً) يفتح تبويبه.
- **الصف**: العضو (حروف + الاسم + الفرع)، الخطة + `membershipDetail`، الفترة `MembershipPeriod` (من `member_cells.dart`، مشتركة مع سجل الملف)، الصافي، الدين `DueText`، الحالة `MembershipBadge`. الضغط يفتح تفاصيل الاشتراك `/memberships/{id}` (§22). الصف فيه `player{id,name}` فقط (بلا المعرّف ولا الموبايل).
- الاختبارات: `test/features/memberships/` (موديل من رد حقيقي، `membershipsArgsFrom`، الـ Cubits، والشاشة: الأرقام والتبويبات، الرقائق والبحث والمسح، تبويب الديون وفتح العضو، رابط القريبة، بطاقة الديون، فارغ بفلاتر وبدونها، فشل الأرقام والقائمة، فشل الخطط، الموبايل، و 360–1440). `ShellHarness` يعرض `MembershipsScreen` الحقيقية على `/memberships`.

## 22. تفاصيل الاشتراك (مبنية ومختبرة)

- `/memberships/{id}` ← `MembershipDetailScreen` (`MembershipDetail.html`، `_itemPage` في `app_router.dart`): `MembershipDetailCubit` (factoryParam بالمعرّف، `LoadCubit<MembershipDetail>`) ← `GET club-admin/memberships/{id}`. معرّف غير رقمي = "الاشتراك غير موجود" بلا طلب.
- **الموديل** `MembershipDetail` يركّب `MembershipRow` (نفس صف القائمة) + الخطة والفرع والمدرب بمعرّفاتها، السعر والخصم والدين بالليرة، الجلسات، العمولة، الكوبون، `FreezeAllowance` (`max_freezes`، `max_freeze_days`، المستخدم، `history` = `FreezeEntry`)، الإلغاء، الملاحظات، و `transactions` (`PaymentEntry` من سجل العضو + `amount_usd` و `occurred_at` و `created_by`). الشروط من حالة الخادم فقط: `hasDebt` (غير ملغى و due>0)، `canFreeze` (active|upcoming)، `isFrozen`، `canConsumeSession` (جلسات وفعّال). لا نحسب رصيد التجميد المتبقي: "استُخدم X من Y" والخادم يرفض بـ `FREEZE_LIMIT_REACHED`.
- **الترتيب**: `CancelledNotice` (السبب والتاريخ) ← `MembershipHeader` (الصورة، الخطة، الشارة، رابط العضو، "بيع من الفرع"، الأفعال، ثم بطاقات `_Fact`: المدة، المتبقي، الجلسات، رصيد التجميد، المدرب، العمولة للمالك فقط، الكوبون، تاريخ البيع) ← عمودان من `AppSize.profileSplit`: `MembershipTabsCard` | `MembershipAccountCard` (السعر، الخصم، الصافي، المدفوع، الدين بالعملتين أو "مدفوع بالكامل"). أضيق: الحساب ثم التبويبات.
- **الأفعال** (`membership_actions.dart`، `renew_dialog.dart`؛ كلها `FormDialog` ثم `cubit.refresh()`): "سداد الدين $X" `POST …/payments {payments, branch_id?}` (`NOTHING_DUE`)، تجميد `…/freeze {days, reason?}`، فك التجميد `…/unfreeze`، تسجيل جلسة `POST memberships/{id}/sessions {note?, branch_id?}`، الفاتورة `GET …/invoice` و إيصال كل دفعة `GET transactions/{id}/receipt` (`BlobOpener`)، الإلغاء **للمالك** `…/cancel {reason, refunds?, branch_id?}` (الاسترجاع يظهر فقط إن دُفع شيء). التجديد = نفس الخطة والمدرب: النافذة تطلب `POST memberships/quote {plan_id, previous_membership_id}` وتعرض الفترة والصافي وجواز الدفع الجزئي، ثم `POST …/renew {payments?, branch_id?, trainer_id?}` ← تفتح الاشتراك الجديد. تغيير الخطة أو الكوبون من "بيع اشتراك". عمليات المال بـ `IdempotencyKeeper`.
- **المال**: `PaymentFields` (حقلا الدولار والليرة، `linesOf(form)` يحذف الفواصل والفارغ والصفر، و `noAmount` فشل محلي) و `CashBranch.of(context, fallback:)`: فرع الشريط العلوي، أو قائمة الفروع الفعّالة (أوليّها فرع الاشتراك) حين يكون على "كل الفروع" وللنادي أكثر من فرع.
- **التبويبات**: الدفعات والتجميدات من رد التفاصيل (جدول بلا صفحات، بطاقات بالموبايل)؛ جدول الدفعات بأدنى عرض `AppSize.paymentsTableMin` ورقم الإيصال بعمود ثابت `AppSize.receiptNumberCol` فلا ينكسر، والحضور `GET attendance?player_id=&from=starts_on&to=ends_on` (`MembershipAttendanceCubit`، 10 بالصفحة؛ الخادم بلا فلتر `membership_id`). عكس الجلسة غير مبني (لا قائمة جلسات بالخادم).
- الاختبارات: `test/features/memberships/membership_detail_test.dart` (الموديل من رد حقيقي، `linesOf`، الـ Cubits) و `membership_detail_screen_test.dart` (الرأس والحساب، صلاحية الإلغاء والعمولة، السداد بالعملتين والفرع والمفتاح، بلا مبلغ، `CASH_SESSION_REQUIRED` ← الصندوق، التجميد، فك التجميد وسجله، الإلغاء مع استرجاع، التجديد ← الاشتراك الجديد، الجلسات، الملغى، الحضور بالفترة، رابط العضو، الخطأ، معرّف خاطئ، و 360–1440). `ShellHarness` يعرض الشاشة الحقيقية على `/memberships/:id`.

## 23. بيع اشتراك (مبني ومختبر)

- `/memberships/new` (+ `?player_id=` من ملف العضو: `Routes.sellTo(id)`) ← `SellMembershipScreen` (`SellMembership.html`). الزر "بيع اشتراك" بجانب تبويبات الاشتراكات وأول أفعال ملف العضو. المسار مسجّل قبل `:id`.
- **البيانات** (`SellMembershipRepository`): `plans(branchId:)` ← `GET membership-plans?status=active&per_page=100&sort_by=sort_order` (+ `branch_id` حين يكون فرع الشريط محدداً)، `trainers()` ← `staff-members?type=trainer&status=active` (تُطلب مرة واحدة عند أول خطة تدريب خاص)، `member(id)` ← `players/{id}`، `quote(body)` ← `POST memberships/quote`، `sell(body, idempotencyKey:)` ← `POST memberships` ← `SaleResult` (الاشتراك + حركة لكل دفعة برقم إيصالها). الموديلات بـ `sale_models.dart`؛ `MembershipQuote` مشترك مع نافذة التجديد.
- **`SellMembershipCubit`** (factoryParam `SellArgs = (playerId:, branchId:)`، يُنشأ بمفتاح الفرع بعد استقرار `BranchScopeCubit`): الخطط والعضو بالتوازي، `selectPlan` / `setStart` / `applyCoupon` / `applyDiscount` كلها تعيد التسعير بجسم `{plan_id, starts_on?, coupon_code?, discount_usd?}`، ورد تسعير قديم يُتجاهل (عدّاد). كوبون أو خصم مرفوض (`COUPON_INVALID` 422، `FORBIDDEN`) يُبقي التسعير السابق ويعرض السبب تحت الحقل. الكوبون والخصم يُطبَّقان بزر "تطبيق" لا مع الكتابة. `done(result)` يعرض النجاح و `startOver()` نموذج جديد بمفتاح منع تكرار جديد (الخطط والمدربون يبقون).
- **الخطوات** (`sale_steps.dart`، `sale_form_steps.dart`): 1 العضو (`QuickSearch.pick(context)` يفتح نافذة البحث نفسها ويرجع العضو بدل فتح ملفه؛ الدين السابق والحالة تحت الاسم) ← 2 الخطة (بطاقات `ResponsiveGrid` باختيار واحد؛ "يحتاج مدرباً" ← قائمة المدرب الإلزامية) ← 3 التاريخ والخصم (البداية `FormDate`، النهاية من الخادم، رقائق كوبون / خصم يدوي **للمالك فقط**) ← 4 الدفع (`PaymentFields` + فرع البيع والصندوق حين يلزم + ملاحظات).
- **الملخص** (`sale_summary.dart`): الخطة، الفترة، السعر، الخصم (والكوبون)، الصافي بالعملتين، المدفوع والمتبقي **تقديراً** بسعر صرف التسعير (`MembershipQuote.paidUsd`) مع الكتابة (`ListenableBuilder` على controllerي الدفع)، ملاحظة الدفع الجزئي، `FormErrorBanner`، و "تأكيد البيع" (معطّل حتى العضو والخطة والتسعير). الخادم يحسب الدين النهائي ويرفض الزائد.
- **الصندوق**: إن كان فرع البيع بلا وردية مفتوحة: تنبيه "لا توجد وردية صندوق مفتوحة بـ…" مع "فتح الصندوق" (الزر لا يُعطَّل؛ الخادم يقرر بـ `CASH_SESSION_REQUIRED` وتعرضه اللافتة). `FormErrorBanner` يغلق النافذة قبل فتح الصندوق فقط إن كان داخل نافذة (`PopupRoute`).
- **النجاح** (`sale_done.dart`): رسالة الخادم، الدين المتبقي، إيصال لكل دفعة مع "طباعة الإيصال"، "فتح الاشتراك"، "بيع اشتراك آخر". بعده `UnreadCountCubit.refresh()`.
- الاختبارات: `sell_membership_test.dart` (موديلات من ردود حقيقية والـ Cubit: الكوبون، الخصم المرفوض، رد قديم، المفتاح) و `sell_membership_screen_test.dart` (الدخول من القائمة والملف، اختيار العضو، بيع كامل بالعملتين والإيصالات، بيع آخر، المدرب، الكوبون، الخصم للمالك فقط، تاريخ البداية، تنبيه الصندوق، `CASH_SESSION_REQUIRED`، أخطاء الدفعات، فشل الخطط وفراغها، و 360–1440). `ShellHarness` يعرض الشاشة الحقيقية على `/memberships/new`.

## 24. الحضور (مبني ومختبر)

- `/attendance` ← `AttendanceScreen` (`Attendance.html`): رأس "حضور اليوم · {الفرع}" + "تسجيل دخول يدوي" ← `AttendanceTodaySection` (4 `AppStatCard`: المقبول، المرفوض (يفلتر السجل على المرفوض)، بفترة السماح، الجلسات المستهلكة؛ و `HoursCard` بجانبها من `AppSize.splitMin`) ← `AttendanceTable` (`PagedTable<AttendanceRow>`) ← ملاحظة الفترة الافتراضية.
- **البيانات** (`AttendanceRepository`): `list(query, branchId:)` ← `GET club-admin/attendance` (فلاتر `status`، `method`، `from`/`to`، `branch_id`، `search` بالاسم والموبايل والمعرّف؛ بلا فترة = آخر 31 يوماً و `meta.period.is_default`)، `today(branchId:)` ← `GET attendance/today` (`accepted`، `rejected`، `in_grace`، `sessions_consumed`، `by_hour`؛ **لا عدد أعضاء مميزين**)، `checkIn(body, idempotencyKey:)` ← `POST attendance/check-in`.
- **فرع اليوم**: `today` يحتاج فرعاً: فرع الشريط، أو الرئيسي من الفروع الفعّالة حين يكون على "كل الفروع" (والرأس يسمّيه). الـ Cubitان بمفتاح `(branchId, query)`.
- **الرسم** `HoursCard`: الساعات من 6 صباحاً حتى 1 بعد منتصف الليل (+ أي ساعة فيها بيانات، بترتيب اليوم: `AttendanceToday.hours`)، أعمدة LTR بارتفاع `AppSize.hoursChart`، تلميح لكل عمود، تسمية كل 4 ساعات، و "الذروة HH:00".
- **السجل**: الوقت والتاريخ، العضو (يفتح ملفه)، الفرع، الطريقة (+ "دون اتصال")، النتيجة `AttendanceResult` (عامة الآن من `history_columns.dart`: الشارة + رسالة الرفض)، سجّله. السجل بلا معرّف العضو ولا الخطة ولا الجهاز (الخادم لا يرسلها). الفلاتر: البحث، `FilterDateRange` (core، حبة فترة بـ `showDateRangePicker` وزر ×)، الطريقة، الفرع (حين الشريط على الكل)، ورقائق الحالة. `AttendanceEntry.rejectionReason` = رمز الرفض.
- **التسجيل** `CheckInDialog.show(context, fallbackBranch:)` ← `Future<bool>` (سُجّل شيء ← تحديث اليوم والسجل بـ `keepPage`): المعرّف أو الباركود (Enter يرسل، يُحوَّل لأحرف كبيرة)، أو رمز QR من تطبيق العضو يكتبه قارئ الباركود (`CheckInDialog.isQrToken`: يبدأ بـ `UG1.` ← `qr_token` كما هو بلا تحويل أحرف؛ رفضه 422 `QR_EXPIRED` / `QR_MALFORMED` / `QR_INVALID` / `QR_UNKNOWN_KEY` برسالة الخادم أعلى النموذج، بلا `errors`) أو **"مسح QR بالكاميرا"** (حين `qr_attendance` بالباقة، تُقرأ من سياق الشاشة لأن النافذة خارج الهيكل: `sl<QrScanner>().scan` ← `QrScanDialog` بـ `mobile_scanner`، أول رمز عضو (`UG1.` أو معرّف) يغلقها، رمز غريب يبقيها مع تنبيه، ورسائل رفض الإذن / عدم الدعم / التعذر؛ المقروء يوضع بالحقل ويُرسل فوراً ويلغي العضو المختار؛ الاختبارات تسجّل `FakeQrScanner`) أو "البحث بالاسم أو الموبايل" (`QuickSearch.pick` مع `BlocProvider.value(BranchScopeCubit)` لأن النافذة فوق الهيكل)، فرع الدخول، مفتاح "استهلاك جلسة مع الدخول". الجسم `{player_id | member_code | qr_token, branch_id?, consume_session?}` بـ `IdempotencyKeeper` عبر `CheckInCubit`.
- **النتيجة** `CheckInResultCard`: 201 خضراء (عنبرية بفترة السماح) بالاشتراك والمتبقي والدين، 200 `duplicate` زرقاء برسالة الخادم ("مسجّل منذ…")، و **409 بسجل محفوظ = رفض** يحوّله `AttendanceRemoteDataSource.checkInResultOf` لنتيجة (بطاقة حمراء بالرسالة) لا خطأ نموذج. 404/422/الشبكة تبقى بالنموذج. `checkInFollowUp`: لا اشتراك/منتهٍ/سماح ← "بيع اشتراك" (`Routes.sellTo`)، مجمّد/لم يبدأ/بلا جلسات/فرع غير مسموح ← "فتح الاشتراك"، دين ← "سداد الدين"، غير ذلك ← "ملف العضو". "تسجيل آخر" ينظف النموذج بمفتاح جديد.
- **لم يُبنَ**: "فتح شاشة الاستقبال" (مشروع `ultra_gym_reception`).
- **باكج ويب جديد**: بعد إضافته قد يبقى `web_plugin_registrant.dart` القديم بـ `.dart_tool/flutter_build/<hash>/` مع `flutter run -d web-server --release` (`No implementation found for method …`): احذف مجلدات الـ hash وأعد البناء.
- الاختبارات: `test/features/attendance/` (`attendance_test.dart`: الموديلات من رد حقيقي، الساعات والذروة، تحويل 409، المتابعة، الرابط، الـ Cubits؛ `attendance_screen_test.dart`: اليوم والرسم والسجل، الفلاتر والفترة، الفرع، القبول بالدين، الرفض ← البيع، المكرر ومفتاح جديد، بلا عضو و 404، الاختيار بالبحث والجلسة، فشل اليوم، الفارغ، الاستقبال، و 360–1440). `ShellHarness` يعرض الشاشة الحقيقية على `/attendance`، واختبارات الهيكل العامة تفتح قسماً غير مبني (`Routes.billing` منذ بناء الإعلانات).

## 25. باقة النادي (مبنية ومختبرة)

- `features/club_plan`: `ClubPlanCubit` بعمر الهيكل (يقدّمه `AppShell`، factoryParam بـ "المالك؟") ← `GET /tenant/entitlements` (`Entitlements`: `limits` (null = غير محدود) + `features`) و، للمالك فقط، `GET club-admin/billing/subscription` (`ClubSubscription` من `current`؛ null = لا اشتراك مسجّل) بالتوازي.
- **إخفاء الأقسام**: `NavEntry(feature: PlanFeature.x)` و `AdminNav.visibleFor(session, has:)`؛ الآن الرواتب والسلف ← `advanced_finance`، أجهزة الاستقبال ← `offline_reception`. فتح رابط قسم غير مشمول يعرض `PlanFeatureLocked` ("هذه الميزة ليست ضمن باقتك"، وللمالك "عرض الباقة الحالية" ← `Routes.billing`) بدل الشاشة. أي زر داخل شاشة يخص ميزة (تصدير التقارير `reports_export`، QR `qr_attendance`) يقرأ `context.watch<ClubPlanCubit>().state.has(PlanFeature.x)`.
- **قبل التحميل أو عند الفشل كل ميزة متاحة**، وميزة لا يذكرها الخادم متاحة: الإخفاء للتوضيح، والخادم يرفض بـ `FEATURE_NOT_AVAILABLE` على أي حال (`ErrorState` يعرضه "غير متاح بباقتك").
- **شريط الاشتراك** `ClubPlanBanner` تحت الشريط العلوي (`Dashboard.html`): `grace` ← تنبيه بتاريخ نهاية السماح + "عرض الفاتورة"، و `expired` ← خطر "اللوحة للقراءة فقط" + "تواصل مع UltraGym" (الرابطان للمالك فقط). الاستقبال لا يقرأ اشتراك النادي: `AuthInterceptor` يحوّل أي `403 SUBSCRIPTION_EXPIRED` إلى `SessionEvent.readOnly` (لا ينهي الجلسة؛ `AuthBloc` يتجاهله) فيظهر الشريط للجميع بعد أول عملية مرفوضة. `locked` / `suspended` يبقيان شاشة الحجب (`tenantBlocked`).
- **لم يُبنَ**: تعطيل أزرار التعديل مسبقاً بوضع القراءة فقط (الخادم يرفض ورسالته تظهر بالنموذج)، وعرض الحدود (`limits`) بالشاشات (`PLAN_LIMIT_REACHED` يظهر كما هو).
- الاختبارات: `test/features/club_plan/` (الموديلات من رد حقيقي، الـ Cubit للمالك والاستقبال، الفشل، حدث القراءة فقط، القائمة، والهيكل: القسم المخفي ورابطه، شريط السماح ورابطه، بلا شريط، القراءة فقط للاستقبال، و 360/800) و `api_client_test.dart` (`SUBSCRIPTION_EXPIRED` ← `readOnly`). `ShellHarness` يسجّل `ClubPlanCubit` بـ `h.plan` و `h.events` (نفس قناة `AuthBloc`).

## 26. الدخول اليومي (مبني ومختبر)

- `/day-passes` ← `DayPassesScreen` (لا صفحة بالنموذج؛ بأسلوب `SellMembership.html`): `DayPassesHeader` ("سعر الدخول اليومي · {الفرع}"، سطر السعر أو سبب غيابه، و "بيع دخول يومي") ← `DayPassesStats` (4 `AppStatCard` من `meta.summary`: العدد، الزوار، أعضاء بلا اشتراك، الإيراد بخانتين) ← `DayPassesTable` (`PagedTable<DayPass>`) ← ملاحظة الدفع الكامل والفترة الافتراضية.
- **البيانات** (`DayPassesRepository`، تحت `/club-admin/day-passes`): `list(query, branchId:)` (فلاتر `kind`، `status`، `from`/`to`، `branch_id`، `search` بالاسم والموبايل؛ بلا فترة = آخر 31 يوماً)، `price(branchId:)` ← `GET day-passes/price` (`DayPassPrice`: `enabled`، `price_usd`/`price_syp` أو null، `source`، `can_change_price` للمالك، `gender_required` بفرع الأوقات المنفصلة؛ `canSell` = مفعّل و (له سعر أو يستطيع كتابته))، `sell(body, idempotencyKey:)`، `detail(id)`، `cancel(id, reason, idempotencyKey:)`.
- **فرع السعر**: فرع الشريط أو الرئيسي (`BranchScope.mainId`، يستعمله الحضور أيضاً). الـ Cubitان (`DayPassPriceCubit`، `DayPassesListCubit`) بمفتاح `(branchId, query)`.
- **البيع** `SellDayPassDialog.show(context, fallbackBranch:)` ← `Future<bool>` (بيع شيء ← تحديث السجل بـ `keepPage`). `DayPassSaleCubit`: السعر لفرع النموذج (تغيير الفرع يعيد الطلب، والرد القديم يُتجاهل بعدّاد)، المشتري زائر / عضو، `keyFor` بـ `IdempotencyKeeper`، `again()` نموذج جديد بمفتاح جديد. الحقول: زائر = الاسم (إلزامي) + الموبايل + الجنس (فقط حين `gender_required`)، عضو = `QuickSearch.pick`؛ حقل السعر للمالك (`0` = يوم تجربة مجاني، إلزامي إن لم يُحدد سعر)؛ `PaymentFields` (الدولار يُملأ بالسعر). الجسم `{branch_id, player_id | visitor_name + visitor_phone? + gender?, price_usd? (إن كتبه المالك), payments?, notes?}`؛ بلا عضو أو بلا مبلغ لدخول مدفوع = فشل محلي. أخطاء الخادم (`HAS_ACTIVE_MEMBERSHIP`، `DAY_PASS_EXISTS`، `GENDER_*`، `CASH_SESSION_REQUIRED`) تظهر أعلى النموذج كما هي.
- **قاعدة**: حقل يختفي (زائر ← عضو، فرع بلا أوقات منفصلة، فرع بلا حق تغيير السعر) يزيل تحققه بنفسه (`form.validator(name, null)`)، وإلا بقي تحققه المسجّل يمنع الإرسال.
- **النجاح** `DayPassSold`: النوع والاسم والفرع ("سُجّل دخوله تلقائياً" للعضو)، السعر أو "مجاني"، `DayPassReceipts` (المبلغ، رقم الإيصال، "معكوسة"، "طباعة الإيصال" ← `openReceipt`)، "بيع آخر".
- **التفاصيل** `DayPassDetailDialog.show(context, id)` (نافذة لا صفحة؛ `/day-passes/{id}` ما زال `PendingSection`): الشارة، تنبيه الإلغاء بسببه ووقته، السعر والمدفوع والفرع ويوم العمل والوقت والجنس ومن سجّله، الملاحظات، الإيصالات (مع حركة العكس). "إلغاء الدخول" **للمالك** على الفعّال فقط: `FormDialog` بسبب إلزامي ← `POST …/cancel {reason}` (يعكس الدفعات بالوردية المفتوحة).
- الاختبارات: `test/features/day_passes/` (`day_passes_test.dart`: الموديلات بشكل العقد، الرابط، الـ Cubits ورد السعر القديم؛ `day_passes_screen_test.dart`: السعر والأرقام والسجل، بلا سعر للمالك والاستقبال، بيع زائر ومفتاحه، يوم تجربة مجاني، بلا مبلغ ورفض الخادم، عضو بالبحث، عضو غير مختار، فرع بأوقات منفصلة ← الجنس، التفاصيل والإلغاء، الاستقبال بلا إلغاء، الفلاتر، الفارغ، و 360–1440). `ShellHarness` يعرض الشاشة الحقيقية على `/day-passes`، واختبارات الهيكل العامة تفتح `Routes.billing` (والاستقبال `Routes.dashboard`).

## 27. الصندوق والورديات (مبني ومختبر)

- `/cash-sessions` ← `CashSessionsScreen` (`CashSessions.html`): صندوق فرع الشريط العلوي (أو صندوق لكل فرع فعّال حين يكون على "كل الفروع")، ثم "الورديات السابقة" (`CashHistoryTable`، `PagedTable<CashSession>`). الصف يفتح `/cash-sessions/{id}` (`CashSessionDetailScreen`، وروابط إشعارات `cash_session` تصل إليها).
- **البيانات** (`CashSessionsRepository`، تحت `/club-admin/cash-sessions`): `current(branchId:)` ← `CashBox` (الوردية المفتوحة بأرصدتها الحية `totals`، أو null مع `suggested_opening` = جرد آخر وردية)، `list(query, branchId:, status:)` (فلاتر `from`/`to`، `branch_id`، `with_difference`؛ **بلا فترة افتراضية**، الأحدث فتحاً أولاً؛ `status=closed` يُرسل مع الطلب لا بالـ query فلا يمسحه "مسح الفلاتر")، `detail(id)` (+ `breakdown` حسب النوع والعملة)، `open(body)`، `close(id, body)` (كلاهما بـ `IdempotencyKeeper`)، `report(id)` ← `BlobOpener` (PDF أو HTML للطباعة).
- **`CashBoxCubit`** (factoryParam بالفرع): `current` ثم، إن وُجدت وردية، `detail` لأسطر "حسب النوع"؛ فشل التفاصيل يُبقي الأرصدة الحية بلا التفصيل.
- **البطاقة** `CashSessionCard` (للصفحة وللتفاصيل): "الوردية #N" (+ الفرع حين يتعدد) والحالة "مفتوحة / مغلقة" (`CashSessionLabels`)، فتحها / أغلقها ووقتها، يوم العمل، عدد الحركات (مجموع `count` للعرض)، "تقرير الوردية"، "إغلاق الوردية بالجرد" (للمفتوحة)، ثم ثلاث لوحات: الدولار والليرة (الافتتاحي، الداخل +، الخارج −، المتوقع بالدرج الآن؛ والمغلقة: الجرد والفرق) و "حسب النوع" (كل نوع بعملته وعدده، الداخل أخضر والخارج أحمر). الصفر بلا إشارة.
- **الفرق** `CashDifferenceBadge`: "مطابق" (success) / "عجز −$3.00" (danger) / "زيادة +5,000 ل.س" (warning) بـ `Labels.difference`؛ `compact` بالجدول = المبلغ بإشارته فقط ويصغر إن ضاق العمود.
- **الأفعال** (`CashSessionActions`): `open(context, box)` = `FormDialog` (الافتتاحي بالعملتين مقترح من آخر جرد، ملاحظة) ← `{branch_id, opening_usd, opening_syp, notes?}`؛ `close(context, session)` = الجرد بالعملتين (إلزامي، 0 مقبول) وتحت كل حقل المتوقع والفرق **تقديراً** مع الكتابة (الخادم يثبّت الفرق) ← `{closing_usd, closing_syp, notes?}` ثم `CashClosedDialog` (اللوحتان كما ثبّتها الخادم + "تقرير الوردية"). بعد أي منهما: تحديث الصندوق، `BranchScopeCubit.refresh()` (شارة الشريط)، `UnreadCountCubit.refresh()`، والسجل. الاستقبال يفتح ويغلق بفروعه مثل المالك.
- **core**: `FilterBar(onSearch: null)` = شريط فلاتر بلا بحث (الورديات).
- **تبويبات المالية** (`FinanceTabs` من `features/transactions`): "الورديات" و "دفتر الحركات" أعلى الصفحتين، وبطاقة الوردية المفتوحة فيها "مصروف أو إيراد" (§28) بفرعها الثابت. التبويبان الآخران "سعر الصرف" و "التصنيفات" (§29)؛ الشريط يتمرر أفقياً إن ضاق.
- **ملاحظة اختبار**: go_router يبني صفحة القسم تحت صفحة العنصر (`/cash-sessions` تحت `/cash-sessions/1`)، فطلبات القائمة تحدث أيضاً عند فتح رابط عنصر مباشرة (كل الأقسام).
- الاختبارات: `test/features/cash_sessions/` (`cash_sessions_test.dart`: الموديلات بشكل العقد، `current`، التسميات، الرابط، الـ Cubits وفشل التفاصيل، `status` الثابت؛ `cash_sessions_screen_test.dart`: الصندوقان والسجل، فرع الشريط، الفتح بالمقترح والمفتاح، الإغلاق بالفرق التقديري والنتيجة والتقرير، الجرد الإلزامي ورفض الخادم، الفلاتر وفتح الصف، صفحة التفاصيل والإغلاق منها والمعرّف الخاطئ، الفارغ، و 360–1440). `ShellHarness` يعرض الشاشتين الحقيقيتين بـ `h.cash`.

## 28. دفتر الحركات (مبني ومختبر)

- `/cash-sessions/transactions` (`Routes.transactions`، مسجّل قبل `:id` بقسم "الصندوق والحركات" فالعنوان والحماية من القسم) ← `TransactionsScreen` (`Transactions.html`): `FinanceTabs` + "تسجيل إيراد أو مصروف" ← `LedgerStats` (4 `AppStatCard` من `meta.totals` بالدولار المكافئ: الداخل، الخارج، الصافي، وعدد الحركات من `pagination.total`) ← `LedgerTable` (`PagedTable<LedgerEntry>`) ← ملاحظة "لا تُحذف ولا تُعدّل" والفترة الافتراضية. روابط إشعارات `payment` / `transaction` تفتحه.
- **البيانات** (`TransactionsRepository`، تحت `/club-admin/transactions`): `list(query, branchId:)` (فلاتر `type`، `currency`، `from`/`to`، `branch_id`، `include_reversed=0`، `search` برقم الإيصال أو الوصف؛ بلا فترة ولا بحث = آخر 31 يوماً)، `detail(id)` (+ `reversed_by_transaction`، `amount_syp_equivalent`)، `categories()` ← `GET finance/categories?status=active&per_page=100`، `record(body)` و `reverse(id, reason)` بـ `IdempotencyKeeper`، `receipt(id)` ← `BlobOpener`. الاستقبال لا يرى الرواتب والسلف (الخادم يخفيها، وفلتر النوع يخفي خياريهما حسب `canViewFinance`).
- **الجدول**: الإيصال (LTR، مشطوب للمعكوسة)، النوع (`type_label` بنغمة `TransactionLabels.tone`: الاشتراك والدخول اليومي أخضر، الإيراد فولت، المصروف أحمر، الاسترجاع عنبري، الراتب والسلفة أزرق، العكس محايد)، المبلغ بعملته وإشارته (`LedgerAmount`: سطر واحد يصغر)، بالدولار، التصنيف، مرتبطة بـ (`LedgerLink`: العضو ← ملفه، أو الموظف، أو "وردية #N" ← صفحتها)، يوم العمل (عمود ثابت)، المنفّذ، والإجراءات (الإيصال، ثم "عكس" للمالك أو شارة "معكوسة"). أدنى عرض `AppSize.ledgerTableMin` (1000: كل الأعمدة بلا تمرير عند 1366). الصف يفتح `TransactionDetailDialog`.
- **العكس** (المالك فقط، `LedgerEntry.canReverse` = لا معكوسة ولا حركة عكس؛ الخادم يرفضهما بـ `ALREADY_REVERSED` / `CONFLICT`): `FormDialog(danger)` بملخص الحركة وما سيحدث وسبب إلزامي ← `{reason}`. بعده تحديث الدفتر بـ `keepPage` والجرس.
- **التسجيل** `TransactionActions.record(context, branchId:, fallbackBranch:)`: يجلب التصنيفات أولاً (فشلها رسالة بلا نافذة) ثم `FormDialog` بـ `RecordTransactionFields`: الاتجاه (مصروف / إيراد آخر برقائق؛ تغييره يمسح التصنيف)، المبلغ (> 0) والعملة، التصنيف من نفس الاتجاه (لا تصنيف ← تنبيه "أضف تصنيفاً من الإعدادات المالية" وفشل محلي)، الوصف (إلزامي)، وصندوق الفرع (`CashBranch`) إلا حين يُمرَّر `branchId` ثابتاً (من بطاقة الوردية). الجسم `{type, currency, amount, category_id, description, branch_id?}`. `CASH_SESSION_REQUIRED` يظهر بـ "فتح الصندوق" (`FormErrorBanner`).
- **التفاصيل** `TransactionDetailDialog.show(context, id)` ← `Future<bool>` (عُكست؟): الإيصال والنوع والمبلغ، "معكوسة · الوقت · بالإيصال …"، بالدولار وما يعادله بالليرة وسعر الصرف، الفرع والوردية والتصنيف والعضو أو الموظف ويوم العمل والوقت والمنفّذ، الوصف، والأفعال: "عكس الحركة" (المالك)، "فتح الاشتراك" (لدفعات الاشتراك)، "طباعة الإيصال".
- **لم يُبنَ**: "تصدير Excel" (من التقارير)، ورابط الدخول اليومي من الدفتر (تفاصيله نافذة بشاشته). سعر الصرف والتصنيفات بـ §29.
- الاختبارات: `test/features/transactions/` (`transactions_test.dart`: الموديلات بشكل الرد الحقيقي، `canReverse`، التفاصيل والمجاميع ورد العكس والتصنيفات، النغمات وخيارات النوع، الرابط، الـ Cubits؛ `transactions_screen_test.dart`: الرأس والأرقام والصفوف والإشارات، تبويب الورديات والتسجيل من بطاقة الوردية بفرعها، تسجيل مصروف بجسمه وفرعه ومفتاحه، إيراد بالليرة وتغيير الاتجاه، التحقق المحلي ورفض الخادم، بلا تصنيفات وفشلها، العكس بالسبب، الاستقبال بلا عكس، التفاصيل والإيصال وفتح الاشتراك، الفلاتر ورابط العضو، الرابط بفلتر والفارغ، و 360–1440). `ShellHarness` يعرض الشاشة الحقيقية بـ `h.tx`.

## 29. الإعدادات المالية: سعر الصرف والتصنيفات (مبنية ومختبرة)

- `features/finance_settings` (`FinanceSettings.html`): تبويبان بقسم "الصندوق والحركات" عبر `FinanceTabs` (0 الورديات، 1 الدفتر، 2 سعر الصرف، 3 التصنيفات)، مسجّلان قبل `:id`: `Routes.exchangeRate` (`/cash-sessions/exchange-rate`) و `Routes.financeCategories` (`/cash-sessions/categories`). القراءة للمالك والاستقبال، والتعديل للمالك فقط (الخادم يرفض غيره بـ 403).
- **البيانات** (`FinanceSettingsRepository`، تحت `/club-admin/finance`): `rates(query)` ← `GET exchange-rate` (سجل بصفحات، الأحدث أولاً، والسعر الحالي بـ `meta.current = {syp_per_usd | null, updated_at}`)، `setRate(body, idempotencyKey:)` ← `POST exchange-rate {syp_per_usd 1..1e7, note?}`، `categories()` ← `GET categories?per_page=100` (بنوعيها وحالتيها مع `transactions_count`)، `addCategory` (`{kind, name}`، الاسم فريد لكل نوع ← 422)، `updateCategory(id, {name?, status?})`، `deleteCategory(id)` (المستعمل ← `409 CONFLICT` "أوقفه بدل حذفه"). `FinanceCategory` من `transaction_models.dart` (مشترك مع نموذج تسجيل الحركة).
- **سعر الصرف** `ExchangeRateScreen`: `CurrentRateCard` ("السعر المعتمد الآن": `1 USD = N SYP` LTR، "حدّثه X · الوقت" من أول سطر بالسجل حين الصفحة الأولى؛ بلا سعر: تنبيه عنبري بنصين للمالك والاستقبال) وتحتها للمالك نموذج سعر جديد (إلزامي ≥ 1، الفواصل مقبولة، ملاحظة، `IdempotencyKeeper` يعيش مع الويدجت) ← تحديث السجل. بجانبها من `AppSize.profileSplit` `RateHistoryTable` (`ExchangeRatesCubit`، 10 بالصفحة): التاريخ، ليرة لكل دولار، الفرق عن الأقدم التالي بنفس الصفحة (`rateChange`: ارتفاع أحمر، انخفاض أخضر، آخر سطر "—")، الملاحظة، بواسطة.
- **التصنيفات** `FinanceCategoriesScreen` (`FinanceCategoriesCubit` = `LoadCubit`): مجموعتان `CategoryGroupCard` (المصاريف / الإيرادات الأخرى، `ResponsiveGrid` بعمودين من `AppSize.categoryGroupMin`): الاسم، عدد الحركات، شارة فعّال / متوقف، وللمالك "+ تصنيف" و "تعديل" (الاسم + الحالة برقائق `FormChoice`؛ يُرسل المتغيّر فقط، ولا طلب بلا تغيير) وحذف لغير المستعمل فقط (مكانه محجوز فتصطف الشارات؛ تأكيد خطر، و 409 يظهر بالنافذة). ملاحظة الإيقاف أسفل الصفحة.
- **روابط**: تنبيه الرئيسية `exchange_rate_missing` ← `Routes.exchangeRate` للمالك، وتنبيه "لا تصنيفات" بنموذج الحركة يشير لتبويب "التصنيفات".
- الاختبارات: `test/features/finance_settings/` (`finance_settings_test.dart`: الموديلات بشكل الرد، السعر غير المحدد، `rateChange`، الـ Cubits؛ `exchange_rate_screen_test.dart`: السعر والسجل والفروق، اعتماد سعر بجسمه ومفتاحه ثم التحديث، التحقق ورفض الخادم، بلا سعر، الاستقبال بلا نموذج، التبويبات، الخطأ، و 360–1440؛ `finance_categories_screen_test.dart`: المجموعتان والعدد والحالة والحذف لغير المستعمل، الإضافة والاسم المكرر، التعديل بالمتغيّر فقط وبلا تغيير، الحذف والإلغاء و 409، الاستقبال، الفارغ والخطأ، و 360–1440 مع النافذة). `ShellHarness` يعرض الشاشتين بـ `h.finance`.

## 30. الخطط والكوبونات (مبنية ومختبرة)

- `/plans` ← `PlansScreen` (`Plans.html`، `features/plans`). المالك: `AppTabs` (خطط الاشتراك / الأرشيف / الكوبونات، `ValueCubit<int>`). الاستقبال: بطاقات الخطط للقراءة فقط (الخادم يحصر الكوبونات وكل تعديل بالمالك).
- **البيانات** (`PlansRepository`): `plans(query)` ← `GET membership-plans` (`archived=only` للأرشيف؛ الترتيب الافتراضي `sort_order`؛ كل صف مع `memberships_sold`)، `savePlan(body, id:, idempotencyKey:)` (`POST` بمفتاح أو `PATCH`)، `archivePlan` (`DELETE`: تُوقف وتُؤرشف، المباعة لا تتأثر)، `restorePlan` (`POST …/restore`: تعود موقوفة)، `coupons(query)` ← `GET coupons` (`status`، `search` بالكود)، `saveCoupon`، `deleteCoupon` (المستعمل ← `409 CONFLICT`).
- **الموديلات** (`plans_models.dart`): `Plan` (حدود التجميد محسوبة من الخادم، `defaultFreeze` = `uses_default_freeze_limits`)، `Coupon` (الحالة `active`/`inactive` فقط من الخادم؛ **لا نحسب "منتهٍ" أو "مستنفد"**: التواريخ وشريط الاستخدام يبيّنانها)، و `PlanTexts` للنصوص (النوع، المدة، الحصص، الفروع، التجميد "مرتان · 30 يوماً (افتراضي النادي)" / "بلا تجميد"، الخصم، الاستخدام `64 / ∞`، أسماء الخطط المشمولة).
- **البطاقة** `PlanCard` (`ResponsiveGrid` حتى 3 أعمدة من `AppSize.planCardMin`): الاسم والنوع وشارة فعّالة / متوقفة / مؤرشفة، السعر (+ عدد الحصص)، الوصف، المدة والفروع والتجميد والمباع، شارة "تدريب شخصي" بسطر مستقل (الشارة لا تلتف)، وللمالك "تعديل" وأرشفة (أو "استرجاع" بالأرشيف). `PaginationBar` حين يتجاوز العدد 50.
- **نافذة الخطة** (`PlanActions.save` + `PlanFormFields`): الاسم، النوع (مدة / حصص برقائق؛ حقل الحصص وتحققه فقط للحصص)، الصلاحية والسعر، الفروع (كلها / محددة + رقائق إلزامية؛ تُخفى بنادٍ بفرع واحد)، حدّا التجميد (فارغ = null = افتراضي النادي؛ يبقيان فارغين بالتعديل إن كانا افتراضيين)، الوصف، `FormSwitch` "تدريب شخصي" و "فعّالة للبيع". الجسم الكامل نفسه للإضافة والتعديل (`PlanActions.bodyOf`)، والإضافة بـ `IdempotencyKeeper`.
- **الكوبونات** `CouponsSection`: "كوبون جديد"، `PagedTable<Coupon>` (الكود LTR، الخصم `25%` / `$5.00`، الصلاحية `من ← إلى` أو "بلا تاريخ"، الاستخدام مع شريط `AppSize.usageBar`، الخطط المشمولة بأسمائها من `CouponPlansCubit` (حتى 100 خطة) أو "كل الخطط"، الحالة، "تعديل" وحذف غير المستعمل)، البحث بالكود وفلتر الحالة. الصف يفتح التعديل. النافذة (`CouponActions`): الكود (يُحوَّل لأحرف كبيرة، `[A-Z0-9_-]{3,30}`)، النوع نسبة / مبلغ، القيمة (> 0، والنسبة ≤ 100)، أقصى استخدام (فارغ = بلا حد)، البداية والنهاية (`FormDate` ← `YYYY-MM-DD`)، الخطط (بلا اختيار = كلها)، ملاحظة، "فعّال".
- **core**: `FormSwitch(name, label:, hint:)` (مفتاح بقيمة `bool`)، والتوكنز `planCardMin`، `formFieldMin`، `couponsTableMin`، `usageBar`.
- الاختبارات: `test/features/plans/` (`plans_test.dart`: الموديلات بشكل الرد، النصوص، جسما الخطة والكوبون، الـ Cubits؛ `plans_screen_test.dart`: البطاقات والتبويبات، الاستقبال، إضافة خطة بمدة وبحصص لفروع محددة، الرجوع للمدة، التعديل والإيقاف، حدود النادي الافتراضية، الأرشفة والاسترجاع، الفارغ، جدول الكوبونات، كوبون جديد ونسبة فوق 100، كود خاطئ وتعديل، الحذف و 409، فلتر الحالة، و 360–1440 مع النافذتين). `ShellHarness` يعرض الشاشة الحقيقية بـ `h.plans`.

## 31. الرواتب والسلف (مبنية ومختبرة)

- `/payroll` ← `PayrollScreen` (`Payroll.html` و `Advances.html`، `features/payroll`): للمالك بصلاحية `can_manage_staff` وميزة `advanced_finance` (القسم مخفي بدونهما، ورابطه يعرض `PlanFeatureLocked`). تبويبا "الرواتب الشهرية" و "السلف" بـ `ValueCubit<int>`.
- **البيانات** (`PayrollRepository`، تحت `/club-admin/payroll` إلا الموظفين): `staff()` ← `GET staff-members?status=active&per_page=100`، `salaries(query)` (فلاتر `period`، `staff_member_id`، `status`؛ `meta.summary.total_paid_usd`)، `preview(staffId, period)` ← `GET staff/{id}/preview?period=YYYY-MM` (`base_usd` بالدولار حتى لراتب بالليرة، `commission_usd` + `commission_clients`، `open_advances_usd`، `suggested_net_usd`، `already_paid`، `exchange_rate`)، `paySalary(staffId, body, idempotencyKey:)` ← `POST staff/{id}/salary` (`SALARY_ALREADY_PAID` 409، خصم سلف فوق المفتوح أو صافٍ سالب ← 422 على الحقل)، `advances(query)` (فلاتر `status` open|settled|cancelled، `staff_member_id`؛ `meta.summary.open_remaining_usd`)، `addAdvance(body, idempotencyKey:)` ← `POST advances {staff_member_id, currency, amount, note?, branch_id?}`. الراتب والسلفة حركتا خروج من وردية الفرع المفتوحة (`CASH_SESSION_REQUIRED` بزر "فتح الصندوق").
- **الرواتب الشهرية** (`SalariesSection`): حبة "الشهر" (الشهر الحالي بتوقيت النادي + الخمسة السابقة، `PayrollTexts.recentPeriods`) ← `PayrollRosterCubit` (factoryParam بالشهر، الموظفون ورواتب الشهر المدفوعة `status=paid` بالتوازي ← `PayrollRoster.paid` بمعرّف الموظف). `StaffListCard` (عرض `AppSize.staffListWidth` بجانب اللوحة من `AppSize.profileSplit`، وأضيق فوقها): الحروف والاسم والدور (`PayrollTexts.role`: المسمى أو النوع · الفرع) وشارة "مصروف" / "مستحق". الأول مختار مبدئياً (`ValueCubit<int?>`).
- **لوحة الموظف** `SalaryPanel` (بمفتاح الموظف والشهر): مصروف ← `_PaidView` من سجل الراتب نفسه (شارة "مصروف التاريخ"، تنبيه "لا يمكن صرفه مرة ثانية؛ للتصحيح اعكس الحركة من دفتر الحركات"، "طباعة الإيصال" بـ `transaction_id`، رابط الدفتر، والأسطر كما حُفظت) **بلا طلب معاينة**. غير مصروف ← `SalaryPreviewCubit` ← `SalaryForm`: ثلاث `SalaryTile` (الأساسي، "العمولة · N عملاء"، السلف المفتوحة عنبرية)، المكافأة والخصومات وخصم السلف ("حتى $X"، يُخفى بلا سلف ويُزال تحققه)، الصرف بالدولار / بالليرة، ملاحظة، و `SalaryBreakdown` بالصافي **تقديراً** (`suggested_net_usd` + المكافأة − الخصومات − خصم السلف، و "≈ N ل.س بسعر اليوم" أو "لا سعر صرف معتمد"). `already_paid` من المعاينة والقائمة لم تتحدث ← "صُرف مسبقاً" + "تحديث القائمة".
- **الصرف** `PayrollActions.paySalary`: تحقق الحقول محلياً (خصم السلف ≤ المفتوح، الصافي ≥ 0) عبر `form.submit` بلا طلب، ثم `FormDialog` تأكيد بالصافي التقديري و "صندوق الفرع" حين يلزم (`CashBranch`، مبدئياً فرع الموظف) ← الجسم `{period, currency, bonus_usd?, deductions_usd?, advance_deduction_usd?, note?, branch_id?}` (الموجب فقط؛ الأساسي والعمولة يحسبهما الخادم، والسلف تُخصم الأقدم أولاً) بـ `IdempotencyKeeper` لكل نافذة. بعده تحديث القائمة (فيظهر "مصروف") والجرس.
- **السلف** (`AdvancesSection`): `AdvanceStatsCubit` (طلبان بصف واحد: عدد المفتوحة والمسددة، و `open_remaining_usd`؛ **لا "خُصم هذا الشهر"**: لا رقم له بالخادم)، الملاحظة، "صرف سلفة"، و `AdvancesTable` (`PagedTable<StaffAdvance>`، أدنى عرض `AppSize.advancesTableMin`): الموظف، التاريخ، المبلغ، المخصوم "$x من $y" بشريط أخضر، المتبقي (عنبري للمفتوحة)، الملاحظة، الحالة (`PayrollTexts.advanceStatus`)، الإيصال. الفلاتر: رقائق الحالة ("الكل" مبدئياً فنادٍ بلا سلف يرى الدعوة) والموظف (حين يتعدد). النافذة (`PayrollActions.addAdvance`): الموظف (من `PayrollStaffCubit`)، المبلغ (> 0) وعملته، ملاحظة، وصندوق الفرع (مبدئياً الرئيسي).
- **core**: `Formatters.monthYear` ("تشرين الثاني 2026")، والتوكنز `staffListWidth`، `advancesTableMin`.
- **لم يُبنَ**: سجل الرواتب المدفوعة بجدول (`GET salaries` بلا فلتر شهر)، وتعديل الأساسي أو العمولة يدوياً (الخادم يقبل `base_usd` / `commission_usd`)، وإلغاء السلفة (لا مسار بالخادم؛ العكس من الدفتر).
- الاختبارات: `test/features/payroll/` (`payroll_test.dart`: الموديلات بشكل الرد، النصوص والأشهر عبر السنة، جسم الراتب والصافي التقديري، الـ Cubits وفشل أحد الطلبين؛ `payroll_screen_test.dart`: القائمة والشارات والمعاينة، الصافي مع الكتابة والليرة، الصرف بالتأكيد والجسم والمفتاح ثم "مصروف"، التحقق المحلي، `CASH_SESSION_REQUIRED`، الراتب المصروف بلا معاينة ورابط الدفتر، تغيير الشهر، بلا موظفين، السلف والأرقام والرقائق، صرف سلفة بجسمها، المبلغ الصفر، الفارغ، و 360–1440 مع النافذتين). `ShellHarness` يعرض الشاشة الحقيقية بـ `h.payroll`.

## 32. التقارير (مبنية ومختبرة)

- `/reports` ← `ReportsScreen` (`Reports.html`، `features/reports`): **عارض واحد** يرسم أي تقرير من شكل الخادم، فتقرير جديد بالخادم يظهر دون كود. المالك يرى كل التقارير، والاستقبال غير المالية (الخادم يرجع المتاح فقط).
- **البيانات** (`ReportsRepository`، تحت `/club-admin/reports`): `catalog()` ← `GET reports` (`ReportInfo`: `key`، `label`، `is_financial`، `available` (ضمن الباقة)، `uses_period`؛ و `meta.formats` ← `ReportCatalog.canExport` حين فيها pdf أو xlsx)، `report(ReportQuery)` ← `GET reports/{key}?from&to&branch_id&page&per_page=50` (`ReportResult`: `title`، `subtitle`، `from`/`to`، `summary` (مفتاح ← قيمة نصية جاهزة، بترتيب الخادم)، `sections` = `{title, columns, numeric, rows}`، `data` الخام، و `data.pagination` لتقارير القوائم)، `export(query, format)` ← نفس المسار بـ `format=pdf|xlsx` بلا صفحات ← `BlobOpener`.
- **`ReportQuery`** (`key`، `from`، `to`، `branchId`، `page`): `params({format})` يرسل الفترة والفرع فقط إن حُددا؛ `copyWith` يعيد الصفحة لـ 1 عند أي تغيير غير الصفحة. بلا فترة = الخادم يعتمد هذا الشهر ("الفترة: هذا الشهر").
- **التخطيط**: من `AppSize.profileSplit` قائمة "التقارير المتاحة لك" (`ReportList`، عرض `AppSize.reportsListWidth`: الاسم والوصف من `ReportTexts.description`، المحدد بخلفية `primarySoft` وشريط البداية، و "ليس ضمن باقتك") بجانب `ReportView`؛ أضيق: حبة "التقرير: …" (`ReportPicker` = `FilterMenu(showAll: false)`). الأول المتاح مختار مبدئياً (`ValueCubit<ReportQuery?>`). الشاشة تنتظر استقرار `BranchScopeCubit`.
- **`ReportView`**: الشريط = الحبة، `FilterDateRange` (فقط لـ `uses_period`؛ الديون بلا فترة)، "الفرع" (فقط حين الشريط العلوي على "كل الفروع" وللنادي أكثر من فرع، ولا لتقريري المدربين ومقارنة الفروع `ReportInfo.usesBranch`)، و PDF / Excel (أو شارة "التصدير غير متاح بخطتك"). فرع الشريط العلوي يغلب. التقرير بـ `ReportCubit` (factoryParam بالـ query الفعلي، `BlocProvider` بمفتاحه: أي تغيير = Cubit جديد). تقرير غير متاح ← `EmptyState` بلا طلب.
- **`ReportBody`**: العنوان والسطر الفرعي، بطاقات الملخص (`ResponsiveGrid` من `AppSize.reportSummaryMin`، القيمة LTR وحمراء إن بدأت بـ "-")، الرسم (`ReportTexts.chart`: الصندوق اليومي ← "الصافي اليومي" من `data.days[].net_usd`، الحضور ← "الدخول المقبول حسب اليوم" من `data.by_day[].accepted`؛ `ReportBars` أعمدة LTR والسالب أحمر مع "الأحمر = صافٍ سالب." فقط إن وُجد سالب)، ثم قسم لكل `section` (`AppDataTable` بأدنى عرض الأعمدة × `AppSize.reportColMin`؛ الأعمدة الرقمية LTR بمحاذاة البداية تحت رأسها، والسالب أحمر؛ فارغ ← "لا بيانات بهذه الفترة.")، `PaginationBar` حين `last_page > 1`، وملاحظة "أول 2000 صف بالـ PDF" حين التصدير متاح.
- **core**: `FilterMenu(showAll: false)` (اختيار إلزامي بلا "الكل")، والتوكنز `reportsListWidth`، `reportSummaryMin`، `reportColMin`.
- **لم يُبنَ**: رسوم لباقي التقارير (الجداول تكفي)، والترتيب داخل الأقسام (الخادم لا يقبله).
- الاختبارات: `test/features/reports/` (`reports_test.dart`: الموديلات بشكل الرد، معاملات الطلب والتصدير، الرسوم، الـ Cubits؛ `reports_screen_test.dart`: القائمة وأول تقرير، الصندوق اليومي برسمه وتصدير Excel، فلتر الفرع، الديون بلا فترة وصفحاتها، تقرير خارج الباقة وصيغة json فقط، الخطأ، الحبة بالعرض الضيق بلا "الكل"، و 360–1440). `ShellHarness` يعرض الشاشة الحقيقية بـ `h.reports`؛ تسجيلات أقسام المال بالهارنس في `shell_money_fakes.dart` (`registerMoneyFakes`).

## 33. المدربون والتدريب: خطط التمارين والقياسات (مبنية ومختبرة)

- `/training` ← `TrainingScreen` (`Training.html`، `features/training`): تبويبا "خطط التمارين" و "القياسات" (`ValueCubit<int>`)، ورابط "المدربون" ← `Routes.staffMembers` (تبويب المدربين والعمال) لمن له `can_manage_staff`. الرابط `Routes.measurementsOf(id)` (`?tab=measurements&player_id=`) يفتح قياسات عضو، وبطاقة "التدريب" بملف العضو فيها "القياسات" إليه. **التعديل للمالك فقط**؛ الاستقبال يقرأ البرامج والقياسات حسب CLAUDE.md، مع أن الخادم يقبل كتابته.
- **البيانات** (`TrainingRepository`، تحت `/club-admin`): `plans(query)` ← `GET workout-plans` (`templates=1|0`، قاعدة boolean بلارافيل لا تقبل "true"؛ `search` بالعنوان؛ القائمة بلا `days` بل `days_count`)، `plan(id)` بأيامه، `savePlan(body, id:, idempotencyKey:)` (`POST` بمفتاح أو `PATCH`)، `deletePlan`، `assign(id, {player_id, starts_on?, ends_on?})` ← `POST …/assign` (نسخة جديدة باسم العضو، البداية افتراضياً اليوم)، `trainers()` ← `staff-members?type=trainer&status=active&per_page=100`، `member(id)` (الاسم والمعرّف للرابط)، `measurements(playerId, page:)` ← `GET players/{id}/measurements` (50 بالصفحة، الأحدث أولاً، `meta.progress` = آخر − أول لكل حقل أو null بقياس واحد)، `saveMeasurement` و `deleteMeasurement`.
- **الموديلات** (`training_models.dart`): `WorkoutPlan` (`TrainingRef` للعضو والمدرب، `byPlayer` = `source=player`)، `WorkoutDay` و `Exercise` (`weight_kg` و `duration_seconds` غير معروضين بالمحرر)، `BodyMeasurement` (`bmi` من الخادم)، `MeasurementsPage`، و `MeasureField` (المفتاح، الاسم، الوحدة، أقصى قيمة بالخادم، و `better` للون التقدم فقط)، و `TrainingTexts`. **لا "سجّله"**: الخادم لا يرسل من سجّل القياس.
- **المسودة** (`workout_draft.dart`): `WorkoutDraft` / `DayDraft` / `ExerciseDraft` بنصوص كما كُتبت ومعرّف محلي `uid` (مفتاح الحقل فيبقى بقيمته عند حذف ما قبله)، و `keep` يحفظ الوزن والمدة. `body()` جسم واحد للإضافة والتعديل (الأيام مرقّمة بترتيبها، `player_id` بالإضافة فقط)، و `validate()` بمفاتيح الخادم نفسها (`days.0.exercises.1.name`) فيظهر الخطأ المحلي و 422 تحت الحقل نفسه. الحدود: 14 يوماً، 40 تمريناً، المجموعات 1–50، الراحة 0–1800.
- **التبويب الأول** (`WorkoutPlansSection`): `WorkoutListCard` (عرض `AppSize.workoutListWidth` بجانب المحرر من `AppSize.profileSplit`، وأضيق فوقه): رقائق "لأعضاء / قوالب عامة" (`FilterChoiceChips(showAll: false)`)، البحث، شارتا "مؤرشفة" و "أضافها العضو"، "عرض المزيد"، و "+ خطة" للمالك. الأولى مختارة مبدئياً (`ValueCubit<int?>`، و `0` = خطة جديدة). `WorkoutEditor` (`WorkoutEditorCubit`): الرأس والشارات و "إسناد لعضو" والحذف، الحقول (العنوان، العضو بالبحث عند الإنشاء أو رابط ملفه، المدرب مع إبقاء مدرب غير فعّال باسمه، "من" و "إلى" حقلا تاريخ اختياريان بـ × لكل منهما، الحالة)، الوصف، ثم `WorkoutDayCard` لكل يوم (صف أعمدة من `AppSize.exerciseRowMin` وإلا بطاقة؛ بلا تلميح بالحقول الرقمية لأن الفارغ من الخادم كان يبدو قيمة)، "+ يوم" و "حفظ الخطة". الحفظ يحدّث القائمة ويختار المحفوظة، والإسناد ينقل لتبويب الأعضاء ويفتح النسخة.
- **القياسات** (`MeasurementsSection`): العضو بـ `QuickSearch.pick` (أو من الرابط بـ `TrainingMemberCubit`)، ثم `MeasurementsCubit` بمفتاح `(العضو، الصفحة)`: `MeasurementValues` (آخر قيمة غير فارغة لأهم خمسة حقول + المؤشر، والفرق "منذ البداية" من `progress`: أخضر إن كان بالاتجاه الأفضل وعنبري عكسه ومحايد للطول) و `WeightTrend` (بوزنين على الأقل) بالصفحة الأولى فقط، و "قياس جديد" بالرأس فقط حين توجد قياسات (الفارغ فيه زره)، ثم `MeasurementsTable` (أدنى عرض `AppSize.measurementsTableMin`، الحقول التسعة بأسماء قصيرة والوحدات بسطر تحت الجدول، والمؤشر والملاحظة، وللمالك تعديل وحذف) و `PaginationBar`. النافذة (`MeasurementActions`): التاريخ (حتى اليوم بتوقيت النادي)، تسعة حقول رقمية (الفاصلة عشرية، 0 حتى أقصى الخادم)، ملاحظات؛ بلا أي قيمة = فشل محلي؛ الإضافة بـ `IdempotencyKeeper` والتعديل `PATCH` والحقل الممسوح يُرسل null.
- **الرسم**: `WeightTrend` بـ `CustomPaint` (خطوط أفقية، خط الوزن LTR والمسافة بالأيام، نقطة آخر قياس، والتاريخان بالأسفل). **`fl_chart` 1.1 لا يُبنى على Flutter 3.32** (يستدعي `Matrix4.translateByDouble` من vector_math أحدث)، فلا تستورده حتى ترقية Flutter؛ كل رسوم المشروع مرسومة باليد.
- **core**: التوكنز `workoutListWidth`، `workoutFieldMin`، `exerciseRowMin`، `exerciseDeleteCol`، `trendChart`، `measureTileMin`، `measurementsTableMin`، `measureActionsCol`، `measureMemberMax`؛ و `FilterChoiceChips(showAll: false)`؛ و `Routes.measurementsOf`.
- **فُحص حياً** (2026-11-10، المالك على العضو 15): القراءة والمحرر، إضافة قياسين وتعديل بحقل ممسوح (المؤشر يُعاد حسابه null) وحذفهما، والعقد بنفس أجسام الواجهة (الفلتر، 201، PATCH، مفاتيح 422، الإسناد، الحذف).
- **لم يُبنَ**: تعديل الوزن أو المدة للتمرين (يُحفظان كما هما).
- الاختبارات: `test/features/training/` (`training_test.dart`: الموديلات بشكل الرد، النصوص، نقاط الرسم، جسم المسودة وتحققها، الـ Cubits، جسم القياس؛ `training_screen_test.dart`: القائمة والمحرر بأيامه ورابط المدربين، القوالب، خطة جديدة بالأخطاء المحلية والعضو والأيام والتمارين ومفتاحها، التعديل و 422، حذف يوم، الإسناد، الحذف، الاستقبال للقراءة، الفارغ، و 360–1440؛ `measurements_screen_test.dart`: بلا عضو ثم الاختيار والقيم والرسم والجدول، رابط الملف، الإضافة والتحقق والمفتاح، التعديل بالممسوح null، الحذف، الفارغ، الاستقبال، الصفحة الثانية، و 360–1440 مع النافذة). `ShellHarness` يعرض الشاشة الحقيقية بـ `h.training` (`registerTrainingFakes` بـ `fake_training_repository.dart`).

## 34. الإعلانات (مبنية ومختبرة)

- `/announcements` ← `AnnouncementsScreen` (`Announcements.html`، `features/announcements`)، **للمالك فقط** (القائمة الجانبية `_owner` حسب CLAUDE.md، مع أن الخادم يسمح للاستقبال بالقراءة). بطاقة واحدة: رقائق الحالة (الكل / منشورة / مسودات / منتهية = `state` بالخادم)، الشرح، و "إعلان جديد" (يغيب حين تعرض الحالة الفارغة زرها)، ثم `AnnouncementTile` لكل إعلان: شارة الحالة، العنوان، النص (3 أسطر)، سطر "الجمهور · الفرع · متى" وشارة الإشعار، و "تعديل" / حذف؛ والصفحات (20). القائمة **لا تتبع فرع الشريط العلوي**: فلتر `branch_id` بالخادم مطابقة تامة فيُخفي إعلانات كل الفروع.
- **العقد** (من `ClubAnnouncementController`، الـ YAML ناقص): `branch` = `{id, name}` أو null (الـ YAML يقول نص)؛ الجمهور `all | active | expired`؛ **لا جدولة**: `publish` (افتراضياً true) ينشر الآن، و `publish: false` مسودة، وبالتعديل `publish: false` يعيد المنشور مسودة ("إيقاف النشر"). `expires_at` (`after:now`) يُرسل نهاية يوم النادي المختار بـ UTC (`Formatters.clubDayEndUtc`). الإشعار `send_push` يُرسل بالخلفية **مرة واحدة** عند أول نشر (`pushed_at`، `push_recipients`). الحالة "مجدول" بالنموذج الأولي غير موجودة بالخادم فلم تُبنَ.
- **النافذة** (`AnnouncementActions` + `AnnouncementFields`، عرض `AppSize.announcementDialog`، والمعاينة تنزل تحت الحقول تحت `announcementSplit`): العنوان (150) والنص (5000) مطلوبان، الجمهور بشرح من يصله، الفرع ("كل الفروع" = null، والفرع الموقوف يبقى باسمه) حين يوجد أكثر من فرع، "ينتهي العرض" (`FormDate(clearable:, hint: 'بلا انتهاء')`)، ومفتاح الإشعار (أو سطر "أُرسل إشعاراً لـ N... لا يُعاد" بعد إرساله)، ومعاينة بطاقة تطبيق العضو. الأزرار: جديد/مسودة ← "نشر" + "حفظ مسودة"؛ منشور/منتهٍ ← "حفظ التعديل" (بلا `publish`) + "إيقاف النشر". `bodyOf` لا يرسل `send_push` بعد الإرسال، ولا `expires_at` إن لم يتغيّر يومه (فلا يتحرك وقته ولا يُرفض إعلان منتهٍ). الإضافة بـ `IdempotencyKeeper`، والحقول بأسماء مفاتيح الخادم فيظهر 422 تحت حقله.
- **الفروع بالنوافذ**: `FormDialog` يُفتح على الـ Navigator الجذري **خارج الهيكل**، فـ `BranchScopeCubit` غير موجود داخله: اقرأ الفروع من سياق الشاشة قبل فتح النافذة ومرّرها للحقول.
- **core**: `FormDialog.show(secondary: (label:, onSubmit:), maxWidth:)` زر ثانٍ يمرّ بنفس التحقق بجسمه هو (و "جارٍ التنفيذ…" على الزر المضغوط)؛ `FormDate(clearable:, hint:)`؛ `Formatters.clubDayEndUtc`؛ والتوكنز `announcementDialog` و `announcementSplit`. **تنبيه**: `FormText(validator:)` يحل محل تحقق `required`، فاجمعهما بـ `Validators.all([Validators.required(), ...])`.
- التحقق الحي (المالك): عقد الإنشاء مسودة بمفتاح (وإعادته بنفس المفتاح = نفس الإعلان)، فلتر `state=draft`، النشر بانتهاء، التعديل بلا `publish`، "إيقاف النشر"، 422 (`title`، `expires_at`)، والحذف؛ بإعلان تجريبي بلا إشعار حُذف. والواجهة (1280 والموبايل): القائمة ببيانات حقيقية، النافذة بالمعاينة الحية، حفظ مسودة تجريبية ثم حذفها من الشاشة.
- الاختبارات: `test/features/announcements/` (`announcements_test.dart`: الموديل والنصوص و `bodyOf` و `clubDay`؛ `announcements_screen_test.dart`: القائمة، رقائق الحالة، الفارغ بزر واحد، إعلان جديد بالتحقق والمعاينة ومسودة ونشر بمفتاح، تعديل المنشور (بلا إشعار، الانتهاء محفوظ، المسح، إيقاف النشر)، نشر المسودة، 422، الحذف، القسم للمالك، و 360–1440). `ShellHarness` يعرض الشاشة بـ `h.announcements`، واختبارات الهيكل العامة صارت تفتح `Routes.billing`.

## 35. الإعدادات والفروع (مبنية ومختبرة)

- `/settings` ← `SettingsScreen` (`features/settings`، **للمالك فقط**): تبويبا "النادي" (`ClubSettings.html`) و "الفروع" (`BranchSettings.html`) بـ `ValueCubit<int>`، و `Routes.settingsBranches` (`?tab=branches`) يفتح الفروع. `ClubCubit` مشترك بين التبويبين (حد الفروع)، والقوائم تُحمَّل عند فتح تبويبها (`BlocProvider` كسول).
- **البيانات** (`SettingsRepository`، تحت `/club-admin`): `club()` ← `GET club` (`ClubProfile`: الاسم والشعار من المنصة، التواصل، `settings` = `ClubSettings`، و `usage.branches {used, limit}` ← `branchLimitReached`)، `updateClub` ← `PATCH club` (**التواصل فقط**: `contact_phone` بصيغة `+…`، `contact_email`، `city`، `address`؛ الاسم وبادئة المعرّف لا تُعدَّل)، `updateSettings` ← `PATCH club/settings`، `notificationTypes()` ← `GET club/notification-types` (`types[{type, label, description, audience}]` بجماهير `owners / staff / player` + `platform_types` لا تُطفأ)، `uploadLogo` / `deleteLogo` ← `club/logo` (`logo`، 2MB)، `branches()` ← `GET branches?per_page=100` (الفعّالة والموقوفة، بلا المؤرشفة، الرئيسي أولاً)، `saveBranch(body, id:, idempotencyKey:)` (`POST` بمفتاح، يخضع لـ `PLAN_LIMIT_REACHED`، أو `PATCH`)، `setBranchStatus(id, active|inactive)` ← `POST branches/{id}/status`، `archiveBranch` ← `DELETE`.
- **تبويب النادي** (`ClubTab`): نموذج `AppFormCubit` واحد بأسماء مفاتيح الخادم (فيظهر 422 تحت حقله)، يُبنى من جديد مع كل نسخة من النادي ومع "إلغاء التغييرات" (عدّاد). البطاقات (`club_settings_cards.dart`): الهوية (`ClubLogo` يُحفظ فوراً لا مع النموذج، والاسم للقراءة "تحدده المنصة")، التشغيل (المنطقة الزمنية، نهاية يوم العمل 0–6، بداية الأسبوع، العطلة حتى 3)، الاشتراكات والدخول (أربعة أعداد بحدود الخادم `ClubForm.maxOf`، الدفع الجزئي، التذكير، تذييل الإيصال)، الدخول اليومي وبرامج الأعضاء، و `ClubNotificationsCard` (مفتاح لكل نوع مجمّع بالجمهور؛ المطفأ بقائمة `disabled_notifications`، وإشعارات المنصة سطر "تصل دائماً"). `ClubForm.save` يرسل **الطلب الذي تغيّر جسمه فقط** (مقارنة بالقيم الأولى)، وبلا تغيير "لا تغييرات للحفظ." بلا طلب؛ النص الممسوح يُرسل null. بعد الحفظ تحديث النادي، و `AuthRefreshed` إن تغيّرت المنطقة الزمنية أو الشعار.
- **تبويب الفروع** (`BranchesTab`): `BranchListCard` (عرض `AppSize.branchListWidth` بجانب المحرر من `AppSize.profileSplit`، وأضيق فوقه): "N من L"، "+ فرع" معطّل بحد الباقة، وسطر لكل فرع ("رئيسي · النظام · المدينة" وشارة فعّال / موقوف). المختار `ValueCubit<int?>` (null = الأول، 0 = جديد). `BranchEditor` + `BranchEditorCubit` (factoryParam بـ `BranchDraft`، يُنشأ من جديد مع كل فرع أو نسخة منه): بيانات الفرع بـ `DraftField` (الاسم، الهاتف، المدينة، العنوان، سعر الدخول اليومي "فارغ = سعر النادي")، والحالة بالرأس (شارة "الفرع الرئيسي"؛ إيقاف / تفعيل لغير الرئيسي، وأرشفة للموقوف فقط، كلها بتأكيد ثم تحديث القائمة و `BranchScopeCubit.refresh()`). **لا تعديل لـ `is_main`** (لا مسار بالخادم).
- **أقسام الذكور والإناث** (`BranchScheduleCard`): مختلط / أوقات منفصلة (`FilterChoiceChips(showAll: false)`؛ التحويل للأوقات المنفصلة بلا فترات يضيف فترة جاهزة)، ثم فترة لكل مجموعة: الأيام رقائق، من / إلى (`DraftField` LTR بعرض `AppSize.slotTimeField`، `8:00` يُقبل ويُرسل `08:00`)، القسم إناث / ذكور / مختلط، "حذف الفترة"، و "(حتى اليوم التالي)" حين `to` قبل `from`؛ "+ إضافة فترة" حتى 21، وتنبيه "خارج كل الفترات الفرع مغلق". `BranchDraft.body()` جسم واحد للإضافة والتعديل؛ **المختلط لا يرسل `gender_schedule`** فيبقى المحفوظ للعودة إليه، والأيام تُرسل بترتيب الأسبوع. `validate()` بمفاتيح الخادم (`gender_schedule.0.from`) فيظهر الخطأ المحلي و 422 تحت الحقل نفسه. الإضافة بـ `IdempotencyKeeper`.
- **العقد** (من المتحكمات؛ الـ YAML ناقص): الاسم فريد ("يوجد فرع بنفس الاسم")، `time_split` يحتاج جدولاً، الرئيسي لا يُوقف (`409` "لا يمكن إيقاف الفرع الرئيسي")، الأرشفة للموقوف فقط (`409` "أوقف الفرع أولاً ثم أرشفه")، والإيقاف مع وردية مفتوحة `409`. مفاتيح الإشعارات مثل `club_new_member` (مفتاح غير معروف أو نوع منصة ← 422 "نوع إشعار غير معروف").
- **core**: التوكنز `settingsFieldMin`، `settingsFieldMax`، `settingsMax`، `branchListWidth`، `slotTimeField`؛ و `Routes.settingsBranches`.
- **فُحص حياً** (2026-11-10، المالك): `PATCH club/settings` بجسم الواجهة الكامل (أيام السماح وإشعار مطفأ ثم الإرجاع)، 422 للعطلة فوق 3 وأيام السماح فوق 30 ونوع المنصة، `PATCH club` بنفس القيم و 422 للهاتف والبريد؛ وفرع تجريبي: الإضافة بمفتاح (وإعادته = نفس الفرع، والاستعمال 3 من 10)، التحويل لمختلط يبقي الجدول، 422 (اسم مكرر ومفاتيح الفترات)، أرشفة الفعّال 409، الإيقاف، إيقاف الرئيسي 409، ثم الأرشفة.
- **لم يُبنَ**: تعديل اسم النادي وبادئة المعرّف (من المنصة)، وتعيين فرع رئيسي آخر.
- الاختبارات: `test/features/settings/` (`settings_test.dart`: الموديلات بشكل الرد، النصوص، المسودة وجسمها وتحققها، `ClubForm` (القيم الأولى، بلا تغيير، المتغيّر فقط، العطلة فوق 3)، و `BranchEditorCubit` (الفترات، التحقق المحلي، المفتاح للإضافة، 422)؛ `club_settings_screen_test.dart`: البطاقات والإشعارات بالجمهور، الحفظ بلا تغيير، الإعدادات وإشعار مطفأ، التواصل والممسوح null، الحدود المحلية، 422، الإلغاء، إزالة الشعار، الخطأ، رابط تبويب الفروع، للمالك فقط، و 360–1440 للتبويبين؛ `branch_settings_screen_test.dart`: القائمة والاستعمال والرئيسي، الفترات وبعد منتصف الليل، الحفظ الكامل، التحويل للأوقات المنفصلة والفترات، أخطاء الفترة، إضافة فرع بمفتاح، رفض الخادم، حد الباقة، الإيقاف والتفعيل والأرشفة، 409، والخطأ). `ShellHarness` يعرض الشاشة الحقيقية بـ `h.settings`.

## 36. الموظفون والحسابات (مبنية ومختبرة)

- `/staff` ← `StaffScreen` (`Staff.html`، `features/staff`، للمالك بصلاحية `can_manage_staff`): `StaffLimitCard` ثم ثلاثة تبويبات (`ValueCubit<int>`، شريطها يتمرر أفقياً إن ضاق): حسابات الاستقبال / المدربون والعمال (`Routes.staffMembers` = `?tab=staff`، ورابط "المدربون" بالتدريب يفتحه) / كل الحسابات (`Routes.staffAccounts` = `?tab=accounts`). القوائم تُحمَّل عند فتح تبويبها (`BlocProvider` كسول)، وأفعال الصف بقائمة ⋯ (`MenuAnchor`)، وكل فعل يرجع true فتُحدَّث الصفحة الحالية بـ `keepPage`.
- **البيانات** (`StaffRepository`، تحت `/club-admin`؛ العقد من المتحكمات، الـ YAML ناقص):
  - `usage()` ← `GET club` (`usage.staff {used, limit}`): **المالك والاستقبال فقط**، المدربون والعمال لا يُحسبون، فنص البطاقة يقول ذلك بخلاف النموذج.
  - الاستقبال: `receptionists` (`status` active|suspended، `archived=only`، `search`؛ كل صف بـ `branches[{id,name}]` و `member_code` و `must_change_password`)، `addReceptionist` (`{name, phone, email?, branch_ids≥1}` بمفتاح؛ الرد بكلمة السر المؤقتة مرة واحدة أو `is_existing_account`؛ 409 للرقم الحالي أو المؤرشف، `PLAN_LIMIT_REACHED`)، `updateReceptionist` (`PATCH` الاسم والموبايل والبريد)، `setReceptionistBranches` (`PUT …/branches`)، الإيقاف بسبب إلزامي، التفعيل، الأرشفة (`DELETE`)، الاسترجاع.
  - المدربون والعمال: `staffMembers` (`type`، `status` active|inactive، `branch_id`، `archived=only`؛ الأرشيف يرجع بلا علامة فيعلّمه الـ datasource بـ `asArchived()`)، `saveStaffMember` (`POST` بمفتاح أو `PATCH`)، الأرشفة (409 بسلف غير مسددة) والاسترجاع.
  - الحسابات: `accounts` (`role`، `state`، `search`؛ `meta.summary` عدّادات الحالات، و `blocked_reason` / `shared_account` لكل صف)، `resetPasswords` (`{user_ids}` أو `{state: never_logged_in|expired, role?, valid_days 1..30}` ← `credentials` و `skipped` بأسبابها؛ ينهي الجلسات)، `cardsPdf` (`POST accounts/cards/pdf {cards}` ← `BlobOpener`؛ **الخادم لا يحفظ الكلمات**، فالبطاقات تُرسل من الرد نفسه)، `regenerateCode`، `endSessions` (`DELETE accounts/{id}/sessions`).
- **الموديلات**: `staff_models.dart` (`Receptionist`، `ReceptionistCreated`، `StaffMember`) يصدّر `account_models.dart` (`ClubAccount` مع `canResetPassword`، `IssuedCredential` و `card()`، `ResetResult`، `StaffUsage`). النصوص والنغمات بـ `StaffTexts`: شارة الاستقبال مؤرشف ← موقوف ← "بانتظار تغيير كلمة السر" ← فعّال، والعمولة `20%` أو "`$5.00` لكل عميل" للمدرب فقط (المبلغ معزول بـ `Formatters.ltr` داخل جملة عربية، والخلية ليست LTR وإلا انقلب الترتيب).
- **حسابات الاستقبال** (`ReceptionTab`): الشرح و "طباعة بطاقات الدخول PDF" و "+ حساب استقبال"، ثم `PagedTable` (الاسم والبريد، الموبايل، المعرّف، الفروع، آخر دخول نسبياً أو "لم يدخل بعد"، الحالة) بالبحث و "الأرشيف" ورقائق الحالة (تُخفى بالأرشيف). النوافذ (`ReceptionActions`): الإضافة (رقائق الفروع إلزامية حين يتعدد الفرع، وإلا الفرع الوحيد تلقائياً) ثم `CredentialsDialog`، تعديل البيانات، الفروع (فرع الحساب غير الفعّال يبقى خياراً)، الإيقاف بسبب، التفعيل، الأرشفة والاسترجاع. بعد الإضافة أو الاسترجاع يتحدث حد الباقة.
- **أفعال الحساب** (`AccountActions` + `accountMenuItems`، مشتركة بين التبويبين): "كلمة سر جديدة" (`user_ids: [id]`)، "معرّف جديد" (القديم يتوقف)، "إنهاء الجلسات"، كلها بتأكيد؛ و `bulkReset` (الحالة برقائق، الدور إن لم يُثبَّت، صلاحية 1–30 يوماً، افتراضياً 7). النتيجة `IssuedCredentialsDialog`: رسالة الخادم، بطاقة لكل حساب (الاسم والدور، المعرّف والموبايل، الكلمة، الانتهاء، نسخ وواتساب)، المتخطاة بأسبابها، و "طباعة البطاقات PDF".
- **المدربون والعمال** (`StaffMembersTab`): رقائق النوع، الحالة، الفرع (حين يتعدد)، الأرشيف، والبحث. الأعمدة: الاسم والمسمى، النوع (مدرب info، غيره محايد)، الفرع، الراتب الأساسي بعملته، العمولة، "منذ" (`hired_on`)، الحالة. الصف يفتح التعديل. النافذة (`StaffMemberFields`): النوع، الاسم، المسمى، الفرع ("بلا فرع محدد") وتاريخ التعيين، الراتب (0–1e8) وعملته، الموبايل، العمولة للمدرب فقط (نسبة 0–100 أو مبلغ ثابت 0–100000 لكل عميل؛ حقلان باسمي مفتاحي الخادم `commission_percent` / `commission_fixed_usd` فيظهر 422 تحت الظاهر منهما؛ غير المدرب يُرسل صفراً ويزيل تحققهما)، الحالة بالتعديل فقط، الملاحظات. `body()` جسم واحد للإضافة (بمفتاح) والتعديل. أرشفة 409 (سلف مفتوحة) تظهر بالنافذة.
- **كل الحسابات** (`AccountsTab`): رقائق الحالة بعدّاداتها ("لم يدخل بعد (4)")، الدور، البحث، و "كلمات سر جديدة لمجموعة" (بدور الفلتر إن اختير). الصف: الحساب ("حسابك" لـ `is_self`)، الدور، الموبايل، آخر دخول، الحالة (`state_label` بنغمة `StaffTexts.stateTone`). `blocked_reason` يحل محل الأفعال كسطر معطّل، والحساب المرتبط بنادٍ آخر بلا كلمة سر ولا معرّف (إنهاء الجلسات فقط).
- **core**: التوكنز `staffIntroMax`، `receptionTableMin`، `staffTableMin`، `accountsTableMin`، `staffLimitBar`؛ و `Routes.staffMembers` / `Routes.staffAccounts`.
- **لم يُبنَ**: `GET accounts/options` (الحالات والصلاحية الافتراضية ثابتة بالواجهة)، "إجبار تغيير كلمة السر" (`force-password-change`)، وتفاصيل الموظف (`GET staff-members/{id}`: العملاء والسلف والرواتب؛ الرواتب والسلف بقسمها).
- `MutedCell(ltr: true)` سطر واحد يصغر (`FittedBox`) فلا ينكسر "2,500,000 ل.س" بعمود ضيق.
- **فُحص حياً** (2026-11-11، المالك): الأشكال الحقيقية للقوائم الثلاث و `accounts/options` تطابق الموديلات (`usage.staff.limit` null بهذه الباقة ← "2 / ∞")؛ وعلى حساب استقبال وموظف تجريبيين أُرشفا بالنهاية: الإنشاء بمفتاح وإعادته (نفس المعرّف، والاستعمال 3 ثم 2 بعد الأرشفة)، رقم مكرر 409، بلا فروع 422، التعديل، الفروع، الإيقاف بلا سبب 422 ثم بسبب ثم مكرراً 409، فلتر الموقوف، التفعيل، كلمة سر جديدة (`credentials` بلا متخطى) و `cards/pdf` (`login-cards.pdf`)، 422 للحالة والصلاحية بالجماعي (لم يُشغَّل جماعي حقيقي حتى لا تتغير كلمات الحسابات التجريبية)، معرّف جديد، إنهاء الجلسات (`terminated_count`)، و 409 على حسابك؛ والموظف: الإنشاء بعمولة ثابتة ومفتاح، التعديل لعامل متوقف، 422 (`commission_percent` فوق 100)، الأرشفة (الأرشيف يرجعه `inactive`) والاسترجاع. والواجهة بالمتصفح: التبويبات الثلاثة ببيانات حقيقية، `?tab=staff`، والعدّادات.
- **درس**: اختبارات الشاشات تسجّل مستودعات وهمية بنفسها ولا تمرّ على `registerFeatures`؛ تسجيل مكرر بـ `feature_injection.dart` أسقط التطبيق عند التشغيل فقط. `test/core/di/feature_injection_test.dart` يشغّل التسجيل الحقيقي على GetIt جديد.
- الاختبارات: `test/features/staff/` (`staff_test.dart`: الموديلات بشكل الرد، النصوص، جسم البطاقة، الحد، جسم الموظف للمدرب والعامل، الـ Cubits؛ `staff_screen_test.dart`: الحد والصفوف والتحميل الكسول، إضافة استقبال بالفروع والمفتاح وكلمة السر، 409، الإيقاف والفروع والتفعيل، كلمة سر جديدة والمتخطى والطباعة، البطاقات الجماعية وتحققها، الأرشيف، تبويب المدربين، مدرب بعمولة ثابتة وعامل بلا عمولة، التعديل و 409 الأرشفة، تبويب الحسابات بعدّاداته والحساب الممنوع والمشترك والجماعي، الصلاحية، فشل الحد والقائمة، و 360–1440 مع النوافذ). `ShellHarness` يعرض الشاشة بـ `h.staff` (`registerStaffFakes`).

## 37. أجهزة الاستقبال (مبنية ومختبرة)

- `/reception-devices` ← `ReceptionDevicesScreen` (`ReceptionDevices.html`، `features/reception_devices`، للمالك وميزة `offline_reception`؛ القسم مخفي بدونها ورابطه يعرض `PlanFeatureLocked`). الشاشة تنتظر استقرار `BranchScopeCubit` ثم `ReceptionDevicesCubit` (factoryParam بفرع الشريط، `BlocProvider` بمفتاحه).
- **البيانات** (`ReceptionDevicesRepository`، تحت `/club-admin/reception/devices`): `list(query, branchId:)` (فلاتر `status` active|revoked و `branch_id`)، و `revoke(id)` ← `POST …/{id}/revoke` (للمالك؛ الاستقبال 403، والموقوف مسبقاً `409` "الجهاز موقوف مسبقاً"). الجهاز يُسجَّل من شاشة الاستقبال نفسها (`POST reception/devices {device_uuid, name}`)، فاللوحة تعرض وتوقف فقط؛ لا حذف ولا تفعيل من جديد.
- **الموديل** `ReceptionDevice` (`device_uuid` ← `shortUuid` "7f3c…e91a" LTR مع تلميح بالكامل، الفرع، `last_pack_at`، `last_sync_at`، `created_at`)، و `DeviceTexts`: الحالة فعّال (success) / موقوف (neutral)، والوقت نسبياً ("قبل دقيقتين") أو "لم يحمّل بعد" / "لم يزامن بعد"، وبعد 30 يوماً تاريخ معزول بـ `Formatters.ltr`.
- **الشاشة**: `DeviceSetupCard` (ثلاث خطوات مرقّمة، `AppSize.deviceStepMax` و `stepBadge`) ← `DevicesTable` (`PagedTable`، أدنى عرض `AppSize.devicesTableMin`): الجهاز، الفرع، آخر تحميل للبيانات، آخر مزامنة، الحالة، و "إيقاف" للمالك على الفعّال فقط؛ رقائق الحالة، وحبة الفرع فقط حين الشريط على "كل الفروع"؛ الموبايل بطاقات `StaffMobileCard` ← ملاحظة "الجهاز الذي لم يزامن منذ مدة…".
- **الإيقاف** `DeviceActions.revoke`: `FormDialog(danger)` "إيقاف «الاسم»؟" بما يحدث وتنبيه بآخر مزامنة (أو "لم يزامن أي عملية بعد") ← تحديث الجدول بـ `keepPage`.
- **لم يُبنَ**: عمودا "سجّله" وعدد العمليات المنتظرة بالنموذج (الخادم لا يرسلهما).
- **فُحص حياً** (2026-11-11): جهاز تجريبي "جهاز تجريبي للفحص" (id 2، فرع المالكي) سُجّل بالـ API، وفلتر الفرع والحالة، وإيقاف الاستقبال 403، ثم **أُوقف من الواجهة** (يبقى موقوفاً بالقائمة). الجهاز 1 لم يُمس.
- الاختبارات: `test/features/reception_devices/` (الموديل والنصوص والـ Cubit، والشاشة: الصفوف والأوقات، الإيقاف والتحديث، رفض الخادم، فلتر الفرع وفرع الشريط، الرقائق والفارغ، الخطأ، و 360–1440). `ShellHarness` يعرضها بـ `h.admin.devices`.

## 38. اشتراك النادي والدعم وسجل النشاط (مبنية ومختبرة)

- `/billing` ← `BillingScreen` (`ClubBilling.html`، `features/billing`، **للمالك فقط**؛ الاستقبال 403 بالخادم). تبويبات `AppTabs` (`ValueCubit<int>` بمفتاح `?tab=`): "اشتراك النادي والفواتير" / "الدعم الفني" (`Routes.billingSupport`، و `Routes.supportTicket(id)` = `&ticket_id=`) / "سجل النشاط" (`Routes.activityLog`). `Routes.billingInvoice(id)` (`?invoice_id=`) يفتح نافذة الفاتورة فوق التبويب الأول (`OnInit`). Cubitات القوائم كسولة (`MultiBlocProvider`)، وشريط السماح أو القراءة فقط يعرضه الهيكل (`ClubPlanBanner`) لا الصفحة.
- **البيانات** (`billing_repository.dart`: ثلاث واجهات):
  - `BillingRepository`: `overview()` ← `GET billing/subscription` (`current` أو null، `history`، `balance{outstanding, overdue_invoices}`؛ `starts_at`/`ends_at`/`grace_ends_at` هنا **تواريخ** تُعرض كما هي)، `usage()` ← `GET club` (`usage.players/staff/branches {used, limit}` و `subscription.days_remaining`)، `invoices(query)` (`status`، `overdue` يُرسل 1، `search` بالرقم)، `invoice(id)` (+ `payments`)، `invoicePdf(id)` ← `BlobOpener`.
  - `SupportRepository`: `tickets(query)` (`status`، `category`، `search`)، `ticket(id)` ← `{ticket, replies, replies_truncated}`، `open(fields, files, idempotencyKey:)` و `reply(id, message, files, idempotencyKey:)` بـ multipart (`attachments[]`، حتى 5 ملفات و 5MB، الامتدادات `SupportTexts.attachmentExtensions`). الرد على مغلقة 409، والرد على محلولة يعيد فتحها. **لا حذف للتذاكر من النادي.**
  - `ActivityLogRepository`: `list(query)` (50 بالصفحة؛ `user_id`، `module`، `from`/`to`، `search`؛ الأقسام من `meta.modules`)، `entry(id)` (+ `old_values`، `new_values`، `ip_address`)، `users()` ← `GET accounts?role=club_owner` و `receptionist` بالتوازي.
- **التبويب الأول**: `SubscriptionCard` (الباقة والدورة `BillingTexts.title`، الشارة `Labels.tenantSubscription`، السطر "ينتهي بعد N" / "السماح حتى" / "للقراءة فقط"، الفترة، نهاية السماح، الميزات المشمولة من `ClubPlanCubit`، المستحق للمنصة مع شارة "فاتورة متأخرة"، الاشتراكات السابقة؛ بلا اشتراك: دعوة "فتح الدعم الفني") + `UsageCard` (عرض `AppSize.usageCardWidth` بجانبها من `profileSplit`: الأعضاء والموظفون والفروع "N / L" أو "∞" مع "بلا حد بباقتك"، حد التخزين من `entitlements.limits.storage_mb`؛ فشلها يخفيها) + `InvoicesTable` (`PagedTable`: الرقم، الفترة، المبلغ والمتبقي، الاستحقاق، الشارة `Labels.invoice(overdue:)`، PDF؛ البحث و "المتأخرة" ورقائق الحالة) ← `InvoiceDialog` (المبالغ، الدفعات بطريقتها ومرجعها، "تنزيل PDF").
- **الدعم**: `SupportTab` = `TicketListCard` (رقائق الحالة، "عرض المزيد"، "+ تذكرة"، الشارة "بانتظار ردك" تغلب الحالة) بجانب `TicketThreadCard` من `profileSplit` (عرض `AppSize.ticketListWidth`)، وأضيق فوقها. المحددة `ValueCubit<int?>` (null = الأولى). المحادثة: رسائل النادي بجهة البداية وفريق الدعم بجهة النهاية (أقصى عرض `AppSize.messageMax`)، المرفقات روابط موقّعة تُفتح بـ `Launcher.url`، ثم `ReplyBox` (نموذجه و `IdempotencyKeeper` يعيشان معه ويتجددان بعد كل رد) أو ملاحظة المغلقة. `SupportActions.open`: العنوان (200)، النوع `FormChoice`، الأولوية، الرسالة (10000)، `AttachmentsField`؛ الحقول بمفاتيح الخادم فيظهر 422 تحت حقله؛ بعد الإنشاء تُفتح التذكرة الجديدة.
- **سجل النشاط** `ActivityTab` (`PagedTable`، أدنى عرض `AppSize.activityTableMin`): الوقت، المستخدم (+ شارة "دعم UltraGym" لـ `by_platform_support`)، القسم، العملية، العنصر؛ الفلاتر: البحث، المستخدم (فشله يخفيه)، القسم، `FilterDateRange("كل السجل")`. `ActivityDialog`: المستخدم والوقت والعنصر والعملية و IP، ثم "ما تغيّر" (`ActivityEntry.changes`: المفاتيح التي اختلفت فقط، "قبل ← بعد"؛ الإنشاء "القيم المسجّلة") بمفاتيح الخادم كما هي.
- **core**: `PickedUpload` صار يحمل `bytes` و `size` و `part()` (جزء multipart جديد لكل إرسال، لأن جزء Dio لا يُرسل مرتين)، والتوكنز `billingLabelCol`، `invoicesTableMin`، `usageCardWidth`، `ticketListWidth`، `messageMax`، `activityTableMin`، `activityTimeCol`؛ وروابط الإشعارات `billing_invoice` (`invoice_id`) و `support_ticket` (`ticket_id`) و `billing`.
- **خلل بالخادم (مُبلَّغ، بلا التفاف بالواجهة)**: `created_at` بسجل النشاط بتوقيت النادي مع لاحقة `Z` (أي متأخر 3 ساعات عند العرض)، بخلاف باقي المسارات. الإصلاح بالخادم.
- **لم يُبنَ**: سعر الباقة واستعمال التخزين (الخادم لا يرسلهما)، وشريطا السماح والقراءة فقط داخل الصفحة (الهيكل يعرضهما).
- **فُحص حياً** (2026-11-11، قراءة فقط): الاشتراك (لا اشتراك بالقاعدة التجريبية)، الفواتير والتذاكر بالفلاتر (فارغة)، 404 للفاتورة والتذكرة والسجل، 422 لتذكرة فارغة بمفاتيح الحقول، 403 للاستقبال على الأربعة، وسجل النشاط بالفلاتر والتفاصيل. **لم تُنشأ تذكرة** (لا تُحذف). والواجهة بالمتصفح: التبويبات الثلاثة ببيانات حقيقية، الرابط `?tab=support`، 1280 داكن و 360 فاتح.
- الاختبارات: `test/features/billing/` (`billing_test.dart`: الموديلات والنصوص والـ Cubits؛ `billing_screen_test.dart`: الاشتراك والاستخدام، بلا اشتراك، السماح، الفواتير وفلاترها، النافذة و PDF، `?invoice_id=`، الفارغ والخطأ، و 360–1440؛ `support_screen_test.dart`: المحادثة، الرد ومفتاحه، 409، المغلقة والمحلولة، `?ticket_id=`، تذكرة جديدة و 422، الفارغ، سجل النشاط بفلاتره ونافذته، و 360–1440). `ShellHarness` يعرض الشاشتين بـ `h.admin` (`shell_admin_fakes.dart`)، **واختبارات الهيكل العامة صارت تفتح `pendingRoute`** (`/billing/1`: صفحة عنصر بلا شاشة) لأن كل الأقسام مبنية.

