import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/core.dart';
import '../../domain/models/check_in_models.dart';

/// مصدر رمز العضو بالكاميرا. خلف واجهة حتى تستبدله الاختبارات (الكاميرا لا تعمل فيها).
abstract interface class QrScanner {
  /// يفتح الكاميرا ويرجع أول رمز عضو مقروء (QR التطبيق أو المعرّف)، أو null عند الإلغاء.
  Future<String?> scan(BuildContext context);
}

class CameraQrScanner implements QrScanner {
  const CameraQrScanner();

  @override
  Future<String?> scan(BuildContext context) =>
      showDialog<String>(context: context, builder: (_) => const QrScanDialog());
}

/// نافذة الكاميرا: العضو يعطي موبايله للموظف فيوجّه رمز التطبيق نحو كاميرا الجهاز. أول رمز صالح يغلقها.
/// رمز لا يخص UltraGym يبقيها مفتوحة مع تنبيه. `StatefulWidget` لدورة حياة الكاميرا فقط.
class QrScanDialog extends StatefulWidget {
  const QrScanDialog({super.key});

  @override
  State<QrScanDialog> createState() => _QrScanDialogState();
}

class _QrScanDialogState extends State<QrScanDialog> {
  final _controller = MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates);
  final _notMember = ToggleCubit();
  var _done = false;

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    for (final b in capture.barcodes) {
      final raw = b.rawValue?.trim() ?? '';
      if (raw.isEmpty) continue;
      if (StationInput.parse(raw) case QrInput() || CodeInput()) {
        _done = true;
        Navigator.of(context).pop(raw);
        return;
      }
      if (!_notMember.state) _notMember.toggle();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _notMember.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpace.s4),
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(AppRadius.hero))),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSize.scanDialog),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpace.s6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpace.s4,
            children: [
              Row(
                spacing: AppSpace.s3,
                children: [
                  const IconSlab(Icons.qr_code_scanner_rounded, size: AppSize.control),
                  Expanded(
                    child: Text('مسح رمز QR', style: UType.h2(color: c.ink)),
                  ),
                ],
              ),
              ClipRRect(
                borderRadius: AppRadius.cardAll,
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: ColoredBox(
                    color: c.hero,
                    child: MobileScanner(
                      controller: _controller,
                      onDetect: _onDetect,
                      errorBuilder: (context, error) => _CameraError(error.errorCode),
                      placeholderBuilder: (context) => const _CameraStarting(),
                      overlayBuilder: (context, _) => const _ScanFrame(),
                    ),
                  ),
                ),
              ),
              BlocBuilder<ToggleCubit, bool>(
                bloc: _notMember,
                builder: (context, wrong) => Text(
                  wrong
                      ? 'هذا الرمز لا يخص عضواً. افتح بطاقة الدخول بتطبيق UltraGym ثم امسحها.'
                      : 'وجّه رمز QR من تطبيق العضو نحو الكاميرا. الرمز يتجدد كل 10 ثوانٍ.',
                  style: UType.body(color: wrong ? c.warningInk : c.inkMuted),
                ),
              ),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: AppSpace.s2,
                runSpacing: AppSpace.s2,
                children: [
                  UGButton(
                    label: 'تبديل الكاميرا',
                    icon: Icons.cameraswitch_rounded,
                    kind: UButtonKind.ghost,
                    onPressed: _controller.switchCamera,
                  ),
                  UGButton(label: 'إلغاء', kind: UButtonKind.secondary, onPressed: () => Navigator.of(context).pop()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// إطار التصويب فوق صورة الكاميرا.
class _ScanFrame extends StatelessWidget {
  const _ScanFrame();

  @override
  Widget build(BuildContext context) => Center(
    child: FractionallySizedBox(
      widthFactor: 0.55,
      child: AspectRatio(
        aspectRatio: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: context.colors.accent, width: AppSize.scanFrameStroke),
            borderRadius: AppRadius.cardAll,
          ),
        ),
      ),
    ),
  );
}

/// قبل أن تبدأ الصورة: غالباً المتصفح ينتظر إذن الكاميرا.
class _CameraStarting extends StatelessWidget {
  const _CameraStarting();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.all(AppSpace.s6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: AppSpace.s3,
        children: [
          Icon(Icons.videocam_rounded, color: c.sidebarInk, size: AppSize.control),
          Text(
            'جارٍ تشغيل الكاميرا… إن طلب المتصفح الإذن فاضغط "سماح".',
            textAlign: TextAlign.center,
            style: UType.body(color: c.sidebarInk),
          ),
        ],
      ),
    );
  }
}

/// الكاميرا لم تعمل: السبب وماذا يفعل الموظف، والبديل (قارئ الباركود أو الكتابة) متاح دائماً.
class _CameraError extends StatelessWidget {
  const _CameraError(this.code);

  final MobileScannerErrorCode code;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final message = switch (code) {
      MobileScannerErrorCode.permissionDenied =>
        'المتصفح لم يسمح بالكاميرا. اسمح بها من أيقونة القفل بجانب العنوان ثم افتح المسح مجدداً.',
      MobileScannerErrorCode.unsupported =>
        'هذا المتصفح أو الجهاز لا يدعم الكاميرا. استعمل قارئ الباركود أو اكتب معرّف العضو.',
      _ => 'تعذّر تشغيل الكاميرا. تأكد أنها موصولة وغير مستعملة ببرنامج آخر، ثم أعد المحاولة.',
    };
    return Padding(
      padding: const EdgeInsets.all(AppSpace.s6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: AppSpace.s3,
        children: [
          Icon(Icons.videocam_off_rounded, color: c.sidebarInk, size: AppSize.control),
          Text(
            message,
            textAlign: TextAlign.center,
            style: UType.body(color: c.sidebarInk),
          ),
        ],
      ),
    );
  }
}
