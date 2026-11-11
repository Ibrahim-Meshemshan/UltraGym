import '../../../../core/core.dart';
import '../../data/repo/staff_repository.dart';
import '../../domain/models/staff_models.dart';

/// حد حسابات الموظفين بالباقة.
class StaffUsageCubit extends LoadCubit<StaffUsage> {
  StaffUsageCubit(StaffRepository repo) : super(repo.usage);
}

/// حسابات الاستقبال (الأحدث أولاً). الأرشيف بفلتر `archived=only`.
class ReceptionistsCubit extends ListCubit<Receptionist> {
  ReceptionistsCubit(StaffRepository repo) : super((q) => repo.receptionists(q));
}

/// المدربون والعمال.
class StaffMembersCubit extends ListCubit<StaffMember> {
  StaffMembersCubit(StaffRepository repo) : super((q) => repo.staffMembers(q));
}

/// كل حسابات النادي بحالة التفعيل، و `meta.summary` عدّادات الحالات.
class AccountsCubit extends ListCubit<ClubAccount> {
  AccountsCubit(StaffRepository repo) : super((q) => repo.accounts(q));
}
