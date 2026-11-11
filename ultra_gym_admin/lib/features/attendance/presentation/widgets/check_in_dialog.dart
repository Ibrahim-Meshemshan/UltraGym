import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../../branches/presentation/bloc/branch_scope_cubit.dart';
import '../../../club_plan/domain/models/club_plan_models.dart';
import '../../../club_plan/presentation/bloc/club_plan_cubit.dart';
import '../../../memberships/presentation/widgets/cash_fields.dart';
import '../../../quick_search/presentation/widgets/lookup_tile.dart';
import '../../../quick_search/presentation/widgets/quick_search_button.dart';
import '../../data/repo/attendance_repository.dart';
import '../../domain/models/attendance_models.dart';
import '../bloc/attendance_cubit.dart';
import 'check_in_result.dart';
import 'qr_scan_dialog.dart';

/// تسجيل دخول يدوي (`POST attendance/check-in`): بمعرّف العضو (كتابة أو باركود + Enter)، أو رمز QR من تطبيق
/// العضو بقارئ يكتب بالحقل أو بـ "مسح QR بالكاميرا" (حين `qr_attendance` بالباقة)، أو باختياره من البحث،
/// مع فرع الدخول حين يكون الشريط على "كل الفروع"، و "استهلاك جلسة" اختياري. النتيجة ببطاقة داخل النافذة
/// ثم "تسجيل آخر". ترجع true إن سُجّل شيء (المرفوض محفوظ أيضاً) لتحديث السجل والأرقام.
abstract final class CheckInDialog {
  static const _code = 'member_code', _consume = 'consume_session';

  static Future<bool> show(BuildContext context, {int? fallbackBranch}) async {
    final branch = CashBranch.of(context, fallback: fallbackBranch);
    final scope = context.read<BranchScopeCubit>();
    // النافذة على الـ Navigator الجذري خارج الهيكل: الباقة تُقرأ هنا.
    final camera = context.read<ClubPlanCubit>().state.has(PlanFeature.qrAttendance);
    final recorded = await showDialog<bool>(
      context: context,
      builder: (_) => MultiBlocProvider(
        providers: [
          // النافذة فوق الهيكل: البحث بالاسم يحتاج فرع الشريط العلوي.
          BlocProvider.value(value: scope),
          BlocProvider(create: (_) => AppFormCubit(initial: branch.initial)),
          BlocProvider(create: (_) => CheckInCubit()),
        ],
        child: _Body(branch: branch, camera: camera),
      ),
    );
    return recorded ?? false;
  }

  /// رمز QR من تطبيق العضو (`UG1.{key_id}.{ts}.{sig}`) يكتبه قارئ الباركود بالحقل: يُرسل `qr_token` كما هو
  /// (التوقيع حساس لحالة الأحرف)، وأي نص آخر معرّف عضو بأحرف كبيرة. أخطاء الرمز (422 `QR_*`) رسالتها من الخادم.
  static bool isQrToken(String text) => text.startsWith('UG1.');

  /// لا عضو مختار ولا معرّف مكتوب: يظهر أعلى النموذج بلا طلب.
  static const _noMember = ApiFailure<Never>(
    Failure(type: FailureType.validation, message: 'اكتب معرّف العضو أو اختره بالبحث.'),
  );
}

class _Body extends StatelessWidget {
  const _Body({required this.branch, required this.camera});

  final CashBranch branch;
  final bool camera;

  Future<void> _submit(BuildContext context) async {
    final form = context.read<AppFormCubit>();
    final cubit = context.read<CheckInCubit>();
    final player = cubit.state.player;
    final code = '${form.value(CheckInDialog._code) ?? ''}'.trim();
    final body = <String, Object?>{
      if (player != null)
        'player_id': player.id
      else if (CheckInDialog.isQrToken(code))
        'qr_token': code
      else if (code.isNotEmpty)
        'member_code': code.toUpperCase(),
      CashBranch.key: ?branch.idOf(form),
      if (form.value(CheckInDialog._consume) == true) 'consume_session': true,
    };
    final r = await form.submit<CheckInResult>(
      (_) async => player == null && code.isEmpty
          ? CheckInDialog._noMember
          : sl<AttendanceRepository>().checkIn(body, idempotencyKey: cubit.keyFor(body)),
    );
    if (r case ApiSuccess(:final data)) cubit.show(data);
  }

