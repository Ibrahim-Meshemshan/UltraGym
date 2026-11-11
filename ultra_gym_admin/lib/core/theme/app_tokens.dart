import 'package:flutter/widgets.dart';
import 'package:ultragym_design/ultragym_design.dart';

/// الخطوط: Changa للعرض والأرقام الكبيرة فقط، و Readex Pro لكل الواجهة. الأنماط من `UType`.
abstract final class AppFonts {
  static const display = UType.display;
  static const sans = UType.sans;
  static const package = UType.package;
}

/// المسافات على شبكة 4 (من حزمة الهوية). لا أرقام مسافات عشوائية بالواجهة.
abstract final class AppSpace {
  static const s1 = USpace.s1;
  static const s2 = USpace.s2;
  static const s3 = USpace.s3;
  static const s4 = USpace.s4;
  static const s5 = USpace.s5;
  static const s6 = USpace.s6;
  static const s8 = USpace.s8;
  static const s10 = USpace.s10;
  static const s12 = USpace.s12;
  static const s16 = USpace.s16;

  /// فراغات جاهزة تعمل داخل Row و Column.
  static const gap1 = SizedBox(width: USpace.s1, height: USpace.s1);
  static const gap2 = SizedBox(width: USpace.s2, height: USpace.s2);
  static const gap3 = SizedBox(width: USpace.s3, height: USpace.s3);
  static const gap4 = SizedBox(width: USpace.s4, height: USpace.s4);
  static const gap5 = SizedBox(width: USpace.s5, height: USpace.s5);
  static const gap6 = SizedBox(width: USpace.s6, height: USpace.s6);
  static const gap8 = SizedBox(width: USpace.s8, height: USpace.s8);
}

/// الزوايا. البطاقة شكلها توقيعي (`CutCard` / `CutCardBorder`)، لا تصنع زوايا بطاقة يدوياً.
abstract final class AppRadius {
  static const xs = URadius.xs;
  static const sm = URadius.sm;
  static const field = URadius.field;
  static const card = URadius.card;
  static const hero = URadius.hero;
  static const full = URadius.full;

  static const smAll = BorderRadius.all(Radius.circular(URadius.sm));
  static const fieldAll = BorderRadius.all(Radius.circular(URadius.field));
  static const cardAll = BorderRadius.all(Radius.circular(URadius.card));
  static const fullAll = BorderRadius.all(Radius.circular(URadius.full));

  /// عنصر القائمة الجانبية (كلوحة الديمو `--r-md`)، وحلقة تركيزه حوله بمسافة `AppSize.focusGap`.
  static const nav = 14.0;
  static const navAll = BorderRadius.all(Radius.circular(nav));
  static const navFocusAll = BorderRadius.all(Radius.circular(nav + AppSize.focusGap + AppSize.focusRing));
}

/// المقاسات الثابتة.
abstract final class AppSize {
  static const controlSm = USize.controlSm;
  static const control = USize.control;
  static const controlLg = USize.controlLg;
  static const topBar = USize.topBar;
  static const sidebar = USize.sidebar;
  static const sidebarCollapsed = USize.sidebarCollapsed;
  static const bottomNav = USize.bottomNav;
  static const tableRow = 52.0;
  static const maxContent = UBreakpoints.desktop;

  /// أيقونات الواجهة: عادية (القائمة، الأزرار) وصغيرة (داخل الحبوب والشارات).
  static const icon = 20.0;
  static const iconSm = 18.0;

  /// أصغر هدف ضغط باللمس.
  static const minTap = 48.0;

  /// عرض العمود بشبكة البطاقات (الأعمدة = العرض ÷ 230).
  static const gridItem = 230.0;

  /// حبة البحث بالشريط العلوي (`Dashboard.html`)، ونافذة البحث السريع.
  static const searchPill = 300.0;
  static const searchDialog = 560.0;

