import 'package:flutter/material.dart';
import 'package:ultragym_design/ultragym_design.dart';

import '../../responsive/responsive.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../utils/debouncer.dart';

/// رأس الجدول: بحث بـ `Debouncer` + فلاتر (`FilterMenu` / `FilterToggle`) + "مسح الفلاتر"، وتحته رقائق اختيارية.
class FilterBar extends StatelessWidget {
  const FilterBar({
    super.key,
    required this.search,
    required this.onSearch,
    this.hint = 'بحث',
    this.filters = const [],
    this.chips,
    this.onClear,
  });

  /// نص البحث الحالي من `ListQuery` (يُفرّغ الحقل عند "مسح الفلاتر").
  final String search;

  /// null = قائمة بلا بحث (الورديات مثلاً): الفلاتر وحدها من بداية السطر.
  final ValueChanged<String>? onSearch;
  final String hint;
  final List<Widget> filters;
  final Widget? chips;

  /// يظهر "مسح الفلاتر" فقط عند وجود فلتر أو بحث.
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final pad = context.cardPadding;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(pad, AppSpace.s4, pad, AppSpace.s4),
          child: LayoutBuilder(
            builder: (context, box) {
              final onSearch = this.onSearch;
              final rest = [
                ...filters,
                if (onClear != null)
                  TextButton.icon(
                    onPressed: onClear,
                    icon: const Icon(Icons.filter_alt_off_rounded, size: AppSize.iconSm),
                    label: const Text('مسح الفلاتر'),
                  ),
              ];
              if (onSearch == null) {
                return Wrap(
                  spacing: AppSpace.s2,
                  runSpacing: AppSpace.s2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: rest,
                );
              }
              final field = SearchField(value: search, hint: hint, onChanged: onSearch);
              // واسع: البحث يتمدد والفلاتر بجانبه؛ ضيق: البحث بسطر والفلاتر تلتف تحته.
              if (box.maxWidth >= AppSize.filterRow) {
                return Row(
                  children: [
                    Expanded(child: field),
                    for (final w in rest) ...[AppSpace.gap2, w],
                  ],
                );
              }
              return Wrap(
                spacing: AppSpace.s2,
                runSpacing: AppSpace.s2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(width: box.maxWidth, child: field),
                  ...rest,
                ],
              );
            },
          ),
        ),
        if (chips != null) Padding(padding: EdgeInsets.fromLTRB(pad, 0, pad, AppSpace.s4), child: chips),
      ],
    );
  }
}

/// حقل بحث بشكل حبة: يرسل النص بعد توقف الكتابة 400ms، وزر × للمسح.
class SearchField extends StatefulWidget {
  const SearchField({super.key, required this.value, required this.onChanged, this.hint = 'بحث'});

  final String value, hint;
  final ValueChanged<String> onChanged;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  late final _text = TextEditingController(text: widget.value);
  final _debounce = Debouncer();

  @override
  void didUpdateWidget(SearchField old) {
    super.didUpdateWidget(old);
    // مسح من خارج الحقل ("مسح الفلاتر"): لا نكتب فوق ما يكتبه المستخدم الآن.
    if (widget.value != old.value && widget.value.trim() != _text.text.trim()) _text.text = widget.value;
  }

  @override
  void dispose() {
    _debounce.dispose();
    _text.dispose();
    super.dispose();
  }

  void _changed(String v) => _debounce.run(() => widget.onChanged(v.trim()));

  void _clear() {
    _debounce.cancel();
    _text.clear();
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: context.isMobile ? AppSize.minTap : AppSize.filterPill,
      padding: const EdgeInsetsDirectional.only(start: AppSpace.s4, end: AppSpace.s1),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.line),
        borderRadius: AppRadius.fullAll,
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: AppSize.iconSm, color: c.inkMuted),
          AppSpace.gap2,
          Expanded(
            child: TextField(
              controller: _text,
              onChanged: _changed,
              onSubmitted: (v) {
                _debounce.cancel();
                widget.onChanged(v.trim());
              },
              textInputAction: TextInputAction.search,
              style: UType.body(color: c.ink),
              // بلا حدود الثيم: الحبة نفسها هي الإطار.
              decoration: InputDecoration(
                isCollapsed: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: widget.hint,
                hintStyle: UType.body(color: c.inkFaint),
              ),
            ),
          ),
          ValueListenableBuilder(
            valueListenable: _text,
            builder: (context, v, _) => v.text.isEmpty
                ? const SizedBox(width: AppSpace.s3)
                : IconButton(
                    tooltip: 'مسح البحث',
                    onPressed: _clear,
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.close_rounded, size: AppSize.iconSm, color: c.inkMuted),
                  ),
          ),
        ],
      ),
    );
  }
}
