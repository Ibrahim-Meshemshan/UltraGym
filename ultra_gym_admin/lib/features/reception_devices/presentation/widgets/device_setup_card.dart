import 'package:flutter/material.dart';

import '../../../../core/core.dart';

/// "تجهيز جهاز جديد" (`ReceptionDevices.html`): الجهاز يُسجَّل من شاشة الاستقبال نفسها، فاللوحة تشرح الخطوات فقط.
class DeviceSetupCard extends StatelessWidget {
  const DeviceSetupCard({super.key});

  static const _steps = [
    'افتح شاشة الاستقبال على الجهاز وادخل بحساب استقبال أو حساب المالك.',
    'اختر الفرع واكتب اسماً للجهاز. يُسجَّل تلقائياً ويظهر هنا.',
    'ينزّل بيانات الفرع، ثم يحدّثها كل 5 دقائق ما دام متصلاً.',
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return CutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.s4,
        children: [
          Text('تجهيز جهاز جديد', style: UType.h3(color: c.ink)),
          Wrap(
            spacing: AppSpace.s5,
            runSpacing: AppSpace.s3,
            children: [for (final (i, s) in _steps.indexed) _Step(number: i + 1, text: s)],
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppSize.deviceStepMax),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpace.s3,
        children: [
          Container(
            width: AppSize.stepBadge,
            height: AppSize.stepBadge,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: c.primarySoft, shape: BoxShape.circle),
            child: Text('$number', style: UType.label(color: c.primaryInk).weight(700)),
          ),
          Flexible(child: Text(text, style: UType.label(color: c.ink))),
        ],
      ),
    );
  }
}
