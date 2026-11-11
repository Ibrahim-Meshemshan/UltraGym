import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
// ملفات محددة لا core.dart: الـ barrel بالويب يجرّ package:web الذي لا يعمل على VM الاختبارات.
import 'package:ultra_gym_player/core/bloc/slice.dart';
import 'package:ultra_gym_player/core/error/failure.dart';
import 'package:ultra_gym_player/core/networking/api_result.dart';
import 'package:ultra_gym_player/core/theme/app_theme.dart';
import 'package:ultra_gym_player/core/widgets/form/form_dialog.dart';
import 'package:ultra_gym_player/core/widgets/form/form_fields.dart';
import 'package:ultra_gym_player/core/widgets/slice_view.dart';

Widget _app(Widget child) => MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('SliceView shows the four states', (tester) async {
    Widget view(Slice<List<int>> s) => _app(SliceView<List<int>>(
          slice: s,
          loading: const Text('loading'),
          isEmpty: (d) => d.isEmpty,
          empty: const Text('empty'),
          onRetry: () {},
          builder: (_, d) => Text('items ${d.length}'),
        ));

    await tester.pumpWidget(view(const Slice()));
    expect(find.text('loading'), findsOneWidget);

    await tester.pumpWidget(view(const Slice<List<int>>().toFailure(const Failure(type: FailureType.server, message: 'خطأ بالخادم'))));
    await tester.pumpAndSettle();
    expect(find.text('خطأ بالخادم'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);

    await tester.pumpWidget(view(const Slice<List<int>>().toSuccess(const [])));
    await tester.pumpAndSettle();
    expect(find.text('empty'), findsOneWidget);

    await tester.pumpWidget(view(const Slice<List<int>>().toSuccess(const [1, 2])));
    await tester.pumpAndSettle();
    expect(find.text('items 2'), findsOneWidget);
  });

  testWidgets('FormDialog shows 422 errors under fields and closes on success', (tester) async {
    var attempt = 0;
    ApiSuccess<void>? result;
    await tester.pumpWidget(_app(Builder(
      builder: (context) => TextButton(
        onPressed: () async => result = await FormDialog.show<void>(
          context,
          title: 'تعديل بياناتي',
          fields: (_) => const FormColumn(children: [FormText('name', label: 'الاسم', required: true)]),
          onSubmit: (_) async => ++attempt == 1
              ? const ApiFailure(Failure(type: FailureType.validation, message: 'غير صالح', errors: {
                  'name': ['الاسم مستخدم مسبقاً.'],
                }))
              : const ApiSuccess(null),
        ),
        child: const Text('open'),
      ),
    )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('حفظ'));
    await tester.pumpAndSettle();
    expect(find.text('هذا الحقل مطلوب.'), findsOneWidget);
    expect(attempt, 0);

    await tester.enterText(find.byType(TextField), 'سامر');
    await tester.tap(find.text('حفظ'));
    await tester.pumpAndSettle();
    expect(find.text('الاسم مستخدم مسبقاً.'), findsOneWidget);

    await tester.tap(find.text('حفظ'));
    await tester.pumpAndSettle();
    expect(find.text('تعديل بياناتي'), findsNothing);
    expect(result, isNotNull);
  });
}
