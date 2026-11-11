import 'package:flutter/widgets.dart';

/// ويدجت بنية: يطلب أول تحميل من Bloc موجود أعلى الشجرة عند دخول الشاشة.
/// (من الاستثناءات المسموحة لـ StatefulWidget: دورة الحياة فقط، بلا حالة شاشة.)
class OnInit extends StatefulWidget {
  const OnInit({super.key, required this.onInit, required this.child});

  final void Function(BuildContext context) onInit;
  final Widget child;

  @override
  State<OnInit> createState() => _OnInitState();
}

class _OnInitState extends State<OnInit> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onInit(context);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// نص باتجاه LTR داخل الواجهة العربية (أرقام، مبالغ، هواتف، معرّفات).
class LtrText extends StatelessWidget {
  const LtrText(this.text, {super.key, this.style, this.textAlign});

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) => Text(text, style: style, textAlign: textAlign, textDirection: TextDirection.ltr);
}
