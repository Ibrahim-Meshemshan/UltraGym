import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../data/repo/billing_repository.dart';
import 'attachments_field.dart';

/// "ردّك" تحت المحادثة: الرسالة والمرفقات ثم "إرسال" (`POST …/replies`؛ المغلقة ← 409 يظهر فوق الحقل).
/// النموذج يعيش مع الويدجت، ومفتاح منع التكرار يتجدد بعد كل رد ناجح.
class ReplyBox extends StatelessWidget {
  const ReplyBox({super.key, required this.ticketId, required this.onSent});

  final int ticketId;
  final VoidCallback onSent;

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(create: (_) => AppFormCubit()),
      BlocProvider(create: (_) => ValueCubit<IdempotencyKeeper>(IdempotencyKeeper())),
    ],
    child: _Box(ticketId: ticketId, onSent: onSent),
  );
}

class _Box extends StatelessWidget {
  const _Box({required this.ticketId, required this.onSent});

  final int ticketId;
  final VoidCallback onSent;

  Future<void> _send(BuildContext context) async {
    final form = context.read<AppFormCubit>();
    final keeper = context.read<ValueCubit<IdempotencyKeeper>>();
    final r = await form.submit((f) {
      final message = '${f.value('message') ?? ''}'.trim();
      final files = AttachmentsField.of(f);
      return sl<SupportRepository>().reply(
        ticketId,
        message,
        files,
        idempotencyKey: keeper.state.keyFor({'message': message, 'files': [for (final x in files) '${x.name}:${x.size}']}),
      );
    });
    if (!context.mounted) return;
    if (r case ApiSuccess(:final message)) {
      form.text('message').clear();
      form.set(AttachmentsField.name, const <PickedUpload>[]);
      keeper.set(IdempotencyKeeper());
      AppSnackbar.show(message ?? 'تم إرسال الرد.');
      onSent();
    }
  }

  @override
  Widget build(BuildContext context) {
    final submitting = context.select<AppFormCubit, bool>((f) => f.state.submitting);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.s3,
      children: [
        const FormErrorBanner(),
        FormText(
          'message',
          label: 'ردّك',
          hint: 'اكتب ردك',
          maxLines: 4,
          validator: Validators.required('اكتب ردك أولاً.'),
        ),
        const AttachmentsField(),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: UGButton(
            label: submitting ? 'جارٍ الإرسال…' : 'إرسال',
            icon: Icons.send_rounded,
            onPressed: submitting ? null : () => _send(context),
          ),
        ),
      ],
    );
  }
}
