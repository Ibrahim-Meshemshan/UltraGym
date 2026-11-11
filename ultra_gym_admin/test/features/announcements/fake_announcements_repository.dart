import 'package:get_it/get_it.dart';
import 'package:ultra_gym_admin/core/networking/api_result.dart';
import 'package:ultra_gym_admin/core/networking/list_query.dart';
import 'package:ultra_gym_admin/core/networking/paged.dart';
import 'package:ultra_gym_admin/core/utils/json_x.dart';
import 'package:ultra_gym_admin/features/announcements/data/repo/announcements_repository.dart';
import 'package:ultra_gym_admin/features/announcements/domain/models/announcements_models.dart';
import 'package:ultra_gym_admin/features/announcements/presentation/bloc/announcements_cubit.dart';

/// إعلان بشكل رد `GET club-admin/announcements` (`ClubAnnouncementController::payload`).
Json announcementJson({
  int id = 1,
  String title = 'جهاز سكوات جديد',
  String body = 'وصل جهاز سكوات جديد لصالة الحديد. اسأل مدربك عن الطريقة الصحيحة.',
  String audience = 'all',
  Json? branch,
  bool sendPush = true,
  String? pushedAt = '2026-11-02T07:00:00Z',
  int? recipients = 12,
  String state = 'published',
  String? publishedAt = '2026-11-02T07:00:00Z',
  String? expiresAt = '2026-11-16T20:59:59Z',
}) => {
  'id': id,
  'title': title,
  'body': body,
  'audience': audience,
  'branch': branch,
  'send_push': sendPush,
  'pushed_at': pushedAt,
  'push_recipients': recipients,
  'state': state,
  'published_at': publishedAt,
  'expires_at': expiresAt,
  'created_at': publishedAt ?? '2026-11-03T08:00:00Z',
};

List<Announcement> announcementRows() => [
  Announcement.fromJson(announcementJson(branch: const {'id': 1, 'name': 'الفرع الرئيسي - المزة'})),
  Announcement.fromJson(
    announcementJson(
      id: 2,
      title: 'صيانة المكيفات',
      body: 'ستتوقف المكيفات في صالة اللياقة يوم السبت بين 8 و 11 صباحاً.',
      audience: 'active',
      branch: const {'id': 2, 'name': 'فرع المالكي'},
      sendPush: false,
      pushedAt: null,
      recipients: null,
      state: 'draft',
      publishedAt: null,
      expiresAt: null,
    ),
  ),
  Announcement.fromJson(
    announcementJson(
      id: 3,
      title: 'بطولة رفعة الموت',
      body: 'شكراً لكل المشاركين. النتائج معلقة عند الاستقبال.',
      audience: 'expired',
      state: 'expired',
      publishedAt: '2026-10-10T07:00:00Z',
      expiresAt: '2026-10-25T20:59:59Z',
      recipients: 40,
    ),
  ),
];

Paged<Announcement> announcementsPage([List<Announcement>? items, int lastPage = 1]) {
  final rows = items ?? announcementRows();
  return Paged(
    items: rows,
    pagination: Pagination(currentPage: 1, perPage: 20, total: rows.length, lastPage: lastPage),
  );
}

class FakeAnnouncementsRepository implements AnnouncementsRepository {
  ApiResult<Paged<Announcement>> listResult = ApiSuccess(announcementsPage());
  ApiResult<Announcement>? saveResult;
  ApiResult<void> deleteResult = const ApiSuccess(null);

  final queries = <ListQuery>[];
  final saved = <({Json body, int? id, String? key})>[];
  final deleted = <int>[];

  @override
  Future<ApiResult<Paged<Announcement>>> announcements(ListQuery query) async {
    queries.add(query);
    return listResult;
  }

  @override
  Future<ApiResult<Announcement>> save(Json body, {int? id, String? idempotencyKey}) async {
    saved.add((body: body, id: id, key: idempotencyKey));
    return saveResult ?? ApiSuccess(Announcement.fromJson({...announcementJson(id: id ?? 9), 'title': body['title']}));
  }

  @override
  Future<ApiResult<void>> delete(int id) async {
    deleted.add(id);
    return deleteResult;
  }
}

/// تسجيلات قسم الإعلانات بـ GetIt (الهارنس).
void registerAnnouncementsFakes(FakeAnnouncementsRepository repo) {
  GetIt.instance
    ..registerSingleton<AnnouncementsRepository>(repo)
    ..registerFactory(() => AnnouncementsCubit(repo));
}
