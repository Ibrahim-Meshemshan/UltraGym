import '../../../../core/core.dart';
import '../../data/repo/membership_detail_repository.dart';
import '../../domain/models/membership_detail_models.dart';

/// صفحة اشتراك واحد (factoryParam بالمعرّف). بعد أي عملية: `refresh()` صامت.
class MembershipDetailCubit extends LoadCubit<MembershipDetail> {
  MembershipDetailCubit(MembershipDetailRepository repo, this.id) : super(() => repo.detail(id));

  final int id;
}

/// زيارات العضو خلال فترة الاشتراك (10 بالصفحة).
typedef MembershipAttendanceArgs = ({int playerId, DateTime? from, DateTime? to});

class MembershipAttendanceCubit extends ListCubit<AttendanceEntry> {
  MembershipAttendanceCubit(MembershipDetailRepository repo, MembershipAttendanceArgs a)
    : super(
        (q) => repo.attendance(q, playerId: a.playerId, from: a.from, to: a.to),
        query: const ListQuery(perPage: perPage),
      );

  static const perPage = 10;
}
