import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/core.dart';
import '../bloc/station_bloc.dart';
import 'qr_scan_dialog.dart';

/// الحقل الدائم التركيز (قارئ الباركود يكتب ثم Enter: رمز QR أو معرّف ← دخول مباشر، والاسم أو الموبايل ← بحث)
/// وزر "مسح QR" بالكاميرا. بعد كل إدخال يُمسح الحقل ويعود له التركيز. Esc = العضو التالي.
/// `StatefulWidget` لدورة حياة الـ controller والتركيز فقط.
class StationInputBar extends StatefulWidget {
  const StationInputBar({super.key});

  @override
  State<StationInputBar> createState() => _StationInputBarState();
}

class _StationInputBarState extends State<StationInputBar> {
  final _text = TextEditingController();
  final _focus = FocusNode();

  void _submit(String raw) => context.read<StationBloc>().add(StationSubmitted(raw));

  Future<void> _scan() async {
    final raw = await sl<QrScanner>().scan(context);
    if (!mounted) return;
    if (raw != null) _submit(raw);
    _focus.requestFocus();
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final field = CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () => context.read<StationBloc>().add(const StationCleared()),
      },
      child: TextField(
        controller: _text,
        focusNode: _focus,
        autofocus: true,
        textInputAction: TextInputAction.search,
        onSubmitted: _submit,
        style: UType.bodyLg(color: c.ink),
        decoration: InputDecoration(
          hintText: 'الاسم أو الموبايل أو المعرّف · أو امسح الباركود',
          prefixIcon: Icon(Icons.search_rounded, color: c.inkMuted),
          suffixIcon: IconButton(
            tooltip: 'بحث',
            icon: const Icon(Icons.keyboard_return_rounded),
            onPressed: () => _submit(_text.text),
          ),
        ),
      ),
    );
    return BlocListener<StationBloc, StationState>(
      listenWhen: (a, b) => a.attempt != b.attempt,
      listener: (context, _) {
        _text.clear();
        _focus.requestFocus();
      },
      child: LayoutBuilder(
        builder: (context, box) {
          final scan = UGButton(
            label: 'مسح QR',
            icon: Icons.qr_code_scanner_rounded,
            kind: UButtonKind.secondary,
            large: true,
            expand: box.maxWidth < AppSize.scanDialog,
            onPressed: _scan,
          );
          if (box.maxWidth < AppSize.scanDialog) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpace.s3,
              children: [field, scan],
            );
          }
          return Row(
            spacing: AppSpace.s3,
            children: [
              Expanded(child: field),
              scan,
            ],
          );
        },
      ),
    );
  }
}
