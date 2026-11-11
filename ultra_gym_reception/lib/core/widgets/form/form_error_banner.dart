import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ultragym_design/ultragym_design.dart';

import '../../bloc/app_form_cubit.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';

/// الفشل العام (409، شبكة، بيانات دخول خاطئة) وأخطاء الحقول غير الظاهرة أعلى النموذج.
class FormErrorBanner extends StatelessWidget {
  const FormErrorBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return BlocBuilder<AppFormCubit, AppFormState>(
      buildWhen: (a, b) => a.failure != b.failure || a.fieldErrors != b.fieldErrors,
      builder: (context, state) {
        final lines = [if (state.failure != null) state.failure!.message, ...context.read<AppFormCubit>().orphanErrors];
        if (lines.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsetsDirectional.only(top: AppSpace.s4),
          child: Semantics(
            liveRegion: true,
            child: Container(
              padding: const EdgeInsets.all(AppSpace.s3),
              decoration: BoxDecoration(color: c.dangerSoft, borderRadius: AppRadius.smAll),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                for (final l in lines) Text(l, style: UType.body(color: c.dangerInk)),
              ]),
            ),
          ),
        );
      },
    );
  }
}
