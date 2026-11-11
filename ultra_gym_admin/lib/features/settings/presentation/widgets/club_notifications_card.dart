import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../domain/models/settings_models.dart';
import '../bloc/settings_cubits.dart';
import 'club_form.dart';
import 'club_settings_cards.dart';

/// إشعارات النادي: مفتاح لكل نوع للنادي كله، مجمّعة بالجمهور. المطفأ يُحفظ بـ `disabled_notifications`.
class ClubNotificationsCard extends StatelessWidget {
  const ClubNotificationsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SettingsCard(
      title: 'الإشعارات',
      subtitle: 'المطفأ لا يصل لأحد بالنادي.',
      children: [
        BlocBuilder<NotificationCatalogCubit, Slice<NotificationCatalog>>(
          builder: (context, slice) => SliceView<NotificationCatalog>(
            slice: slice,
            loading: const ListShimmer(count: 4),
            onRetry: context.read<NotificationCatalogCubit>().load,
            isEmpty: (d) => d.types.isEmpty,
            empty: Text('لا أنواع إشعارات قابلة للإطفاء.', style: UType.body(color: c.inkMuted)),
            builder: (context, catalog) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpace.s4,
              children: [
                for (final g in catalog.groups)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(g.label, style: UType.label(color: c.inkMuted).weight(600)),
                      for (final t in g.types) _TypeSwitch(t),
                    ],
                  ),
                if (catalog.platform.isNotEmpty)
                  Text(
                    'إشعارات المنصة (${catalog.platform.join('، ')}) تصل دائماً ولا تُطفأ.',
                    style: UType.caption(color: c.inkMuted),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TypeSwitch extends StatelessWidget {
  const _TypeSwitch(this.type);

  final NotificationType type;

  @override
  Widget build(BuildContext context) {
    final form = context.read<AppFormCubit>();
    return BlocSelector<AppFormCubit, AppFormState, (bool, bool)>(
      selector: (s) =>
          (!((s.values[ClubForm.disabled] as List<dynamic>?) ?? const []).contains(type.type), s.submitting),
      builder: (context, sel) => SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        value: sel.$1,
        title: Text(type.label, style: UType.body(color: context.colors.ink)),
        subtitle: type.description.isEmpty
            ? null
            : Text(type.description, style: UType.caption(color: context.colors.inkMuted)),
        onChanged: sel.$2
            ? null
            : (on) {
                final now = [...?(form.value(ClubForm.disabled) as List<dynamic>?)?.whereType<String>()];
                on ? now.remove(type.type) : now.add(type.type);
                form.set(ClubForm.disabled, now);
              },
      ),
    );
  }
}
