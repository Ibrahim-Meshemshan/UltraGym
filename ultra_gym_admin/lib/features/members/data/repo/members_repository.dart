import '../../../../core/core.dart';
import '../../domain/models/member_models.dart';

abstract interface class MembersRepository {
  /// `GET club-admin/players` بالبحث والفلاتر، و `archived=only` للأرشيف.
  Future<ApiResult<Paged<MemberRow>>> list(ListQuery query, {required MembersTab tab, int? branchId});

  /// عدد الأعضاء والأرشيف (طلبان بصف واحد بالتوازي).
  Future<ApiResult<MemberCounts>> counts({int? branchId});

  /// `POST club-admin/players` (مع `Idempotency-Key`).
  Future<ApiResult<NewMember>> create(Json body, {required String idempotencyKey});

  /// أرشفة (`DELETE players/{id}`) واسترجاع (`POST players/{id}/restore`): للمالك فقط.
  Future<ApiResult<void>> archive(int id);
  Future<ApiResult<void>> restore(int id);
}
