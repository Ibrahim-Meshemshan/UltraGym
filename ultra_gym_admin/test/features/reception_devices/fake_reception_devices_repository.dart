import 'package:get_it/get_it.dart';
import 'package:ultra_gym_admin/core/core.dart';
import 'package:ultra_gym_admin/features/reception_devices/data/repo/reception_devices_repository.dart';
import 'package:ultra_gym_admin/features/reception_devices/domain/models/reception_device_models.dart';
import 'package:ultra_gym_admin/features/reception_devices/presentation/bloc/reception_devices_cubit.dart';

/// جهاز بشكل `ReceptionController::devicePayload` (من رد حقيقي).
Json deviceJson({
  int id = 1,
  String name = 'كاونتر الاستقبال الرئيسي',
  String status = 'active',
  String? lastSync = '2026-11-11T09:58:00Z',
  String? lastPack = '2026-11-11T09:57:00Z',
  int branchId = 1,
  String branch = 'الفرع الرئيسي',
}) => {
  'id': id,
  'device_uuid': 'e83cbfa6-4661-4ce1-9e36-635f4455a35b',
  'name': name,
  'branch': {'id': branchId, 'name': branch},
  'status': status,
  'last_pack_at': lastPack,
  'last_sync_at': lastSync,
  'created_at': '2026-11-08T11:58:43Z',
};

Paged<ReceptionDevice> devicesPage(List<Json> items) => Paged(
  items: [for (final j in items) ReceptionDevice.fromJson(j)],
  pagination: Pagination(currentPage: 1, perPage: 15, total: items.length, lastPage: 1),
);

class FakeReceptionDevicesRepository implements ReceptionDevicesRepository {
  ApiResult<Paged<ReceptionDevice>> listResult = ApiSuccess(
    devicesPage([
      deviceJson(),
      deviceJson(id: 2, name: 'تابلت المدخل الخلفي', lastSync: null, lastPack: null),
      deviceJson(id: 3, name: 'لابتوب قديم', status: 'revoked', branchId: 2, branch: 'فرع المالكي'),
    ]),
  );
  ApiResult<ReceptionDevice>? revokeResult;

  final queries = <({ListQuery query, int? branchId})>[];
  final revoked = <int>[];

  @override
  Future<ApiResult<Paged<ReceptionDevice>>> list(ListQuery query, {int? branchId}) async {
    queries.add((query: query, branchId: branchId));
    return listResult;
  }

  @override
  Future<ApiResult<ReceptionDevice>> revoke(int id) async {
    revoked.add(id);
    return revokeResult ??
        ApiSuccess(ReceptionDevice.fromJson(deviceJson(id: id, status: 'revoked')), message: 'تم إيقاف الجهاز');
  }
}

void registerDevicesFakes(FakeReceptionDevicesRepository repo) {
  GetIt.instance
    ..registerSingleton<ReceptionDevicesRepository>(repo)
    ..registerFactoryParam<ReceptionDevicesCubit, int?, void>((b, _) => ReceptionDevicesCubit(repo, branchId: b));
}
