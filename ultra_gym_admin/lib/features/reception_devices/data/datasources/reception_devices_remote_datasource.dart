import '../../../../core/core.dart';
import '../../domain/models/reception_device_models.dart';
import '../repo/reception_devices_repository.dart';

class ReceptionDevicesRemoteDataSource implements ReceptionDevicesRepository {
  ReceptionDevicesRemoteDataSource(this._api);

  final ApiClient _api;
  static const _path = '/club-admin/reception/devices';

  @override
  Future<ApiResult<Paged<ReceptionDevice>>> list(ListQuery query, {int? branchId}) =>
      _api.getPaged(_path, fromJson: ReceptionDevice.fromJson, query: query, extra: {'branch_id': ?branchId});

  @override
  Future<ApiResult<ReceptionDevice>> revoke(int id) =>
      _api.post('$_path/$id/revoke', parse: Parse.object(ReceptionDevice.fromJson));
}
