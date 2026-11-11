import '../../../../core/core.dart';
import '../../domain/models/staff_models.dart';

/// الموظفون والحسابات: حسابات الاستقبال، المدربون والعمال (بلا دخول)، وكل حسابات النادي.
abstract interface class StaffRepository {
  Future<ApiResult<StaffUsage>> usage();

  // حسابات الاستقبال (`receptionists`).
  Future<ApiResult<Paged<Receptionist>>> receptionists(ListQuery query);
  Future<ApiResult<ReceptionistCreated>> addReceptionist(Json body, {String? idempotencyKey});
  Future<ApiResult<Receptionist>> updateReceptionist(int id, Json body);
  Future<ApiResult<void>> setReceptionistBranches(int id, List<int> branchIds);
  Future<ApiResult<void>> suspendReceptionist(int id, String reason);
  Future<ApiResult<void>> activateReceptionist(int id);
  Future<ApiResult<void>> archiveReceptionist(int id);
  Future<ApiResult<void>> restoreReceptionist(int id);

  // المدربون والعمال (`staff-members`).
  Future<ApiResult<Paged<StaffMember>>> staffMembers(ListQuery query);
  Future<ApiResult<StaffMember>> saveStaffMember(Json body, {int? id, String? idempotencyKey});
  Future<ApiResult<void>> archiveStaffMember(int id);
  Future<ApiResult<void>> restoreStaffMember(int id);

  // كل الحسابات (`accounts`).
  Future<ApiResult<Paged<ClubAccount>>> accounts(ListQuery query);
  Future<ApiResult<ResetResult>> resetPasswords(Json body);
  Future<ApiResult<FileBlob>> cardsPdf(List<IssuedCredential> credentials);
  Future<ApiResult<void>> regenerateCode(int userId);
  Future<ApiResult<void>> endSessions(int userId);
}
