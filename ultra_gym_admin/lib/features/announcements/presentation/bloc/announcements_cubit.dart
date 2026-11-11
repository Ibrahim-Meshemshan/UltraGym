import '../../../../core/core.dart';
import '../../data/repo/announcements_repository.dart';
import '../../domain/models/announcements_models.dart';

/// قائمة الإعلانات (الأحدث أولاً، 20 بالصفحة) بفلتر الحالة.
class AnnouncementsCubit extends ListCubit<Announcement> {
  AnnouncementsCubit(AnnouncementsRepository repo)
    : super((q) => repo.announcements(q), query: const ListQuery(perPage: 20));
}
