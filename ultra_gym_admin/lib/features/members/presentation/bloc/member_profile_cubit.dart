import 'package:dio/dio.dart';

import '../../../../core/core.dart';
import '../../data/repo/member_profile_repository.dart';
import '../../domain/models/member_models.dart';
import '../../domain/models/member_profile_models.dart';

/// ملف عضو واحد (factoryParam بالمعرّف). العمليات ترجع النتيجة للنافذة، والشاشة تحدّث بعدها بصمت.
class MemberProfileCubit extends LoadCubit<MemberProfile> {
  MemberProfileCubit(this._repo, this.id) : super(() => _repo.profile(id));

  final MemberProfileRepository _repo;
  final int id;

  Future<ApiResult<void>> update(Json body) => _repo.update(id, body);

  Future<ApiResult<void>> suspend(String reason) => _repo.suspend(id, reason);

  Future<ApiResult<void>> activate() => _repo.activate(id);

  Future<ApiResult<NewMember>> resetPassword() => _repo.resetPassword(id);

  Future<ApiResult<void>> uploadPhoto(FormData form) => _repo.uploadPhoto(id, form);
}

/// سجل تبويب واحد بملف العضو (الاشتراكات، الحضور، الدفعات)، 10 بالصفحة والأحدث أولاً.
/// يُنشأ لكل (عضو، تبويب) عبر `sl<MemberHistoryCubit<AttendanceEntry>>(param1: id)`.
class MemberHistoryCubit<T> extends ListCubit<T> {
  MemberHistoryCubit(super.fetch) : super(query: const ListQuery(perPage: perPage));

  static const perPage = 10;
}
