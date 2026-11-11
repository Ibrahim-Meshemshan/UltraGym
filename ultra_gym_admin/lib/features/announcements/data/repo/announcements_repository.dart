import '../../../../core/core.dart';
import '../../domain/models/announcements_models.dart';

/// إعلانات النادي للاعبين (`/club-admin/announcements`). القراءة للمالك والاستقبال، والنشر والتعديل والحذف للمالك.
abstract interface class AnnouncementsRepository {
  /// فلاتر `state` (`draft` / `published` / `expired`)، `branch_id`، `search` (بالعنوان)؛ الأحدث أولاً.
  Future<ApiResult<Paged<Announcement>>> announcements(ListQuery query);

  /// إضافة (`id` null، بمفتاح منع التكرار؛ `publish: false` = مسودة) أو تعديل (`PATCH` بالحقول المرسلة فقط).
  Future<ApiResult<Announcement>> save(Json body, {int? id, String? idempotencyKey});

  Future<ApiResult<void>> delete(int id);
}