  /// قائمة الجرس المنسدلة (`SystemStates.html` `.np`) وأقصى ارتفاع لقائمتها.
  static const panel = 400.0;
  static const panelList = 440.0;

  /// ارتفاع ظل القوائم العائمة (الجرس).
  static const floatingElevation = 12.0;

  /// الرئيسية: أقل عرض لبطاقتين متجاورتين (`flex 2 : 1`)، ولأزرار بانر الترحيب (تحتاج 230 فراغاً للزخرفة).
  static const splitMin = 840.0;
  static const heroActions = 880.0;

  /// عمود رقم صغير داخل بطاقة (أرقام المال)، وارتفاع رسم أعمدة الإيراد.
  static const figure = 120.0;
  static const barChart = 180.0;

  /// الجداول (`.tbl` بالنموذج): أقل عرض قبل التمرير الأفقي، وزر الصفحة `.pg`.
  static const tableMin = 980.0;
  static const pageButton = USize.controlSm;

  /// شريط الفلاتر: حبة الفلتر `.pill` 38، ورقاقة الحالة `.chip` 34، وأقل عرض يضع البحث والفلاتر بسطر واحد.
  static const filterPill = 38.0;
  static const filterChip = USize.controlSm;
  static const filterRow = 760.0;

  /// عمود الإجراءات (⋯) بآخر الجدول، وعرض النوافذ (النماذج وبيانات الدخول).
  static const actionsCol = 72.0;
  static const dialog = 520.0;

  /// نافذة مسح QR بالكاميرا: سماكة إطار التصويب.
  static const scanFrameStroke = 3.0;

  /// عنصر القائمة الجانبية (`.snav__item` بالديمو: 44)، وحلقة تركيز لوحة المفاتيح: سمك 2 وبُعد 2 عن العنصر.
  static const navItem = 44.0;
  static const focusRing = 2.0;
  static const focusGap = 2.0;

  /// الصورة الدائرية بصف الجدول (`.av`).
  static const avatar = 36.0;

  /// ملف العضو: الصورة بالرأس (72)، عرض المحتوى الذي يظهر فيه العمود الجانبي، وأدنى عرض لجداول السجل.
  static const profileAvatar = 72.0;
  static const profileSplit = 960.0;
  static const historyTableMin = 600.0;

  /// جدول دفعات الاشتراك: عمود زر "الإيصال"، عمود رقم الإيصال (بسطر واحد)، وأدنى عرض للجدول.
  static const receiptCol = 96.0;
  static const receiptNumberCol = 170.0;
  static const paymentsTableMin = 900.0;

  /// دفتر الحركات: عمود الإجراءات (الإيصال + "عكس" أو "معكوسة")، عمود التاريخ بسطر واحد، وأدنى عرض للجدول.
  static const ledgerActionsCol = 132.0;
  static const ledgerDateCol = 100.0;
  static const ledgerTableMin = 1000.0;

  /// التصنيفات: أدنى عرض لمجموعة (المصاريف / الإيرادات) قبل أن تصيرا عموداً واحداً.
  static const categoryGroupMin = 380.0;

  /// الخطط: أدنى عرض لبطاقة الخطة، وأدنى عرض لحقل بصف حقول النموذج قبل أن تلتف تحت بعضها.
  static const planCardMin = 280.0;
  static const formFieldMin = 140.0;

  /// الكوبونات: أدنى عرض للجدول، وعرض شريط الاستخدام.
  static const couponsTableMin = 900.0;
  static const usageBar = 120.0;

  /// الرواتب: عرض قائمة الموظفين بجانب لوحة الراتب، وأدنى عرض لجدول السلف.
  static const staffListWidth = 300.0;
  static const advancesTableMin = 900.0;

  /// التقارير: عرض قائمة التقارير بجانب العارض، أدنى عرض لبطاقة الملخص، ولعمود بجداول التقرير.
  static const reportsListWidth = 300.0;
  static const reportSummaryMin = 170.0;
  static const reportColMin = 100.0;

