import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../domain/models/finance_settings_models.dart';
import '../bloc/finance_settings_cubit.dart';

/// سجل سعر الصرف (`FinanceSettings.html`): التاريخ، ليرة لكل دولار، الفرق عن السابق (ارتفاع الليرة لكل دولار
/// أحمر، انخفاضها أخضر)، الملاحظة، ومن سجّله.
class RateHistoryTable extends StatelessWidget {
  const RateHistoryTable({super.key});

  @override
  Widget build(BuildContext context) {
    final list = context.read<ExchangeRatesCubit>();
    final state = context.watch<ExchangeRatesCubit>().state;
    final rows = state.slice.data?.items ?? const <ExchangeRateEntry>[];
    Widget change(BuildContext c, ExchangeRateEntry r) => _Change(rateChange(rows, rows.indexOf(r)));
    return PagedTable<ExchangeRateEntry>(
      state: state,
      noun: 'سعراً',
      minWidth: AppSize.historyTableMin,
      onPage: list.goTo,
      onRetry: list.load,
      header: Text('السجل', style: UType.h3(color: context.colors.ink)),
      empty: const AppEmptyState(
        icon: Icons.currency_exchange_rounded,
        title: 'لا أسعار مسجّلة بعد',
        message: 'اعتمد أول سعر صرف ليُحسب به أي مبلغ بالليرة.',
      ),
      mobileItem: (context, r) => _MobileCard(r, change: change(context, r)),
      columns: [
        TableCol(
          'التاريخ',
          flex: 3,
          cell: (c, r) => LtrText(Formatters.dateTime(r.createdAt), style: UType.label(color: c.colors.inkMuted)),
        ),
        TableCol(
          'ليرة لكل دولار',
          flex: 2,
          cell: (c, r) => LtrText(Formatters.number(r.sypPerUsd), style: UType.body(color: c.colors.ink).weight(700)),
        ),
        TableCol('الفرق', flex: 2, cell: change),
        TableCol('ملاحظة', flex: 3, cell: (c, r) => _muted(c, r.note ?? '—')),
        TableCol('بواسطة', flex: 2, cell: (c, r) => _muted(c, r.createdBy ?? '—')),
      ],
    );
  }

  static Widget _muted(BuildContext c, String v) =>
      Text(v, style: UType.label(color: c.colors.inkMuted), maxLines: 1, overflow: TextOverflow.ellipsis);
}

/// الفرق بإشارته: الليرة لكل دولار ارتفعت (أحمر) أو انخفضت (أخضر)، و "—" لآخر سطر بالصفحة.
class _Change extends StatelessWidget {
  const _Change(this.value);

  final double? value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final v = value;
    if (v == null) return Text('—', style: UType.label(color: c.inkFaint));
    final color = v > 0 ? c.dangerInk : (v < 0 ? c.successInk : c.inkMuted);
    final sign = v > 0 ? '+' : (v < 0 ? '−' : '');
    return LtrText('$sign${Formatters.number(v.abs())}', style: UType.label(color: color).weight(600));
  }
}

class _MobileCard extends StatelessWidget {
  const _MobileCard(this.r, {required this.change});

  final ExchangeRateEntry r;
  final Widget change;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final muted = UType.caption(color: c.inkMuted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.s1,
      children: [
        Row(
          children: [
            LtrText('1 USD = ${Formatters.number(r.sypPerUsd)} SYP', style: UType.body(color: c.ink).weight(700)),
            const Spacer(),
            change,
          ],
        ),
        LtrText(Formatters.dateTime(r.createdAt), style: muted),
        Text([r.note, r.createdBy].nonNulls.join(' · '), style: muted),
      ],
    );
  }
}
