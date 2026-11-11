import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../branches/presentation/bloc/branch_scope_cubit.dart';
import '../../data/repo/announcements_repository.dart';
import '../../domain/models/announcements_models.dart';
import 'announcement_fields.dart';

/// أفعال المالك على الإعلانات (`Announcements.html`): نافذة واحدة للإضافة والتعديل بزرين
/// ("نشر" و "حفظ مسودة"، أو "حفظ التعديل" و "إيقاف النشر" للمنشور)، والحذف. ترجع true إن تغيّر شيء.
abstract final class AnnouncementActions {
  /// أسماء الحقول = مفاتيح الخادم، فأخطاء 422 تظهر تحت حقولها.
  static const title = 'title',
      body = 'body',
      audience = 'audience',
      branch = 'branch_id',
      push = 'send_push',
      expires = 'expires_at';

  /// "كل الفروع" بقائمة الفرع (يُرسل null).
  static const allBranches = 0;

  /// اليوم (بتوقيت النادي) من وقت UTC، لمنتقي التاريخ.
  static DateTime? clubDay(DateTime? utc) {
    if (utc == null) return null;
    final t = Formatters.clubTime(utc);
    return DateTime(t.year, t.month, t.day);
  }

  /// جسم الطلب. [publish] null = لا يغيّر حالة النشر (تعديل المنشور).
  /// بالتعديل: الإشعار المُرسل لا يُعاد فلا يُرسل `send_push`، وتاريخ الانتهاء لا يُرسل إن لم يتغيّر يومه
  /// (فلا يتحرك وقته المحفوظ، ولا يرفضه الخادم بـ `after:now` لإعلان منتهٍ).
  static Json bodyOf(AppFormCubit f, {required bool? publish, Announcement? existing}) {
    final day = f.value(expires) as DateTime?;
    final branchId = f.value(branch) as int?;
    return {
      title: '${f.value(title) ?? ''}'.trim(),
      body: '${f.value(body) ?? ''}'.trim(),
      audience: f.value(audience) ?? 'all',
      branch: branchId == allBranches ? null : branchId,
      if (existing == null || !existing.pushed) push: f.value(push) == true,
      if (existing == null || day != clubDay(existing.expiresAt))
        expires: day == null ? null : Formatters.clubDayEndUtc(day).toIso8601String(),
      'publish': ?publish,
    };
  }

  static Future<bool> save(BuildContext context, {Announcement? existing}) async {
    final keeper = IdempotencyKeeper();
    final a = existing;
    final live = a != null && !a.isDraft;
    // النافذة على الـ Navigator الجذري خارج الهيكل: الفروع تُقرأ هنا من سياق الشاشة.
    final active = context.read<BranchScopeCubit>().state.active;
    final branches = <FormOption<int>>[
      (value: allBranches, label: 'كل الفروع'),
      for (final b in active) (value: b.id, label: b.name),
      // فرع الإعلان موقوف الآن: يبقى بالقائمة باسمه فلا يتغير دون قصد.
      if (a?.branch case final b? when !active.any((x) => x.id == b.id)) (value: b.id, label: b.name),
    ];
    Future<ApiResult<Announcement>> send(AppFormCubit form, {required bool? publish}) {
      final json = bodyOf(form, publish: publish, existing: a);
      return sl<AnnouncementsRepository>().save(
        json,
        id: a?.id,
        idempotencyKey: a == null ? keeper.keyFor(json) : null,
      );
    }

    final done = await FormDialog.show<Announcement>(
      context,
      title: a == null ? 'إعلان جديد' : 'تعديل الإعلان',
      icon: Icons.campaign_rounded,
      maxWidth: AppSize.announcementDialog,
      submitLabel: live ? 'حفظ التعديل' : 'نشر',
      initial: {
        title: a?.title ?? '',
        body: a?.body ?? '',
        audience: a?.audience ?? 'all',
        branch: a?.branch?.id ?? allBranches,
        push: a?.sendPush ?? true,
        expires: ?clubDay(a?.expiresAt),
      },
      fields: (_) => AnnouncementFields(existing: a, branches: branches),
      onSubmit: (form) => send(form, publish: live ? null : true),
      secondary: (
        label: live ? 'إيقاف النشر' : 'حفظ مسودة',
        onSubmit: (form) => send(form, publish: false),
      ),
    );
    return done != null;
  }

  static Future<bool> delete(BuildContext context, Announcement a) async {
    final done = await FormDialog.confirm<void>(
      context,
      title: 'حذف الإعلان',
      message: 'سيُحذف "${a.title}" ويختفي من تطبيق الأعضاء. لا يمكن التراجع؛ لإخفائه مؤقتاً استعمل "إيقاف النشر".',
      confirmLabel: 'حذف',
      icon: Icons.delete_outline_rounded,
      onConfirm: () => sl<AnnouncementsRepository>().delete(a.id),
    );
    return done != null;
  }
}
