import '../../../../core/core.dart';
import '../../../members/domain/models/member_profile_models.dart';

/// صف بقائمة الاشتراكات `GET club-admin/memberships` (أو `/debts`): الاشتراك + صاحبه.
/// الحالة والأيام والدين من الخادم كما هي.
class MembershipRow extends MembershipItem {
  const MembershipRow({
    required super.id,
    required super.planName,
    required super.status,
    required super.statusLabel,
    required this.playerId,
    required this.playerName,
    super.type,
    super.startsOn,
    super.endsOn,
    super.daysRemaining,
    super.sessionsRemaining,
    super.frozenUntil,
    super.sessionsTotal,
    super.branchName,
    super.trainerName,
    super.netUsd,
    super.paidUsd,
    super.dueUsd,
  });

  factory MembershipRow.fromJson(Json j) {
    final m = MembershipItem.fromJson(j);
    final player = j.obj('player');
    return MembershipRow(
      id: m.id,
      planName: m.planName,
      status: m.status,
      statusLabel: m.statusLabel,
      playerId: player.intv('id'),
      playerName: player.str('name', '—'),
      type: m.type,
      startsOn: m.startsOn,
      endsOn: m.endsOn,
      daysRemaining: m.daysRemaining,
      sessionsRemaining: m.sessionsRemaining,
      frozenUntil: m.frozenUntil,
      sessionsTotal: m.sessionsTotal,
      branchName: m.branchName,
      trainerName: m.trainerName,
      netUsd: m.netUsd,
      paidUsd: m.paidUsd,
      dueUsd: m.dueUsd,
    );
  }

  final int playerId;
  final String playerName;

  @override
  List<Object?> get props => [...super.props, playerId, playerName];
}

/// أرقام رأس الصفحة: الفعّالة، المجمّدة، تنتهي خلال 7 أيام، ومجموع الديون (`debts.meta.summary`).
class MembershipStats extends Equatable {
  const MembershipStats({this.active = 0, this.frozen = 0, this.expiring = 0, this.debtUsd = 0, this.debtCount = 0});

  final int active, frozen, expiring, debtCount;
  final double debtUsd;

  @override
  List<Object?> get props => [active, frozen, expiring, debtUsd, debtCount];
}

/// خطة اشتراك بقائمة الفلتر (`GET membership-plans`).
typedef PlanOption = FormOption<int>;

/// التبويبات: الكل (بالفلاتر)، عليها ديون (`/debts` الأكبر أولاً)، تنتهي خلال 7 أيام (الأقرب أولاً).
enum MembershipsTab { all, debts, expiring }

/// فلاتر القائمة بمفاتيح الخادم.
abstract final class MembershipFilters {
  static const status = 'status';
  static const planId = 'plan_id';
  static const branchId = 'branch_id';

  /// "تنتهي خلال" بالأيام لتبويب القريبة (والرئيسية تربط بنفس القيمة).
  static const expiringDays = 7;

  /// قيم `status` المقبولة بالخادم، بنصوص `Labels.membershipStatus`.
  static final statuses = <FormOption<String>>[
    for (final s in const ['active', 'upcoming', 'frozen', 'grace', 'expired', 'cancelled'])
      (value: s, label: Labels.membershipStatus(s).text),
  ];
}
