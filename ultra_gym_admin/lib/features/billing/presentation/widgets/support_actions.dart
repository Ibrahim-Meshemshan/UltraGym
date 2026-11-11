import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../data/repo/billing_repository.dart';
import '../../domain/models/support_models.dart';
import 'attachments_field.dart';

/// فتح تذكرة دعم جديدة (`ClubBilling.html` · "+ تذكرة"): العنوان، النوع، الأولوية، الرسالة، والمرفقات.
/// الحقول بأسماء مفاتيح الخادم فيظهر 422 تحت حقله. يرجع التذكرة المنشأة أو null.
abstract final class SupportActions {
  static Future<SupportTicket?> open(BuildContext context) async {
    final keeper = IdempotencyKeeper();
    final done = await FormDialog.show<SupportTicket>(
      context,
      title: 'تذكرة دعم جديدة',
      icon: Icons.support_agent_rounded,
      message: 'يصل طلبك لفريق UltraGym، ويصلك إشعار بكل رد.',
      submitLabel: 'إرسال التذكرة',
      initial: const {'category': 'technical', 'priority': 'medium'},
      fields: (_) => FormColumn(
        children: [
          FormText(
            'subject',
            label: 'العنوان',
            hint: 'باختصار: ما المشكلة أو الطلب؟',
            required: true,
            validator: Validators.all([Validators.required('اكتب عنواناً للتذكرة.'), _max(200)]),
          ),
          const FormChoice<String>('category', label: 'النوع', options: SupportTexts.categories),
          const FormDropdown<String>('priority', label: 'الأولوية', options: SupportTexts.priorities),
          FormText(
            'message',
            label: 'الرسالة',
            hint: 'اشرح ما حدث وخطوات تكراره إن وُجدت.',
            required: true,
            maxLines: 5,
            validator: Validators.all([Validators.required('اكتب تفاصيل الطلب.'), _max(10000)]),
          ),
          const AttachmentsField(),
        ],
      ),
      onSubmit: (form) {
        final fields = form.apiBody(except: {AttachmentsField.name});
        final files = AttachmentsField.of(form);
        return sl<SupportRepository>().open(
          fields,
          files,
          idempotencyKey: keeper.keyFor({...fields, 'files': [for (final f in files) '${f.name}:${f.size}']}),
        );
      },
    );
    return done?.data;
  }

  static FieldValidator _max(int n) =>
      (v) => (v?.trim().length ?? 0) > n ? 'النص أطول من $n حرف.' : null;
}
