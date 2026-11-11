import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../domain/models/check_in_models.dart';
import '../bloc/station_bloc.dart';
import 'check_in_card.dart';

/// مكان النتيجة تحت الحقل: جاهز للمسح، نتائج البحث، جارٍ التسجيل، النتيجة، أو سبب الفشل.
class OutcomePanel extends StatelessWidget {
  const OutcomePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<StationBloc>().state;
    final bloc = context.read<StationBloc>();
    void next() => bloc.add(const StationCleared());
    final o = s.outcome;
    final Widget child = switch (o) {
      _ when s.lookupQuery != null => _Lookup(query: s.lookupQuery!, slice: s.lookup),
      Slice(isLoading: true) => const _Pending(),
      Slice(:final data?) => CheckInCard(data, onNext: next),
      Slice(:final failure?) => _FailureCard(failure, onNext: next),
      _ => const CutCard(
        child: AppEmptyState(
          icon: Icons.qr_code_2_rounded,
          title: 'جاهز للمسح',
          message: 'امسح رمز QR من تطبيق العضو، أو اكتب معرّفه أو اسمه أو موبايله ثم Enter.',
        ),
      ),
    };
    return AnimatedSwitcher(
      duration: AppMotion.of(context, AppMotion.fast),
      // بعرض العمود كاملاً ومن الأعلى (الافتراضي يوسّط ويصغّر).
      layoutBuilder: (current, previous) => Stack(
        fit: StackFit.passthrough,
        alignment: AlignmentDirectional.topCenter,
        children: [...previous, ?current],
      ),
      child: KeyedSubtree(key: ValueKey(s.attempt), child: child),
    );
  }
}

/// هيكل بطاقة النتيجة أثناء التسجيل.
class _Pending extends StatelessWidget {
  const _Pending();

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'جارٍ تسجيل الدخول',
    child: const AppShimmer(
      child: ShimmerCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpace.s5,
          children: [
            ShimmerBox(width: AppSize.resultAvatar, height: AppSize.resultAvatar, radius: AppRadius.card),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpace.s3,
                children: [
                  ShimmerBox(width: AppSize.gridItem, height: AppSpace.s6),
                  ShimmerBox(width: AppSize.resultAvatar * 2),
                  ShimmerBox(height: AppSpace.s12, radius: AppRadius.field),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// لم يُسجَّل شيء: رمز QR مرفوض (422)، عضو غير موجود (404)، أو شبكة (إعادة بنفس المفتاح).
class _FailureCard extends StatelessWidget {
  const _FailureCard(this.failure, {required this.onNext});

  final Failure failure;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final qr = failure.code?.startsWith('QR_') ?? false;
    final (tone, icon, hint) = switch (failure) {
      _ when qr => (UTone.warning, Icons.qr_code_2_rounded, 'اطلب من العضو تحديث الرمز بالتطبيق ثم امسحه مجدداً.'),
      Failure(type: FailureType.notFound) => (
        UTone.danger,
        Icons.person_off_rounded,
        'تأكد من المعرّف، أو ابحث بالاسم أو الموبايل.',
      ),
      Failure(isNetwork: true) => (UTone.warning, Icons.wifi_off_rounded, 'لم يُسجَّل الدخول بعد. أعد المحاولة.'),
      _ => (UTone.danger, Icons.error_outline_rounded, null),
    };
    final (bg, fg) = tone.colors(c);
    return CutCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: bg,
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.s6, vertical: AppSpace.s3),
            child: Row(
              spacing: AppSpace.s2,
              children: [
                Icon(icon, color: fg, size: AppSize.iconSm),
                Expanded(
                  child: Text(failure.message, style: UType.body(color: fg).weight(600)),
                ),
                if (failure.code case final code? when qr) LtrText(code, style: UType.caption(color: fg)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpace.s6),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpace.s3,
              runSpacing: AppSpace.s3,
              children: [
                if (hint != null) Text(hint, style: UType.body(color: c.inkMuted)),
                Wrap(
                  spacing: AppSpace.s2,
                  children: [
                    if (failure.isNetwork)
                      UGButton(
                        label: 'إعادة المحاولة',
                        icon: Icons.refresh_rounded,
                        onPressed: () => context.read<StationBloc>().add(const StationRetried()),
                      ),
                    UGButton(
                      label: 'العضو التالي',
                      icon: Icons.skip_next_rounded,
                      kind: UButtonKind.ghost,
                      onPressed: onNext,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// نتائج البحث بالاسم أو الموبايل: الضغط على عضو يسجّل دخوله (الخادم يقرر ويحفظ المرفوض أيضاً).
class _Lookup extends StatelessWidget {
  const _Lookup({required this.query, required this.slice});

  final String query;
  final Slice<List<LookupPlayer>> slice;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<StationBloc>();
    return SliceView<List<LookupPlayer>>(
      slice: slice,
      loading: const ListShimmer(count: 3),
      onRetry: () => bloc.add(StationSubmitted(query)),
      isEmpty: (l) => l.isEmpty,
      empty: CutCard(
        child: AppEmptyState(
          icon: Icons.person_search_rounded,
          title: 'لا نتائج',
          message: 'لا عضو يطابق «$query». جرّب الموبايل أو معرّف العضو.',
        ),
      ),
      builder: (context, players) => SectionCard(
        title: 'نتائج البحث عن «$query»',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [for (final p in players) _LookupRow(p, onTap: () => bloc.add(StationPlayerPicked(p)))],
        ),
      ),
    );
  }
}

class _LookupRow extends StatelessWidget {
  const _LookupRow(this.player, {required this.onTap});

  final LookupPlayer player;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final m = player.membership;
    final ids = [player.memberCode, player.phone].nonNulls.join('  ·  ');
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.fieldAll,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSize.minTap),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.s2, vertical: AppSpace.s3),
          child: Row(
            spacing: AppSpace.s3,
            children: [
              InitialsAvatar(player.name, size: AppSize.control),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(player.name, style: UType.body(color: c.ink).weight(600)),
                    if (ids.isNotEmpty) LtrText(ids, style: UType.caption(color: c.inkMuted)),
                    if (!player.canEnter && player.rejectionMessage != null)
                      Text(player.rejectionMessage!, style: UType.caption(color: c.dangerInk)),
                  ],
                ),
              ),
              if (m != null) StatusBadge(m.statusLabel, tone: Labels.membershipStatus(m.status).tone),
            ],
          ),
        ),
      ),
    );
  }
}
