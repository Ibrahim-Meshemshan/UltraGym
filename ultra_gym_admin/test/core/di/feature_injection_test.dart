import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:ultra_gym_admin/core/di/feature_injection.dart';
import 'package:ultra_gym_admin/features/staff/data/repo/staff_repository.dart';
import 'package:ultra_gym_admin/features/staff/presentation/bloc/staff_cubits.dart';

/// اختبارات الشاشات تسجّل مستودعات وهمية بنفسها، فلا تمرّ على `registerFeatures` الحقيقي:
/// تسجيل مكرر هنا كان يُسقط التطبيق عند التشغيل فقط ("already registered inside GetIt").
void main() {
  test('registerFeatures registers every type exactly once', () async {
    final sl = GetIt.asNewInstance();
    expect(() => registerFeatures(sl), returnsNormally);
    expect(sl.isRegistered<StaffRepository>(), isTrue);
    expect(sl.isRegistered<AccountsCubit>(), isTrue);
    await sl.reset();
  });
}
