import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/models/announcements_models.dart';
import 'announcement_actions.dart';

/// حقول نافذة الإعلان، ومعاينته بتطبيق العضو بجانبها (وتحتها بالشاشة الضيقة).
class AnnouncementFields extends StatelessWidget {
  const AnnouncementFields({super.key, this.existing, required this.branches});

  final Announcement? existing;

  /// "كل الفروع" ثم الفروع الفعّالة (من سياق الشاشة؛ النافذة خارج الهيكل).
  final List<FormOption<int>> branches;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final fields = _Fields(existing: existing, branches: branches);
      const preview = _Preview();
      if (box.maxWidth < AppSize.announcementSplit) {
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: AppSpace.s5, children: [fields, preview]);
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpace.s5,
        children: [
          Expanded(flex: 3, child: fields),
          const Expanded(flex: 2, child: preview),
        ],
      );
    },
  );
}

class _Fields extends StatelessWidget {
  const _Fields({required this.existing, required this.branches});

  final Announcement? existing;
  final List<FormOption<int>> branches;

  /// مطلوب وبحد أقصى (المخصّص يحل محل تحقق `required` بـ FormText فيُجمعان هنا).
  static String? Function(String?) _max(int n) => Validators.all([
    Validators.required(),
    (v) => (v ?? '').trim().length > n ? 'أقصى طول $n حرفاً.' : null,
  ]);

  @override
  Widget build(BuildContext context) {
    final a = existing;
    final today = AnnouncementActions.clubDay(sl<ServerClock>().now())!;
    final saved = AnnouncementActions.clubDay(a?.expiresAt);
    return FormColumn(
      children: [
        FormText(AnnouncementActions.title, label: 'العنوان', required: true, validator: _max(150)),
        FormText(AnnouncementActions.body, label: 'النص', required: true, maxLines: 5, validator: _max(5000)),
        const FormChoice<String>(AnnouncementActions.audience, label: 'الجمهور', options: AnnouncementTexts.audiences),
        const _AudienceNote(),
        ResponsiveGrid(
          minItemWidth: AppSize.formFieldMin,
          maxColumns: 2,
          children: [
            if (branches.length > 1) FormDropdown<int>(AnnouncementActions.branch, label: 'الفرع', options: branches),
            FormDate(
              AnnouncementActions.expires,
              label: 'ينتهي العرض',
              hint: 'بلا انتهاء',
              clearable: true,
              // تاريخ إعلان منتهٍ قبل اليوم يبقى قابلاً للعرض بالمنتقي.
              firstDate: saved != null && saved.isBefore(today) ? saved : today,
              lastDate: DateTime(today.year + 2, today.month, today.day),
            ),
          ],
        ),
        if (a != null && a.pushed)
          Text(
            '${AnnouncementTexts.push(a)}. الإشعار يُرسل مرة واحدة ولا يُعاد بعد التعديل.',
            style: UType.label(color: context.colors.inkMuted),
          )
        else
          const FormSwitch(
            AnnouncementActions.push,
            label: 'إرسال إشعار للهاتف عند النشر',
            hint: 'مرة واحدة لأجهزة الجمهور، بالخلفية.',
          ),
      ],
    );
  }
}

/// من يصله الإعلان حسب الجمهور المختار.
class _AudienceNote extends StatelessWidget {
  const _AudienceNote();

  @override
  Widget build(BuildContext context) {
    final audience = context.select<AppFormCubit, Object?>((f) => f.value(AnnouncementActions.audience));
    final text = switch (audience) {
      'active' => 'من له اشتراك فعّال أو بأيام السماح أو مجمّد أو قادم.',
      'expired' => 'من ليس له اشتراك جارٍ، للتذكير بالتجديد.',
      _ => 'كل أعضاء النادي. إعلان الفرع يصل لمن سُجّل به أو اشترك فيه.',
    };
    return Text(text, style: UType.caption(color: context.colors.inkMuted));
  }
}

/// المعاينة كما تظهر ببطاقة الإعلان بتطبيق العضو.
class _Preview extends StatelessWidget {
  const _Preview();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final club = context.select<AuthBloc, String>((b) => b.state.session?.tenant?.name ?? AppConfig.appTitle);
    final (title, body) = context.select<AppFormCubit, (String, String)>(
      (f) => ('${f.value(AnnouncementActions.title) ?? ''}'.trim(), '${f.value(AnnouncementActions.body) ?? ''}'.trim()),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.s2,
      children: [
        const FieldLabel('معاينة في تطبيق العضو'),
        Container(
          padding: const EdgeInsets.all(AppSpace.s4),
          decoration: BoxDecoration(color: c.surfaceAlt, borderRadius: AppRadius.cardAll),
          child: Container(
            padding: const EdgeInsets.all(AppSpace.s4),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: AppRadius.cardAll,
              border: Border.all(color: c.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpace.s1,
              children: [
                Text('إعلان · $club', style: UType.caption(color: c.primaryInk)),
                Text(
                  title.isEmpty ? 'عنوان الإعلان' : title,
                  style: UType.h3(color: title.isEmpty ? c.inkFaint : c.ink),
                ),
                Text(
                  body.isEmpty ? 'يظهر النص هنا كما سيقرؤه العضو.' : body,
                  style: UType.label(color: body.isEmpty ? c.inkFaint : c.inkMuted),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
