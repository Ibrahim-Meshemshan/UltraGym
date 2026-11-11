/// كل مسارات التطبيق. لا مسار مكتوب نصاً داخل أي شاشة.
abstract final class Routes {
  // البوابات (قبل الدخول)
  static const splash = '/';
  static const login = '/login';
  static const changePassword = '/change-password';
  static const offline = '/offline';
  static const blocked = '/blocked';
  static const updateRequired = '/update-required';

  // أقسام اللوحة (داخل الهيكل AppShell، وعناصرها بـ `core/layout/nav_config.dart`)
  static const dashboard = '/dashboard';
  static const members = '/members';
  static const memberships = '/memberships';
  static const attendance = '/attendance';
  static const dayPasses = '/day-passes';
  static const cashSessions = '/cash-sessions';
  static const payroll = '/payroll';
  static const reports = '/reports';
  static const plans = '/plans';
  static const training = '/training';
  static const announcements = '/announcements';
  static const settings = '/settings';

  /// تبويب الفروع بالإعدادات.
  static const settingsBranches = '$settings?tab=branches';
  static const staff = '/staff';

  /// تبويبا المدربين والعمال وكل الحسابات بالموظفين.
  static const staffMembers = '$staff?tab=staff';
  static const staffAccounts = '$staff?tab=accounts';
  static const receptionDevices = '/reception-devices';
  static const billing = '/billing';

  /// تبويبا الدعم الفني وسجل النشاط باشتراك النادي، وروابط الإشعارات: تذكرة محددة، أو فاتورة فوق التبويب الأول.
  static const billingSupport = '$billing?tab=support';
  static const activityLog = '$billing?tab=activity';
  static String supportTicket(int id) => '$billingSupport&ticket_id=$id';
  static String billingInvoice(int id) => '$billing?invoice_id=$id';

  /// بيع اشتراك (صفحة فرعية بالاشتراكات، قبل `:id`)، و `sellTo(12)` يفتحها على عضو محدد.
  static const sellMembership = '$memberships/new';
  static String sellTo(int playerId) => '$sellMembership?player_id=$playerId';

  /// تبويب القياسات بقسم التدريب على عضو محدد (من ملفه).
  static String measurementsOf(int playerId) => '$training?tab=measurements&player_id=$playerId';

  /// دفتر الحركات (تبويب بقسم "الصندوق والحركات"، قبل `:id`).
  static const transactions = '$cashSessions/transactions';

  /// الإعدادات المالية (تبويبان بنفس القسم): سعر الصرف وسجله، والتصنيفات.
  static const exchangeRate = '$cashSessions/exchange-rate';
  static const financeCategories = '$cashSessions/categories';

  /// مسار فرعي بمعرّف: `Routes.child(Routes.members, 12)` ← `/members/12`.
  static String child(String base, Object id) => '$base/$id';
}
