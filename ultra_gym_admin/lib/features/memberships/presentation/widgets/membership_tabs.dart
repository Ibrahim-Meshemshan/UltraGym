import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../members/presentation/widgets/history_columns.dart';
import '../../domain/models/membership_detail_models.dart';
import '../bloc/membership_detail_cubit.dart';
import 'membership_actions.dart';

/// تبويبات الاشتراك: الدفعات والتجميدات (من رد التفاصيل، بلا صفحات) والحضور (زيارات العضو خلال الفترة).
class MembershipTabsCard extends StatelessWidget {
  const MembershipTabsCard(this.detail, {super.key});

  final MembershipDetail detail;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => ValueCubit(MembershipDetailTab.payments),
    child: BlocBuilder<ValueCubit<MembershipDetailTab>, MembershipDetailTab>(
      builder: (context, tab) {
        final d = detail;
        final header = Padding(
          padding: const EdgeInsetsDirectional.only(start: AppSpace.s5, end: AppSpace.s5, top: AppSpace.s2),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: AppTabs(
                tabs: [
                  (label: 'الدفعات', count: d.transactions.length),
                  (label: 'التجميدات', count: d.freezes.history.length),
                  (label: 'الحضور', count: null),
                ],
                selected: tab.index,
                onSelect: (i) => context.read<ValueCubit<MembershipDetailTab>>().set(MembershipDetailTab.values[i]),
              ),
            ),
          ),
        );
        return switch (tab) {
          MembershipDetailTab.payments => _StaticTable<PaymentEntry>(
            header: header,
            rows: d.transactions,
            columns: _payments,
            mobileItem: _paymentMobile,
            minWidth: AppSize.paymentsTableMin,
            footnote: 'الدفعات لا تُعدَّل ولا تُحذف. التصحيح بعكس الحركة من دفتر الحركات (للمالك).',
            empty: const AppEmptyState(
              icon: Icons.receipt_long_rounded,
              title: 'لا دفعات',
              message: 'كل الاشتراك دين. سجّل أول دفعة من "سداد الدين".',
            ),
          ),
          MembershipDetailTab.freezes => _StaticTable<FreezeEntry>(
            header: header,
            rows: d.freezes.history,
            columns: _freezes,
            mobileItem: _freezeMobile,
            empty: const AppEmptyState(
              icon: Icons.ac_unit_rounded,
              title: 'لم يُجمَّد بعد',
              message: 'كل تجميد يظهر هنا بفترته وسببه، وفكّه المبكر إن حصل.',
            ),
          ),
          MembershipDetailTab.attendance => _Attendance(detail: d, header: header),
        };
      },
    ),
  );

  static final _payments = <TableCol<PaymentEntry>>[
    TableCol('الإيصال', width: AppSize.receiptNumberCol, cell: (c, p) => _ltr(c, p.receiptNumber ?? '—')),
    TableCol('التاريخ', flex: 3, cell: (c, p) => _ltr(c, Formatters.dateTime(p.occurredAt), muted: true)),
    _shared('النوع', 3),
    _shared('المبلغ', 3),
    TableCol('بالدولار', cell: (c, p) => _ltr(c, p.amountUsd == null ? '—' : Formatters.usd(p.amountUsd!))),
    TableCol('بواسطة', flex: 2, cell: (c, p) => _text(c, p.createdBy ?? '—')),
    TableCol('', width: AppSize.receiptCol, cell: (c, p) => _ReceiptButton(p)),
  ];

  /// عمود من أعمدة سجل الدفعات المشتركة بعرض مختلف.
  static TableCol<PaymentEntry> _shared(String label, int flex) =>
      TableCol(label, flex: flex, cell: HistoryColumns.payments.firstWhere((col) => col.label == label).cell);

  static Widget _paymentMobile(BuildContext context, PaymentEntry p) => Row(
    children: [
      Expanded(child: HistoryColumns.paymentMobile(context, p)),
      _ReceiptButton(p),
    ],
  );

  static final _freezes = <TableCol<FreezeEntry>>[
    TableCol('من', cell: (c, f) => _ltr(c, Formatters.date(f.startsOn))),
    TableCol('إلى', cell: (c, f) => _ltr(c, Formatters.date(f.endsOn))),
    TableCol('الأيام', cell: (c, f) => _ltr(c, '${f.days}')),
    TableCol('فُكّ', cell: (c, f) => f.endedEarlyOn == null ? _text(c, '—') : _ltr(c, Formatters.date(f.endedEarlyOn))),
    TableCol('السبب', flex: 3, cell: (c, f) => _text(c, f.reason ?? '—')),
  ];

  static Widget _freezeMobile(BuildContext context, FreezeEntry f) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: AppSpace.s1,
    children: [
      _ltr(context, '${Formatters.date(f.startsOn)} → ${Formatters.date(f.endsOn)}'),
      _text(context, '${Formatters.days(f.days)} · ${f.reason ?? '—'}'),
    ],
  );

  static Widget _ltr(BuildContext c, String v, {bool muted = false}) =>
      LtrText(v, style: UType.body(color: muted ? c.colors.inkMuted : c.colors.ink));

  static Widget _text(BuildContext c, String v) => Text(v, style: UType.body(color: c.colors.ink));
}

