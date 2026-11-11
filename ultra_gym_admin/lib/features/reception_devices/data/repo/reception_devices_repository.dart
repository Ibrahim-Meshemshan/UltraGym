import '../../../../core/core.dart';
import '../../domain/models/reception_device_models.dart';

/// أجهزة الاستقبال (ميزة `offline_reception`، تحت `/club-admin/reception`).
abstract interface class ReceptionDevicesRepository {
  /// `GET reception/devices` بفلاتر `status` و `branch_id` (الأحدث مزامنة أولاً).
  Future<ApiResult<Paged<ReceptionDevice>>> list(ListQuery query, {int? branchId});

  /// `POST reception/devices/{id}/revoke` (للمالك؛ الموقوف مسبقاً ← 409).
  Future<ApiResult<ReceptionDevice>> revoke(int id);
}
