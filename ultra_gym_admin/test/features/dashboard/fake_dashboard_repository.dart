import 'package:ultra_gym_admin/core/networking/api_result.dart';
import 'package:ultra_gym_admin/core/utils/json_x.dart';
import 'package:ultra_gym_admin/features/dashboard/data/repo/dashboard_repository.dart';
import 'package:ultra_gym_admin/features/dashboard/domain/models/dashboard_models.dart';

/// رد المالك الحقيقي من الخادم التجريبي (2026-11-08) مع تنبيهين.
Json ownerJson() => asJson({
  'business_date': '2026-11-08',
  'exchange_rate': 13000,
  'players': {'total': 12, 'new_this_month': 3},
  'memberships': {'active': 9, 'frozen': 1, 'expiring_7_days': 2, 'in_grace': 1, 'sold_today': 2, 'sold_this_month': 4},
  'attendance': {'today': 7, 'rejected_today': 1, 'this_month': 21, 'visitors_today': 0},
  'day_passes': {'today': 0, 'this_month': 0},
  'debts': {'total_due_usd': 20, 'players': 1, 'total_due_syp': 260000},
  'cash_sessions': [
    {
      'branch': {'id': 1, 'name': 'الفرع الرئيسي - المزة'},
      'is_open': true,
      'session_id': 1,
      'opened_at': '2026-09-27T09:00:00Z',
      'balance': {'expected_usd': 314.5, 'expected_syp': 180000},
    },
    {
      'branch': {'id': 2, 'name': 'فرع المالكي'},
      'is_open': false,
      'session_id': null,
      'opened_at': null,
      'balance': null,
    },
  ],
  'finance': {
    'revenue_today_usd': 12,
    'revenue_month_usd': 33,
    'expenses_month_usd': 34.62,
    'net_month_usd': -1.62,
    'revenue_last_14_days': [
      for (var d = 26; d <= 31; d++) {'date': '2026-10-$d', 'revenue_usd': 0},
      for (var d = 1; d <= 8; d++) {'date': '2026-11-0$d', 'revenue_usd': d == 7 ? 21 : (d == 8 ? 12 : 0)},
    ],
  },
  'alerts': [
    {'type': 'cash_session_closed', 'message': 'يوجد فرع صندوقه مغلق'},
    {'type': 'memberships_expiring', 'message': '2 اشتراك ينتهي خلال 7 أيام'},
  ],
});

/// رد الاستقبال: بلا `finance`، ورصيد الصندوق `null`، وفرعه فقط.
Json receptionJson() {
  final j = ownerJson()..remove('finance');
  j['cash_sessions'] = [
    {
      'branch': {'id': 1, 'name': 'الفرع الرئيسي - المزة'},
      'is_open': true,
      'session_id': 1,
      'opened_at': '2026-09-27T09:00:00Z',
      'balance': null,
    },
  ];
  j['alerts'] = <Object>[];
  return j;
}

final ownerData = DashboardData.fromJson(ownerJson());
final receptionData = DashboardData.fromJson(receptionJson());

const expiringSoon = [
  ExpiringMembership(
    id: 3,
    playerName: 'أحمد الخطيب',
    planName: 'تدريب خاص شهري',
    branchName: 'الفرع الرئيسي - المزة',
    daysRemaining: 3,
    status: 'active',
    statusLabel: 'فعّال',
  ),
  ExpiringMembership(
    id: 8,
    playerName: 'لينا سعيد',
    planName: 'شهري',
    daysRemaining: 0,
    status: 'frozen',
    statusLabel: 'مجمّد',
  ),
];

/// مستودع وهمي: يرجع النتائج المضبوطة ويسجّل الفرع بكل طلب.
class FakeDashboardRepository implements DashboardRepository {
  FakeDashboardRepository({ApiResult<DashboardData>? summary, ApiResult<List<ExpiringMembership>>? expiring})
    : summaryResult = summary ?? ApiSuccess(ownerData),
      expiringResult = expiring ?? const ApiSuccess(expiringSoon);

  ApiResult<DashboardData> summaryResult;
  ApiResult<List<ExpiringMembership>> expiringResult;
  final summaryCalls = <int?>[];
  final expiringCalls = <int?>[];

  @override
  Future<ApiResult<DashboardData>> summary({int? branchId}) async {
    summaryCalls.add(branchId);
    return summaryResult;
  }

  @override
  Future<ApiResult<List<ExpiringMembership>>> expiring({int? branchId, int days = 7, int limit = 5}) async {
    expiringCalls.add(branchId);
    return expiringResult;
  }
}
