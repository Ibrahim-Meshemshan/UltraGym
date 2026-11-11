import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../quick_search/presentation/widgets/quick_search_button.dart';
import '../../data/repo/training_repository.dart';
import '../../domain/models/training_models.dart';
import '../../domain/models/workout_draft.dart';

/// حذف خطة، وإسنادها لعضو (نسخة جديدة باسمه).
abstract final class WorkoutActions {
  /// يرجع true إن حُذفت.
  static Future<bool> delete(BuildContext context, WorkoutDraft d) async {
    final done = await FormDialog.confirm<void>(
      context,
      title: d.isTemplate ? 'حذف القالب' : 'حذف الخطة',
      message: d.isTemplate
          ? 'يُحذف القالب "${d.title}". الخطط المنسوخة منه للأعضاء تبقى كما هي.'
          : 'تُحذف خطة "${d.title}" وتختفي من تطبيق ${d.player?.name ?? 'العضو'}.',
      confirmLabel: 'حذف',
      icon: Icons.delete_outline_rounded,
      successMessage: 'تم حذف الخطة.',
      onConfirm: () => sl<TrainingRepository>().deletePlan(d.id!),
    );
    return done != null;
  }

  /// العضو بالبحث أولاً (النافذة فوق الهيكل لا ترى فرعه)، ثم التأكيد بتاريخي البداية والنهاية الاختياريين.
  static Future<WorkoutPlan?> assign(BuildContext context, WorkoutDraft d) async {
    final player = await QuickSearch.pick(context);
    if (player == null || !context.mounted) return null;
    final keeper = IdempotencyKeeper();
    final done = await FormDialog.show<WorkoutPlan>(
      context,
      title: 'إسناد الخطة لعضو',
      icon: Icons.person_add_alt_1_rounded,
      message:
          'تُنسخ "${d.title}" إلى ${player.name} وتظهر بتطبيقه. تعديل النسخة لا يغيّر الأصل. '
          'بلا تاريخ بداية تبدأ اليوم.',
      submitLabel: 'إسناد',
      successMessage: 'تم إسناد الخطة لـ ${player.name}.',
      fields: (_) => const FormColumn(
        children: [
          FormDate('starts_on', label: 'تبدأ'),
          FormDate('ends_on', label: 'تنتهي'),
        ],
      ),
      onSubmit: (form) {
        final body = {'player_id': player.id, ...form.apiBody()};
        return sl<TrainingRepository>().assign(d.id!, body, idempotencyKey: keeper.keyFor(body));
      },
    );
    return done?.data;
  }
}
