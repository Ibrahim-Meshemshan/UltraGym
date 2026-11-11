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

- **الأدوار اللونية**: `bg`، `surface/surfaceAlt`، `line/lineStrong`، `ink/inkMuted/inkFaint`، `sidebar/sidebarInk/hero` (لون الهيكل)، `primary(+Hover/Soft/Ink/onPrimary)` = الفعل، `accent(+Soft/Ink/onAccent)` = اللمعة/المحدد/الإنجاز، `success/warning/danger/info` بثلاث درجات (قوي، Soft خلفية، Ink نص).
- **لون واحد لكل معنى.** زر أساسي واحد بكل شاشة. الخطر مختلف بوضوح عن الفعل.
- **الشارة دائماً**: خلفية هادئة + نص بالحبر + نقطة (`StatusBadge(label, tone: UTone.x)`). اللون وحده لا يكفي.
- النص فوق البرتقالي **فحمي** (`onPrimary`). الفولت لا يُكتب كنص على الفاتح: `accentInk`.
- **الخطوط**: Changa (`UType.displayXl/displayMd/stat`) للتحيات وشاشة الدخول وعناوين الحالات الفارغة والنجاح والأرقام الكبيرة فقط؛ لا لعناوين الصفحات ولا الأزرار ولا الجداول. Readex Pro لكل شيء آخر. الخطوط مضمّنة بالحزمة.
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
- **حالة التنفيذ الحالية**: core مبني ومختبر (القسم 16)، والدخول والجلسة والراوتر (القسم 17)، والهيكل ومحطة الدخول متصلة (القسم 18). الباقي: الجداول، العمل دون اتصال، وباقي الشاشات.

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
- `Slice<T>` + `LoadCubit<T>(fetch)` (`load / refresh / patch`) + `ListCubit<T>((query) => repo.list(query))` (`load / refresh / more / filter / search / clearFilters / query / patchItems`، والحالة `ListState`: `slice`، `query`، `loadingMore`، `moreFailure`، `canLoadMore`).
- `ValueCubit<T>` (`set / update`)، `ToggleCubit` (`toggle`)، `pullRefresh(bloc, () => bloc.add(...), busy: (s) => s.list.isLoading)`.
- `AppFormCubit(initial:)`: `text(name)`، `set(name, v)`، `value(name)`، `apiBody(keepNulls:, dateTimes:, except:)`، `payload`، `orphanErrors`، `submit((form) => repo.x(form.apiBody()))`.

**الواجهة**
- `SliceView<T>(slice:, loading:, builder:, onRetry:, isEmpty:, empty:, frame:)`، `ErrorState(failure:, onRetry:, compact:)`.
- الهياكل: `AppShimmer` + `ShimmerBox` / `ShimmerBox.circle` / `ShimmerCard`، وجاهزة: `ListShimmer`، `TableShimmer`، `StatsShimmer`، `DetailsShimmer`.
- النماذج: `FormDialog.show<R>(context, title:, fields: (form) => FormColumn(...), onSubmit:, initial:, icon:, submitLabel:, successMessage:, danger:)` يرجع `ApiSuccess<R>?`، و `FormDialog.confirm(context, title:, message:, confirmLabel:, onConfirm:)`. الحقول: `FormText(name, label:, required:, validator:, ltr:)`، `FormPassword`، `FormDropdown<T>(name, label:, options: [(value: 1, label: '...')])`، `FormDate`، `FormChips<T>`.
- `OnInit(onInit: (context) => ..., child:)`، `LtrText('$25.00')`، `AppSnackbar.show('تم الحفظ.')`.
- `context.isMobile / isTablet / isDesktop`، `context.responsive(mobile:, tablet:, desktop:)`، `context.pagePadding`، `ResponsiveGrid(children:)`.

**الأدوات**
- `Formatters`: `usd`، `syp`، `money(v, currency)`، `number`، `date(d, fromUtc:)`، `time`، `dateTime`، `relative(utc, now: sl<ServerClock>().now())`، `days(n)`، `greeting(utc)`، و `Formatters.setTimezone(tenant.timezone)` بعد الدخول.
- `Labels.membershipStatus(status).tone` (و `attendance`، `direction`، `cashSession`، `difference`، `tenantSubscription`، `invoice`، `alertLevel`، `role`، `gender`، `currency`).
- `Validators.required / email / phone / minLength / newPassword / matches / amount / all`، `Debouncer`، `Launcher.url / phone / whatsapp`، `FilePick.image()` ← `PickedUpload` (`form('photo')` أو `error`).

**لم يُبنَ بعد (الخطوة التالية)**: `core/layout` (AppShell / MobileShell / AppPage / OfflineBanner)، `blocRoute`، `PagedTable` + `FilterBar` + `AppDataTable`، `OptionsLoader`، `FormFile`، والرسوم (`TrendChart`، `BarsChart`).

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
- بعد الدخول: `Routes.home = Routes.station` (محطة الدخول، §18). حُذفت الرئيسية المؤقتة `features/home`.
- **اختبار ويدجت فيه زخارف دائمة**: لُف التطبيق بـ `MediaQuery(disableAnimations: true)` حتى يستقر `pumpAndSettle`، ولا تنتظر `bloc.stream` داخل `testWidgets` (لا يكتمل بالزمن الوهمي): افحص `bloc.state` بعد `pumpAndSettle`.

