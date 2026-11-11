import 'dart:async';

import 'package:ultra_gym_admin/core/networking/api_result.dart';
import 'package:ultra_gym_admin/features/quick_search/data/repo/quick_search_repository.dart';
import 'package:ultra_gym_admin/features/quick_search/domain/models/quick_search_models.dart';

const ahmad = LookupPlayer(
  id: 3,
  name: 'أحمد الخطيب',
  phone: '+963944100001',
  memberCode: 'DMO-098969',
  canEnter: true,
  membership: LookupMembership(id: 3, status: 'active', statusLabel: 'فعّال', planName: 'تدريب خاص شهري', dueUsd: 20),
);

const sami = LookupPlayer(
  id: 7,
  name: 'سامي منتهٍ',
  phone: '+963944100005',
  rejectionReason: 'EXPIRED',
  rejectionMessage: 'انتهى اشتراك العضو. جدّد الاشتراك ثم سجّل الدخول.',
  membership: LookupMembership(id: 9, status: 'expired', statusLabel: 'منتهٍ'),
);

/// بحث وهمي: يرجع من يحوي اسمه أو موبايله النص، ويسجّل كل طلب.
/// `hold` يعلّق الرد حتى يُكمله الاختبار (لاختبار الردود القديمة).
class FakeQuickSearchRepository implements QuickSearchRepository {
  final calls = <(String, int?)>[];
  Completer<void>? hold;

  @override
  Future<ApiResult<List<LookupPlayer>>> lookup(String q, {int? branchId}) async {
    calls.add((q, branchId));
    final gate = hold;
    if (gate != null) await gate.future;
    return ApiSuccess([
      for (final p in [ahmad, sami])
        if (p.name.contains(q) || (p.phone ?? '').contains(q)) p,
    ]);
  }
}