class _ReceiptButton extends StatelessWidget {
  const _ReceiptButton(this.p);

  final PaymentEntry p;

  @override
  Widget build(BuildContext context) => p.receiptNumber == null
      ? const SizedBox.shrink()
      : TextButton(onPressed: () => openReceipt(p.id), child: const Text('الإيصال'));
}

/// جدول بلا صفحات بنفس إطار `PagedTable` (بطاقات بالموبايل).
class _StaticTable<T> extends StatelessWidget {
  const _StaticTable({
    required this.header,
    required this.rows,
    required this.columns,
    required this.mobileItem,
    required this.empty,
    this.footnote,
    this.minWidth = AppSize.historyTableMin,
  });

  final Widget header, empty;
  final List<T> rows;
  final List<TableCol<T>> columns;
  final Widget Function(BuildContext context, T row) mobileItem;
  final String? footnote;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final line = BoxDecoration(
      border: Border(top: BorderSide(color: c.line)),
    );
    return CutCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          if (rows.isEmpty)
            Padding(padding: const EdgeInsets.all(AppSpace.s5), child: empty)
          else if (context.isMobile)
            for (final r in rows)
              Container(decoration: line, padding: const EdgeInsets.all(AppSpace.s4), child: mobileItem(context, r))
          else
            AppDataTable<T>(columns: columns, rows: rows, minWidth: minWidth),
          if (footnote != null && rows.isNotEmpty)
            Container(
              decoration: line,
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.s5, vertical: AppSpace.s3),
              child: Text(footnote!, style: UType.caption(color: c.inkMuted)),
            ),
        ],
      ),
    );
  }
}

/// زيارات العضو بين بداية الاشتراك ونهايته (`attendance?player_id=&from=&to=`).
class _Attendance extends StatelessWidget {
  const _Attendance({required this.detail, required this.header});

  final MembershipDetail detail;
  final Widget header;

  @override
  Widget build(BuildContext context) {
    final m = detail.membership;
    return BlocProvider(
      create: (_) =>
          sl<MembershipAttendanceCubit>(param1: (playerId: m.playerId, from: m.startsOn, to: m.endsOn))..load(),
      child: BlocBuilder<MembershipAttendanceCubit, ListState<AttendanceEntry>>(
        builder: (context, state) {
          final cubit = context.read<MembershipAttendanceCubit>();
          return PagedTable<AttendanceEntry>(
            state: state,
            columns: HistoryColumns.attendance,
            mobileItem: HistoryColumns.attendanceMobile,
            onPage: cubit.goTo,
            onRetry: cubit.load,
            header: header,
            noun: 'زيارة',
            minWidth: AppSize.historyTableMin,
            empty: const AppEmptyState(
              icon: Icons.login_rounded,
              title: 'لا زيارات خلال الاشتراك',
              message: 'كل دخول للعضو بين بداية الاشتراك ونهايته يظهر هنا.',
            ),
          );
        },
      ),
    );
  }
}