## 18. الهيكل ومحطة الدخول (مبني ومختبر، متصل فقط)

`core/layout/` + `features/station/` (`Reception.html`). الاختبارات في `test/features/station/`.

- **الهيكل** `ReceptionShell(child:)`: شريط أيقونات ضيق بلون `sidebar` (`AppSize.rail`، يختفي على الموبايل؛ الآن "محطة الدخول" فقط، والأقسام الأخرى تُضاف حين تُبنى) + `ReceptionTopBar` (اسم الفرع مع اختيار الفرع إن كان للموظف أكثر من فرع، تحته التاريخ و"قسم: ذكور الآن" من `StationBranch.sectionAt` بتوقيت النادي ويتحدث كل `AppConfig.clockTick`، شارة "متصل / دون اتصال" من `ConnectionCubit`، الثيم، والموظف مع "تسجيل الخروج") + شريط "جلسة دعم" + شريط الانقطاع. لا شارة وردية ولا جرس بعد (الصندوق والإشعارات لم تُبنَ).
- **الفرع** `ActiveBranchCubit` (lazySingleton): `GET club-admin/branches` (الخادم يحصرها بفروع الموظف) عند كل فتح للمحطة؛ المختار محفوظ بـ `reception.branch_id` ← الرئيسي ← الأول. المحطة تبدأ بعد وصول القائمة فقط (لا طلب بفرع موظف سابق).
- **`StationRepository`**: `branches()`، `today(branchId)` ← `GET attendance/today` (`accepted`، `rejected`، `in_grace`، و `latest[]` آخر الدخول بشكل سجل الحضور)، `lookup(q, branchId)` ← `GET players/lookup` (مع `can_enter` و `rejection_message`)، `checkIn(body, idempotencyKey:)` ← `POST attendance/check-in` (201 مقبول، 200 `ALREADY_CHECKED_IN` مكرر، 409 بسجل = **نتيجة مرفوضة** لا خطأ، وغير ذلك فشل: 422 `QR_*`، 404، شبكة).
- **الإدخال** `StationInput.parse`: `UG1.` ← `qr_token` **كما هو** (التوقيع حساس للأحرف)، `ABC-123456` ← `member_code` بأحرف كبيرة، غير ذلك بحث بالاسم أو الموبايل ← قائمة نتائج، والضغط على عضو ← `player_id`. الجسم دائماً مع `branch_id` المحطة.
- **`StationBloc`** (factory): كل إدخال بمفتاح منع تكرار جديد؛ فشل الشبكة يبقى معلقاً و "إعادة المحاولة" (`StationRetried`) يرسله **بنفس المفتاح**؛ بعد أي تسجيل غير مكرر يتحدث حضور اليوم. `attempt` يزيد مع كل إدخال: الحقل يُمسح ويعود له التركيز. Esc أو "العضو التالي" = `StationCleared`.
- **الحقل** `StationInputBar`: دائم التركيز (قارئ الباركود يكتب ثم Enter)، وزر **"مسح QR"** ← `sl<QrScanner>().scan(context)`: `CameraQrScanner` يفتح `QrScanDialog` (`mobile_scanner`: كاميرا المتصفح، أول رمز عضو يغلقها، رمز غريب يبقيها مع تنبيه، "تبديل الكاميرا"، ورسائل رفض الإذن / عدم الدعم / التعذر). الاختبارات تسجّل `FakeQrScanner` بدلها (الكاميرا لا تعمل في الاختبار).
- **النتيجة** `OutcomePanel`: جاهز للمسح (دعوة) ← نتائج البحث ← هيكل التسجيل ← `CheckInCard` (شريط الحكم: مقبول + الوقت، بفترة السماح، مكرر "لم يُسجَّل دخول جديد"، مرفوض + الرمز؛ ثم الأحرف الأولى والاسم وحالة الاشتراك والمعرّف والموبايل، وخانات الخطة / المتبقي (`MemberMembership.remaining` من قيم الخادم دون حساب) / الدين) أو بطاقة فشل (QR: "اطلب من العضو تحديث الرمز"، 404، شبكة + إعادة المحاولة).
- **"دخول اليوم"** `TodayCard`: المقبول والمرفوض و `latest[]` (الوقت، الأحرف الأولى، الطريقة: QR / المعرّف / بحث يدوي / دخول يومي + سبب الرفض + "دون اتصال").
- **لم يُبنَ بعد**: العمل دون اتصال (الحزمة، التحقق المحلي من QR بـ `cryptography`، الـ outbox، المزامنة؛ الآن الانقطاع يظهر بطاقة فشل شبكة مع إعادة المحاولة)، أزرار "تجديد / سداد الدين / ملف العضو" وبطاقات "خصم جلسة / بيع / تجميد" وبطاقة الصندوق (شاشاتها لم تُبنَ)، الجرس، والصوت.