  /// التدريب: عرض قائمة البرامج بجانب المحرر، أدنى عرض لحقل برأس المحرر، أدنى عرض لصف التمرين بأعمدته (وإلا يصير بطاقة)، عمود حذف التمرين،
  /// ارتفاع رسم الوزن، أدنى عرض لبطاقة القياس، أدنى عرض لجدول القياسات، عمود تعديل القياس وحذفه، وأقصى عرض لحقل العضو.
  static const workoutListWidth = 300.0;
  static const workoutFieldMin = 200.0;
  static const exerciseRowMin = 620.0;
  static const exerciseDeleteCol = 40.0;
  static const trendChart = 160.0;
  static const measureTileMin = 150.0;
  static const measurementsTableMin = 980.0;
  static const measureActionsCol = 104.0;
  static const measureMemberMax = 420.0;

  /// الإعلانات: عرض النافذة بالمعاينة (`Announcements.html`)، والعرض الذي تنزل تحته المعاينة تحت الحقول.
  static const announcementDialog = 860.0;
  static const announcementSplit = 640.0;

  /// الإعدادات (`ClubSettings.html`، `BranchSettings.html`): أدنى عرض حقل بالشبكة، أقصى عرض حقل منفرد،
  /// أقصى عرض عمود الإعدادات، عرض قائمة الفروع بجانب المحرر، وعرض حقل الوقت بالفترة.
  static const settingsFieldMin = 240.0;
  static const settingsFieldMax = 360.0;
  static const settingsMax = 920.0;
  static const branchListWidth = 300.0;
  static const slotTimeField = 96.0;

  /// الموظفون والحسابات: أقصى عرض لسطر شرح التبويب، أدنى عرض الجداول، وشريط حد الباقة.
  static const staffIntroMax = 640.0;
  static const receptionTableMin = 1000.0;
  static const staffTableMin = 1000.0;
  static const accountsTableMin = 980.0;
  static const staffLimitBar = 160.0;

  /// أجهزة الاستقبال: أدنى عرض الجدول، أقصى عرض خطوة التجهيز، وقطر رقمها.
  static const devicesTableMin = 1000.0;
  static const deviceStepMax = 320.0;
  static const stepBadge = 28.0;

  /// اشتراك النادي والدعم (`ClubBilling.html`): عمود العنوان بسطور البطاقة، أدنى عرض جدول الفواتير، عرض بطاقة
  /// الاستخدام بجانب الاشتراك، عرض قائمة التذاكر، أقصى عرض رسالة، وجدول سجل النشاط وعمود الوقت فيه.
  static const billingLabelCol = 140.0;
  static const invoicesTableMin = 760.0;
  static const usageCardWidth = 340.0;
  static const ticketListWidth = 340.0;
  static const messageMax = 560.0;
  static const activityTableMin = 900.0;
  static const activityTimeCol = 104.0;

  /// شريط التقدّم الرفيع أثناء إعادة التحميل (2px).
  static const progress = 2.0;

  // الحضور: ارتفاع رسم الدخول حسب الساعة
  static const hoursChart = 96.0;
}

/// مدد الحركة ومنحنياتها. كل حركة تفحص `AppMotion.reduced(context)`.
abstract final class AppMotion {
  static const instant = UMotionValues.press;
  static const fast = UMotionValues.fast;
  static const normal = UMotionValues.base;
  static const slow = UMotionValues.slow;
  static const entrance = UMotionValues.entrance;
  static const entranceStep = UMotionValues.entranceStep;

  static const curve = UMotionValues.standard;
  static const emphasized = UMotionValues.emphasized;
  static const exit = UMotionValues.exit;

  /// "تقليل الحركة" من إعدادات النظام.
  static bool reduced(BuildContext context) => UMotion.reduced(context);

  /// المدة نفسها، أو صفر مع "تقليل الحركة".
  static Duration of(BuildContext context, Duration d) => reduced(context) ? Duration.zero : d;
}
