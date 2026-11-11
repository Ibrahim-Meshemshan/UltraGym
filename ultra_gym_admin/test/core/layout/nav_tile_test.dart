import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_gym_admin/core/layout/nav_tile.dart';
import 'package:ultra_gym_admin/core/theme/app_theme.dart';
import 'package:ultra_gym_admin/core/theme/app_tokens.dart';

void main() {
  Future<void> pump(WidgetTester tester, {bool selected = true}) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: 240,
              child: NavTile(
                icon: Icons.home_rounded,
                label: 'الرئيسية',
                selected: selected,
                collapsed: false,
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Finder ring() => find.byWidgetPredicate(
    (w) => w is DecoratedBox && w.decoration is BoxDecoration && (w.decoration as BoxDecoration).border != null,
  );

  testWidgets('label is vertically centred in the 44px tile', (tester) async {
    await pump(tester);
    final tile = tester.getRect(find.byType(AnimatedContainer));
    final label = tester.getRect(find.text('الرئيسية'));
    expect(tile.height, AppSize.navItem);
    expect((label.center.dy - tile.center.dy).abs(), lessThan(1));
  });

  testWidgets('focus ring shows for keyboard focus only', (tester) async {
    await pump(tester, selected: false);
    expect(ring(), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(ring(), findsOneWidget);
  });
}
