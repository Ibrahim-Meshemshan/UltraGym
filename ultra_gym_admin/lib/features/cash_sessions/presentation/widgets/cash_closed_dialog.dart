import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../domain/models/cash_session_models.dart';
import 'cash_session_dialogs.dart';
import 'cash_session_panels.dart';

/// بعد الإغلاق: الجرد والفرق النهائي لكل عملة كما ثبّتها الخادم، و "تقرير الوردية" للطباعة.
abstract final class CashClosedDialog {
  static Future<void> show(BuildContext context, CashSession s) =>
      showDialog<void>(context: context, builder: (context) => _Body(s));
}

class _Body extends StatelessWidget {
  const _Body(this.s);

  final CashSession s;

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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpace.s4,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpace.s4),
                decoration: BoxDecoration(color: c.successSoft, borderRadius: AppRadius.fieldAll),
                child: Row(
                  spacing: AppSpace.s3,
                  children: [
                    Icon(Icons.check_circle_rounded, color: c.successInk),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تم إغلاق الوردية ${Formatters.ltr('#${s.id}')}',
                            style: UType.body(color: c.successInk).weight(600),
                          ),
                          Text(
                            [
                              ?s.branchName,
                              if (s.businessDate != null)
                                'يوم العمل ${Formatters.ltr(Formatters.date(s.businessDate))}',
                            ].join(' · '),
                            style: UType.caption(color: c.successInk),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              ResponsiveGrid(
                maxColumns: 2,
                children: [
                  CashCurrencyPanel(session: s, usd: true),
                  CashCurrencyPanel(session: s, usd: false),
                ],
              ),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: AppSpace.s2,
                runSpacing: AppSpace.s2,
                children: [
                  UGButton(
                    label: 'تقرير الوردية',
                    icon: Icons.download_rounded,
                    kind: UButtonKind.secondary,
                    onPressed: () => CashSessionActions.report(s.id),
                  ),
                  UGButton(label: 'تم', onPressed: () => Navigator.of(context).pop()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
