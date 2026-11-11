import 'package:flutter/material.dart';
import 'package:ultragym_design/ultragym_design.dart';

import '../responsive/responsive.dart';
import '../theme/app_tokens.dart';

/// محتوى أي قسم داخل الهيكل: أقصى عرض 1320 من طرف البداية، هوامش 24 (16 موبايل)، وفراغ 20 بين الأجزاء.
/// عنوان القسم بالشريط العلوي، فلا عنوان هنا.
class AppPage extends StatelessWidget {
  const AppPage({super.key, required this.children, this.scroll = true});

  final List<Widget> children;

  /// false للشاشات التي تدير تمريرها بنفسها (جدول بارتفاع الصفحة مثلاً).
  final bool scroll;

  @override
  Widget build(BuildContext context) {
    final content = Align(
      alignment: AlignmentDirectional.topStart,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSize.maxContent),
        child: Padding(
          padding: context.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: scroll ? MainAxisSize.min : MainAxisSize.max,
            children: [
              for (var i = 0; i < children.length; i++) ...[if (i > 0) AppSpace.gap5, children[i]],
            ],
          ),
        ),
      ),
    );
    return scroll ? SingleChildScrollView(child: content) : content;
  }
}

/// قسم لم تُبنَ شاشته بعد: يبقي القائمة صالحة للتنقل حتى تحل الشاشة الحقيقية محله.
class PendingSection extends StatelessWidget {
  const PendingSection({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => AppPage(
    children: [
      AppSpace.gap8,
      EmptyState(title: title, message: 'هذا القسم قيد البناء، ويصل بالتحديث القادم.'),
    ],
  );
}
