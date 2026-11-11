import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../auth_copy.dart';
import '../bloc/login_cubit.dart';
import '../../domain/models/auth_models.dart';
import 'auth_scaffold.dart';

/// خطوة اختيار النادي: يعيد نفس طلب الدخول مع `tenant_id`.
class TenantPicker extends StatelessWidget {
  const TenantPicker({super.key});

  @override
  Widget build(BuildContext context) {
    final login = context.watch<LoginCubit>();
    final tenants = login.state.tenants ?? const <TenantChoice>[];
    final picking = login.state.pickingTenantId;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AuthHeading('اختر النادي', subtitle: AuthCopy.tenantPickerHint),
        const FormErrorBanner(),
        AppSpace.gap5,
        for (final t in tenants) ...[
          _TenantTile(
            choice: t,
            busy: picking == t.tenant.id,
            onTap: picking != null ? null : () => login.submit(context.read<AppFormCubit>(), tenantId: t.tenant.id),
          ),
          AppSpace.gap3,
        ],
        AppSpace.gap2,
        UGButton(
          label: 'رجوع',
          icon: Icons.arrow_forward_rounded,
          kind: UButtonKind.ghost,
          onPressed: picking != null ? null : login.backToCredentials,
        ),
      ],
    );
  }
}

class _TenantTile extends StatelessWidget {
  const _TenantTile({required this.choice, required this.busy, this.onTap});

  final TenantChoice choice;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final roles = choice.roles.map((r) => Labels.role(r).text).join(' · ');
    return CutCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpace.s4),
      child: Row(
        children: [
          Container(
            width: AppSize.control,
            height: AppSize.control,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: c.primarySoft, borderRadius: AppRadius.smAll),
            child: Text(choice.tenant.initial, style: UType.h3(color: c.primaryInk)),
          ),
          AppSpace.gap3,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(choice.tenant.name, style: UType.h3(color: c.ink)),
                if (roles.isNotEmpty) Text(roles, style: UType.caption(color: c.inkMuted)),
              ],
            ),
          ),
          if (busy)
            SizedBox.square(
              dimension: AppSpace.s5,
              child: CircularProgressIndicator(strokeWidth: 2, color: c.primary),
            )
          else
            Icon(Icons.chevron_left_rounded, color: c.inkFaint),
        ],
      ),
    );
  }
}
