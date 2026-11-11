import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../domain/models/dashboard_models.dart';
import '../demo/demo_kpi.dart';
import 'alerts_card.dart';
import 'cash_boxes_card.dart';
import 'expiring_card.dart';
import 'finance_card.dart';

/// محتوى الرئيسية تحت الرأس بترتيب `Dashboard.html`: أرقام اليوم، المال + الصناديق، التنبيهات + المنتهية.
/// المال للمالك فقط (الخادم لا يرسل `finance` للاستقبال)، والتنبيهات تظهر حين توجد.
class DashboardBody extends StatelessWidget {
  const DashboardBody({super.key, required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      DashboardStats(data: data),
      AppSpace.gap5,
      DashboardSplit(
        first: switch (data.finance) {
          final f? => FinanceCard(finance: f),
          null => null,
        },
        second: data.cashBoxes.isEmpty ? null : CashBoxesCard(boxes: data.cashBoxes),
      ),
      AppSpace.gap5,
      DashboardSplit(
        first: data.alerts.isEmpty ? null : AlertsCard(alerts: data.alerts),
        second: const ExpiringCard(),
        firstFlex: 1,
        secondFlex: 2,
      ),
    ],
  );
}

/// أرقام اليوم بأسلوب التجربة: الاشتراكات الفعّالة بطاقة التدرج الرئيسية مع شريط أجزائها، والباقي
/// بطاقات هادئة (الأعمدة = العرض ÷ 230). كلها تدخل متتابعة وتفتح قسمها.
class DashboardStats extends StatelessWidget {
  const DashboardStats({super.key, required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final p = data.players, m = data.memberships, a = data.attendance, d = data.debts;
    final cards = [
      DemoHeroKpi(
        icon: Icons.card_membership_rounded,
        label: 'الاشتراكات الفعّالة',
        value: m.active.toDouble(),
        note: (text: 'اشتراكات اليوم: ${m.soldToday}', tone: null),
        parts: [
          (label: 'فعّالة', value: m.active),
          (label: 'مجمّدة', value: m.frozen),
          (label: 'بالسماح', value: m.inGrace),
        ],
        onTap: () => context.go(Routes.memberships),
      ),
      DemoKpi(
        icon: Icons.groups_rounded,
        label: 'الأعضاء',
        value: p.total.toDouble(),
        note: p.newThisMonth > 0
            ? (text: 'جدد هذا الشهر: ${p.newThisMonth}', tone: UTone.success)
            : (text: 'لا أعضاء جدد هذا الشهر', tone: null),
        onTap: () => context.go(Routes.members),
      ),
      DemoKpi(
        icon: Icons.login_rounded,
        label: 'دخول اليوم',
        value: a.today.toDouble(),
        note: (
          text: [
            'مرفوض ${a.rejectedToday}',
            'هذا الشهر ${Formatters.number(a.thisMonth)}',
            if (a.visitorsToday > 0) 'زوار ${a.visitorsToday}',
          ].join(' · '),
          tone: null,
        ),
        onTap: () => context.go(Routes.attendance),
      ),
      DemoKpi(
        icon: Icons.account_balance_wallet_outlined,
        label: 'الديون',
        value: d.totalDueUsd,
        prefix: r'$',
        decimals: 2,
        note: d.players > 0
            ? (
                text: 'على ${Formatters.count(d.players, 'عضو واحد', 'عضوين', 'أعضاء', many: 'عضواً')}',
                tone: UTone.warning,
              )
            : (text: 'لا ديون مستحقة', tone: null),
        onTap: () => context.go(DashboardLinks.debts),
      ),
    ];
    return Semantics(
      container: true,
      label: 'أرقام اليوم',
      child: ResponsiveGrid(
        children: [for (var i = 0; i < cards.length; i++) Entrance(index: i, child: cards[i])],
      ),
    );
  }
}

/// روابط الرئيسية لصفحات بفلتر أولي (query parameters تقرؤها الصفحة حين تُبنى).
abstract final class DashboardLinks {
  static final debts = Uri(path: Routes.memberships, queryParameters: {'has_debt': '1'}).toString();
  static final expiring = Uri(path: Routes.memberships, queryParameters: {'expiring_within_days': '7'}).toString();
}

/// بطاقتان متجاورتان بنسبة `firstFlex : secondFlex` على العرض الكافي، وإلا فوق بعض.
/// الغائبة (null) تترك الأخرى بكامل العرض.
class DashboardSplit extends StatelessWidget {
  const DashboardSplit({super.key, this.first, this.second, this.firstFlex = 2, this.secondFlex = 1});

  final Widget? first, second;
  final int firstFlex, secondFlex;

  @override
  Widget build(BuildContext context) {
    final a = first, b = second;
    if (a == null || b == null) return a ?? b ?? const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, box) => box.maxWidth >= AppSize.splitMin
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: firstFlex, child: a),
                AppSpace.gap3,
                Expanded(flex: secondFlex, child: b),
              ],
            )
          : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [a, AppSpace.gap3, b]),
    );
  }
}

/// هيكل التحميل بشكل المحتوى: بطاقات الأرقام ثم بطاقة بصفوف.
class DashboardShimmer extends StatelessWidget {
  const DashboardShimmer({super.key});

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [StatsShimmer(), AppSpace.gap5, TableShimmer(rows: 5, columns: 4)],
  );
}
