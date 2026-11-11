import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../bloc/announcements_cubit.dart';
import '../widgets/announcements_list.dart';

/// الإعلانات (`Announcements.html`، للمالك فقط حسب CLAUDE.md): بطاقة واحدة فيها فلتر الحالة و "إعلان جديد"،
/// ثم الإعلانات بحالتها وجمهورها وفرعها ووقت نشرها وشارة الإشعار، و "تعديل" / حذف.
/// القائمة لا تتبع فرع الشريط العلوي: فلتر الخادم بالفرع يُخفي إعلانات كل الفروع، والفرع ظاهر بكل إعلان.
class AnnouncementsScreen extends StatelessWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => sl<AnnouncementsCubit>()..load(),
    child: const AppPage(children: [AnnouncementsList()]),
  );
}
