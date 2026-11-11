import 'package:dio/dio.dart';
import 'package:ultra_gym_admin/core/networking/api_result.dart';
import 'package:ultra_gym_admin/core/networking/list_query.dart';
import 'package:ultra_gym_admin/core/networking/paged.dart';
import 'package:ultra_gym_admin/core/utils/json_x.dart';
import 'package:ultra_gym_admin/features/members/data/repo/member_profile_repository.dart';
import 'package:ultra_gym_admin/features/members/domain/models/member_models.dart';
import 'package:ultra_gym_admin/features/members/domain/models/member_profile_models.dart';

final Json _membershipJson = {
  'id': 3,
  'plan': {'id': 4, 'name': 'تدريب خاص شهري'},
  'type': 'duration',
  'branch': {'id': 1, 'name': 'الفرع الرئيسي - المزة'},
  'starts_on': '2026-10-25',
  'ends_on': '2026-11-23',
  'days_remaining': 15,
  'sessions_total': null,
  'sessions_remaining': null,
  'status': 'active',
  'status_label': 'فعّال',
  'frozen_until': null,
  'net_usd': 60,
  'paid_usd': 40,
  'due_usd': 20,
  'trainer': {'id': 1, 'name': 'كابتن مازن'},
};

/// رد حقيقي من `GET club-admin/players/3` (الخادم التجريبي، 2026-11-09) مع حقول ملف معبأة.
Json profileJson({String status = 'active', String? reason, String? archivedAt}) => {
  'id': 3,
  'name': 'أحمد الخطيب',
  'phone': '+963944100001',
  'email': null,
  'status': status,
  'suspended_at': status == 'suspended' ? '2026-11-05T09:00:00Z' : null,
  'suspension_reason': reason,
  'joined_at': '2026-09-27T09:00:00Z',
  'archived_at': archivedAt,
  'member_code': 'DMO-098969',
  'must_change_password': false,
  'last_login_at': null,
  'profile': {
    'branch': {'id': 1, 'name': 'الفرع الرئيسي - المزة'},
    'gender': 'male',
    'birth_date': '1996-04-12',
    'emergency_contact_name': 'نزار الخطيب',
    'emergency_contact_phone': '+963933001245',
    'address': null,
    'notes': 'يفضّل التمرين المسائي.',
    'photo_url': null,
  },
  'current_membership': _membershipJson,
  'memberships': [_membershipJson],
  'memberships_count': 1,
  'due_usd': 20,
  'stats': {'visits_total': 8, 'visits_this_month': 5, 'last_visit_at': '2026-11-08T11:58:43Z', 'paid_total_usd': 40},
  'latest_measurement': {'measured_on': '2026-11-06', 'weight_kg': 86, 'height_cm': 178, 'body_fat_percent': 18.9},
};

final ahmadProfile = MemberProfile.fromJson(profileJson());
final ahmadMembership = MembershipItem.fromJson(_membershipJson);

final Json attendanceJson = {
  'id': 39,
  'branch': {'id': 1, 'name': 'الفرع الرئيسي - المزة'},
  'checked_in_at': '2026-11-08T11:58:43Z',
  'method': 'manual',
  'status': 'accepted',
  'rejection_message': null,
  'in_grace': false,
};

final rejected = AttendanceEntry.fromJson({
  ...attendanceJson,
  'id': 30,
  'method': 'qr',
  'status': 'rejected',
  'rejection_message': 'ليس وقت قسمك',
});

final Json paymentJson = {
  'id': 4,
  'receipt_number': 'B1-2026-000004',
  'type_label': 'دفعة اشتراك',
  'direction': 'in',
  'currency': 'SYP',
  'amount': 130000,
  'business_date': '2026-10-25',
  'is_reversed': false,
};

Paged<T> onePage<T>(List<T> items) => Paged(
  items: items,
  pagination: Pagination(
    currentPage: 1,
    perPage: 10,
    total: items.length,
    lastPage: 1,
    from: items.isEmpty ? null : 1,
    to: items.isEmpty ? null : items.length,
  ),
);

final resetResult = NewMember.fromJson({
  'phone': '+963944100001',
  'member_code': 'DMO-098969',
  'temporary_password': '735190',
  'temporary_password_expires_at': '2026-11-16T10:00:00Z',
  'whatsapp_message': 'كلمة السر المؤقتة: 735190',
});

class FakeMemberProfileRepository implements MemberProfileRepository {
  ApiResult<MemberProfile> profileResult = ApiSuccess(ahmadProfile);
  ApiResult<void> actionResult = const ApiSuccess(null, message: 'تم');

  final profileCalls = <int>[];
  final updates = <Json>[];
  final suspended = <String>[];
  var activated = 0, resets = 0;
  final historyCalls = <String>[];

  @override
  Future<ApiResult<MemberProfile>> profile(int id) async {
    profileCalls.add(id);
    return profileResult;
  }

  @override
  Future<ApiResult<void>> update(int id, Json body) async {
    updates.add(body);
    return actionResult;
  }

  @override
  Future<ApiResult<void>> suspend(int id, String reason) async {
    suspended.add(reason);
    return actionResult;
  }

  @override
  Future<ApiResult<void>> activate(int id) async {
    activated++;
    return actionResult;
  }

  @override
  Future<ApiResult<NewMember>> resetPassword(int id) async {
    resets++;
    return ApiSuccess(resetResult);
  }

  @override
  Future<ApiResult<void>> uploadPhoto(int id, FormData form) async => actionResult;

  @override
  Future<ApiResult<Paged<MembershipItem>>> memberships(int id, ListQuery query) async {
    historyCalls.add('memberships:${query.page}');
    return ApiSuccess(onePage([ahmadMembership]));
  }

  @override
  Future<ApiResult<Paged<AttendanceEntry>>> attendance(int id, ListQuery query) async {
    historyCalls.add('attendance:${query.page}');
    return ApiSuccess(onePage([AttendanceEntry.fromJson(attendanceJson), rejected]));
  }

  @override
  Future<ApiResult<Paged<PaymentEntry>>> payments(int id, ListQuery query) async {
    historyCalls.add('payments:${query.page}');
    return ApiSuccess(onePage([PaymentEntry.fromJson(paymentJson)]));
  }
}
