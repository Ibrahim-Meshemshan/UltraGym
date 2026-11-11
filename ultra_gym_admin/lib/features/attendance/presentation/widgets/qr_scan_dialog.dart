import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/core.dart';

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

/// نافذة الكاميرا: العضو يعطي موبايله للموظف فيوجّه رمز التطبيق نحو كاميرا الجهاز. أول رمز عضو يغلقها.
/// رمز لا يخص UltraGym يبقيها مفتوحة مع تنبيه. `StatefulWidget` لدورة حياة الكاميرا فقط.
class QrScanDialog extends StatefulWidget {
  const QrScanDialog({super.key});

  static final _memberCode = RegExp(r'^[A-Za-z]{2,8}-\d{3,12}$');

  /// رمز يخص عضواً: QR التطبيق (`UG1.`) أو معرّف العضو (`DMO-123456`) المطبوع كباركود.
  static bool isMemberScan(String raw) => raw.startsWith('UG1.') || _memberCode.hasMatch(raw);

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
      if (QrScanDialog.isMemberScan(raw)) {
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
        constraints: const BoxConstraints(maxWidth: AppSize.dialog),
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
                      errorBuilder: (context, error) => _CameraMessage.error(error.errorCode),
                      placeholderBuilder: (context) => const _CameraMessage(
                        Icons.videocam_rounded,
                        'جارٍ تشغيل الكاميرا… إن طلب المتصفح الإذن فاضغط "سماح".',
                      ),
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

/// رسالة فوق مكان الصورة: قبل أن تبدأ (غالباً ينتظر المتصفح الإذن)، أو سبب تعذّرها وماذا يفعل الموظف.
/// البديل (قارئ الباركود أو كتابة المعرّف) متاح دائماً بنافذة التسجيل.
class _CameraMessage extends StatelessWidget {
  const _CameraMessage(this.icon, this.message);

  _CameraMessage.error(MobileScannerErrorCode code)
    : icon = Icons.videocam_off_rounded,
      message = switch (code) {
        MobileScannerErrorCode.permissionDenied =>
          'المتصفح لم يسمح بالكاميرا. اسمح بها من أيقونة القفل بجانب العنوان ثم افتح المسح مجدداً.',
        MobileScannerErrorCode.unsupported =>
          'هذا المتصفح أو الجهاز لا يدعم الكاميرا. استعمل قارئ الباركود أو اكتب معرّف العضو.',
        _ => 'تعذّر تشغيل الكاميرا. تأكد أنها موصولة وغير مستعملة ببرنامج آخر، ثم أعد المحاولة.',
      };

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.all(AppSpace.s6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: AppSpace.s3,
        children: [
          Icon(icon, color: c.sidebarInk, size: AppSize.control),
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