  void _again(BuildContext context) {
    context.read<AppFormCubit>().text(CheckInDialog._code).clear();
    context.read<CheckInCubit>().again();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.watch<CheckInCubit>().state;
    final result = s.result;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(s.recorded);
      },
      child: Dialog(
        insetPadding: const EdgeInsets.all(AppSpace.s4),
        backgroundColor: c.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(AppRadius.hero))),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSize.dialog),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpace.s6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpace.s4,
              children: [
                Row(
                  children: [
                    const IconSlab(Icons.login_rounded, size: AppSize.control),
                    AppSpace.gap3,
                    Expanded(
                      child: Text('تسجيل دخول يدوي', style: UType.h2(color: c.ink)),
                    ),
                  ],
                ),
                if (result != null) ...[
                  CheckInResultCard(result),
                  _ResultActions(result: result, recorded: s.recorded, onAgain: () => _again(context)),
                ] else ...[
                  const FormErrorBanner(),
                  _MemberField(onSubmit: () => _submit(context), camera: camera),
                  if (branch.needsField) branch.field(label: 'فرع الدخول'),
                  const _ConsumeSwitch(),
                  _FormActions(onSubmit: () => _submit(context), recorded: s.recorded),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// العضو: المختار من البحث ببطاقته (الحالة وسبب المنع من الخادم)، وإلا حقل المعرّف.
/// "مسح QR بالكاميرا": الرمز المقروء يوضع بالحقل ويُرسل فوراً (كما لو كتبه قارئ الباركود).
class _MemberField extends StatelessWidget {
  const _MemberField({required this.onSubmit, required this.camera});

  final VoidCallback onSubmit;
  final bool camera;

  Future<void> _scan(BuildContext context) async {
    final raw = await sl<QrScanner>().scan(context);
    if (raw == null || !context.mounted) return;
    context.read<CheckInCubit>().clearPlayer();
    context.read<AppFormCubit>().text(CheckInDialog._code).text = raw;
    onSubmit();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<CheckInCubit>();
    final player = cubit.state.player;
    final pickButton = Wrap(
      spacing: AppSpace.s2,
      runSpacing: AppSpace.s1,
      children: [
        TextButton.icon(
          onPressed: () async {
            final picked = await QuickSearch.pick(context);
            if (picked == null || !context.mounted) return;
            context.read<AppFormCubit>().text(CheckInDialog._code).clear();
            cubit.pick(picked);
          },
          icon: Icon(player == null ? Icons.person_search_rounded : Icons.swap_horiz_rounded, size: AppSize.iconSm),
          label: Text(player == null ? 'البحث بالاسم أو الموبايل' : 'تغيير العضو'),
        ),
        if (camera)
          TextButton.icon(
            onPressed: () => _scan(context),
            icon: const Icon(Icons.qr_code_scanner_rounded, size: AppSize.iconSm),
            label: const Text('مسح QR بالكاميرا'),
          ),
      ],
    );
    if (player != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.s1,
        children: [
          const FieldLabel('العضو'),
          LookupTile(player: player, onTap: cubit.clearPlayer),
          pickButton,
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.s1,
      children: [
        FormText(
          CheckInDialog._code,
          label: 'معرّف العضو أو الباركود',
          hint: 'DMO-123456',
          ltr: true,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmit(),
        ),
        pickButton,
      ],
    );
  }
}

class _ConsumeSwitch extends StatelessWidget {
  const _ConsumeSwitch();

  @override
  Widget build(BuildContext context) {
    final form = context.read<AppFormCubit>();
    final on = context.select<AppFormCubit, bool>((f) => f.value(CheckInDialog._consume) == true);
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      value: on,
      onChanged: (v) => form.set(CheckInDialog._consume, v),
      title: Text('استهلاك جلسة مع الدخول', style: UType.body(color: context.colors.ink)),
      subtitle: Text('لاشتراكات الجلسات فقط.', style: UType.caption(color: context.colors.inkMuted)),
    );
  }
}

class _FormActions extends StatelessWidget {
  const _FormActions({required this.onSubmit, required this.recorded});

  final VoidCallback onSubmit;
  final bool recorded;

  @override
  Widget build(BuildContext context) => BlocSelector<AppFormCubit, AppFormState, bool>(
    selector: (s) => s.submitting,
    builder: (context, submitting) => Wrap(
      alignment: WrapAlignment.end,
      spacing: AppSpace.s2,
      runSpacing: AppSpace.s2,
      children: [
        UGButton(
          label: 'إغلاق',
          kind: UButtonKind.ghost,
          onPressed: submitting ? null : () => Navigator.of(context).pop(recorded),
        ),
        UGButton(
          label: submitting ? 'جارٍ التسجيل…' : 'تسجيل الدخول',
          icon: Icons.login_rounded,
          onPressed: submitting ? null : onSubmit,
        ),
      ],
    ),
  );
}

/// بعد النتيجة: الفعل التالي (بيع، فتح الاشتراك، الملف) ثم "تسجيل آخر".
class _ResultActions extends StatelessWidget {
  const _ResultActions({required this.result, required this.recorded, required this.onAgain});

  final CheckInResult result;
  final bool recorded;
  final VoidCallback onAgain;

  @override
  Widget build(BuildContext context) {
    final next = checkInFollowUp(result);
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: AppSpace.s2,
      runSpacing: AppSpace.s2,
      children: [
        UGButton(label: 'إغلاق', kind: UButtonKind.ghost, onPressed: () => Navigator.of(context).pop(recorded)),
        if (next != null)
          UGButton(
            label: next.label,
            icon: next.icon,
            kind: UButtonKind.secondary,
            onPressed: () {
              final router = GoRouter.of(context);
              Navigator.of(context).pop(recorded);
              router.go(next.route);
            },
          ),
        UGButton(label: 'تسجيل آخر', icon: Icons.login_rounded, onPressed: onAgain),
      ],
    );
  }
}
