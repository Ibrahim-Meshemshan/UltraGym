import '../../../../core/core.dart';
import '../../data/repo/reception_devices_repository.dart';
import '../../domain/models/reception_device_models.dart';

/// الأجهزة المسجلة لفرع الشريط العلوي (null = كل الفروع، وحينها فلتر الفرع بالجدول).
class ReceptionDevicesCubit extends ListCubit<ReceptionDevice> {
  ReceptionDevicesCubit(ReceptionDevicesRepository repo, {int? branchId})
    : super((q) => repo.list(q, branchId: branchId));
}
