import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/core.dart';
import '../../../../core/layout/app_top_bar.dart';
import '../../../branches/presentation/bloc/branch_scope_cubit.dart';
import '../../domain/models/quick_search_models.dart';
import '../bloc/quick_search_cubit.dart';
import 'quick_search_dialog.dart';

/// البحث السريع بالشريط العلوي (`Dashboard.html`): حبة "ابحث عن عضو..." على الكمبيوتر،
/// وزر أيقونة حين يضيق الشريط. يفتح نافذة البحث، واختصاره Ctrl K (`QuickSearch.shortcuts`).
class QuickSearchButton extends StatelessWidget {
  const QuickSearchButton({super.key});

  /// أضيق عرض تبقى فيه الحبة مقروءة؛ أضيق منه ← زر أيقونة.
  static const _minPill = AppSize.gridItem * .75;

  @override
  Widget build(BuildContext context) {
    void open() => QuickSearch.open(context);
    final icon = TopBarIconButton(icon: Icons.search_rounded, tooltip: 'بحث عن عضو (Ctrl K)', onPressed: open);
    if (!context.isDesktop) return icon;
    return Flexible(
      child: LayoutBuilder(
        builder: (context, box) => box.maxWidth < _minPill
            ? Align(alignment: AlignmentDirectional.centerEnd, child: icon)
            : Semantics(
                button: true,
                label: 'بحث عن عضو',
                child: TopBarPill(
                  icon: Icons.search_rounded,
                  label: 'ابحث عن عضو بالاسم أو الموبايل أو المعرّف',
                  muted: true,
                  maxWidth: AppSize.searchPill,
                  trailing: const _KeyHint('Ctrl K'),
                  onTap: open,
                ),
              ),
      ),
    );
  }
}

/// فتح نافذة البحث (من الحبة أو الاختصار) بالفرع المحدد حالياً.
abstract final class QuickSearch {
  static Future<void> open(BuildContext context) {
    final branchId = context.read<BranchScopeCubit>().state.branchId;
    return showDialog<void>(
      context: context,
      builder: (_) => BlocProvider(
        create: (_) => sl<QuickSearchCubit>(param1: branchId),
        child: const QuickSearchDialog(),
      ),
    );
  }

  /// اختيار عضو لعملية (بيع اشتراك): نفس النافذة، والعضو المختار يرجع بدل فتح ملفه.
  static Future<LookupPlayer?> pick(BuildContext context) {
    final branchId = context.read<BranchScopeCubit>().state.branchId;
    return showDialog<LookupPlayer>(
      context: context,
      builder: (_) => BlocProvider(
        create: (_) => sl<QuickSearchCubit>(param1: branchId),
        child: const QuickSearchDialog(picking: true),
      ),
    );
  }

  /// Ctrl K أو ⌘ K؟
  static bool isHotkey(KeyEvent e) =>
      e is KeyDownEvent &&
      e.logicalKey == LogicalKeyboardKey.keyK &&
      (HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed);
}

/// اختصار البحث على مستوى لوحة المفاتيح (لا يعتمد على التركيز: بالويب قد لا يكون أي عنصر مركّزاً).
/// يعمل فقط والهيكل بالواجهة (لا نافذة فوقه). StatefulWidget بنية: يسجّل المعالج ويزيله فقط.
class QuickSearchHotkey extends StatefulWidget {
  const QuickSearchHotkey({super.key, required this.child});

  final Widget child;

  @override
  State<QuickSearchHotkey> createState() => _QuickSearchHotkeyState();
}

class _QuickSearchHotkeyState extends State<QuickSearchHotkey> {
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  bool _onKey(KeyEvent e) {
    if (!QuickSearch.isHotkey(e) || !mounted || !(ModalRoute.of(context)?.isCurrent ?? true)) return false;
    QuickSearch.open(context);
    return true;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _KeyHint extends StatelessWidget {
  const _KeyHint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.s1 + AppSpace.s1 / 2),
      decoration: BoxDecoration(
        border: Border.all(color: c.line),
        borderRadius: AppRadius.smAll,
      ),
      child: LtrText(text, style: UType.caption(color: c.inkFaint)),
    );
  }
}
