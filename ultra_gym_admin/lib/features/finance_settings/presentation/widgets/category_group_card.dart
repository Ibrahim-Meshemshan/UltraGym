import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../transactions/domain/models/transaction_models.dart';
import 'category_actions.dart';

/// مجموعة تصنيفات بنوع واحد (`FinanceSettings.html`): العنوان و "+ تصنيف" (للمالك)، ثم سطر لكل تصنيف
/// بعدد حركاته وحالته و "تعديل" / حذف غير المستعمل.
class CategoryGroupCard extends StatelessWidget {
  const CategoryGroupCard({super.key, required this.kind, required this.items, required this.owner});

  final String kind;
  final List<FinanceCategory> items;
  final bool owner;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final income = kind == 'income';
    return CutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.s3,
        children: [
          Row(
            spacing: AppSpace.s3,
            children: [
              Expanded(
                child: Text(
                  income ? 'تصنيفات الإيرادات الأخرى' : 'تصنيفات المصاريف',
                  style: UType.h3(color: c.ink),
                ),
              ),
              if (owner)
                UGButton(
                  label: 'تصنيف',
                  icon: Icons.add_rounded,
                  kind: UButtonKind.secondary,
                  onPressed: () => CategoryActions.add(context, kind),
                ),
            ],
          ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.s4),
              child: Text(
                owner
                    ? 'لا تصنيفات ${income ? 'إيراد' : 'مصروف'} بعد. أضف أول تصنيف.'
                    : 'لا تصنيفات ${income ? 'إيراد' : 'مصروف'} بعد.',
                style: UType.label(color: c.inkMuted),
              ),
            )
          else
            for (final (i, cat) in items.indexed) ...[
              if (i > 0) Divider(height: 1, color: c.line),
              _CategoryRow(cat, owner: owner),
            ],
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow(this.cat, {required this.owner});

  final FinanceCategory cat;
  final bool owner;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final used = cat.transactionsCount;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSize.minTap),
      child: Row(
        spacing: AppSpace.s3,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  cat.name,
                  style: UType.body(color: cat.active ? c.ink : c.inkMuted).weight(600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (used != null)
                  Text(
                    used == 0 ? 'لا حركات' : Formatters.count(used, 'حركة واحدة', 'حركتان', 'حركات', many: 'حركة'),
                    style: UType.caption(color: c.inkMuted),
                  ),
              ],
            ),
          ),
          StatusBadge(cat.active ? 'فعّال' : 'متوقف', tone: cat.active ? UTone.success : UTone.neutral),
          if (owner) ...[
            TextButton(onPressed: () => CategoryActions.edit(context, cat), child: const Text('تعديل')),
            // مكان ثابت لزر الحذف فتصطف الشارات بكل الأسطر.
            SizedBox(
              width: AppSize.minTap,
              child: used == 0
                  ? IconButton(
                      tooltip: 'حذف ${cat.name}',
                      onPressed: () => CategoryActions.delete(context, cat),
                      color: c.dangerInk,
                      icon: const Icon(Icons.delete_outline_rounded),
                    )
                  : null,
            ),
          ],
        ],
      ),
    );
  }
}
