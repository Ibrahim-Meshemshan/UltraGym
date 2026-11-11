import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ultra_gym_reception/core/network/connection_cubit.dart';
import 'package:ultra_gym_reception/core/networking/api_result.dart';
import 'package:ultra_gym_reception/core/networking/auth_interceptor.dart';
import 'package:ultra_gym_reception/core/networking/server_clock.dart';
import 'package:ultra_gym_reception/core/theme/app_theme.dart';
import 'package:ultra_gym_reception/core/theme/theme_cubit.dart';
import 'package:ultra_gym_reception/core/utils/formatters.dart';
import 'package:ultra_gym_reception/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ultra_gym_reception/features/station/data/repo/station_repository.dart';
import 'package:ultra_gym_reception/features/station/domain/models/check_in_models.dart';
import 'package:ultra_gym_reception/features/station/domain/models/station_models.dart';
import 'package:ultra_gym_reception/features/station/presentation/bloc/active_branch_cubit.dart';
import 'package:ultra_gym_reception/features/station/presentation/bloc/station_bloc.dart';
import 'package:ultra_gym_reception/features/station/presentation/screens/station_screen.dart';
import 'package:ultra_gym_reception/features/station/presentation/widgets/qr_scan_dialog.dart';

import '../auth/fake_auth_repository.dart';
import 'fake_station_repository.dart';

void main() {
  final sl = GetIt.instance;
  late FakeStationRepository repo;
  late FakeQrScanner scanner;
  late AuthBloc auth;
  late ThemeCubit theme;
  const token = 'UG1.khielcztct3p.1794400000.aB-c_9';

  setUpAll(() => Formatters.init('Asia/Damascus'));

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repo = FakeStationRepository();
    scanner = FakeQrScanner();
    theme = ThemeCubit(prefs);
    sl
      ..registerSingleton<ServerClock>(ServerClock()..sync(DateTime.utc(2026, 11, 11, 14, 31)))
      ..registerSingleton<ConnectionCubit>(ConnectionCubit())
      ..registerSingleton<StationRepository>(repo)
      ..registerSingleton<ActiveBranchCubit>(ActiveBranchCubit(repo, prefs))
      ..registerSingleton<QrScanner>(scanner)
      ..registerFactory<StationBloc>(() => StationBloc(repo));
  });

  tearDown(() async {
    await sl.reset();
    await auth.close();
    await theme.close();
  });

  Future<void> pump(WidgetTester tester, {double width = 1280, bool dark = false}) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // يُنشأ داخل منطقة الاختبار حتى تكتمل أحداثه مع pump.
    auth = AuthBloc(FakeAuthRepository()..token = true, SessionEvents())..add(const AuthStarted());
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [BlocProvider.value(value: auth), BlocProvider.value(value: theme)],
        child: MaterialApp(
          theme: dark ? AppTheme.dark : AppTheme.light,
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (context, child) =>
              MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: true), child: child!),
          home: const StationScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> enter(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  testWidgets('ready to scan: branch, section now, today counts and the feed', (tester) async {
    await pump(tester);
    expect(find.text('جاهز للمسح'), findsOneWidget);
    expect(find.text('ماستر'), findsOneWidget);
    expect(find.textContaining('قسم: ذكور الآن'), findsOneWidget);
    expect(find.text('متصل'), findsNothing, reason: 'no badge before the first connection check');
    expect(repo.todayCalls, [1]);
    expect(find.text('أحمد الخطيب'), findsOneWidget);
    expect(find.text('المعرّف · اشتراك اللاعب لا يشمل هذا الفرع'), findsOneWidget);
    expect(find.text('QR'), findsOneWidget);
    expect(find.text('سامر الحلبي'), findsOneWidget);
  });

  testWidgets('a QR typed by the barcode reader + Enter checks in untouched; the field clears', (tester) async {
    await pump(tester);
    await enter(tester, token);
    expect(repo.checkIns.single.body, {'qr_token': token, 'branch_id': 1});
    expect(find.text('مقبول · تم تسجيل الدخول 17:31'), findsOneWidget);
    expect(find.text('تدريب خاص شهري'), findsOneWidget);
    expect(find.text('DMO-098969  ·  +963944100001'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);
    expect(repo.todayCalls, [1, 1]);

    await tap(tester, find.text('العضو التالي'));
    expect(find.text('جاهز للمسح'), findsOneWidget);
  });

  testWidgets('camera button: the scanned code checks in; cancelling sends nothing', (tester) async {
    await pump(tester);
    scanner.next = token;
    await tap(tester, find.text('مسح QR'));
    expect(scanner.opened, 1);
    expect(repo.checkIns.single.body['qr_token'], token);

    scanner.next = null;
    await tap(tester, find.text('مسح QR'));
    expect(repo.checkIns, hasLength(1));
  });

  testWidgets('expired QR: the server message, its code and what to ask the member', (tester) async {
    repo.checkInResults.add(qrExpired);
    await pump(tester);
    await enter(tester, token);
    expect(find.text('رمز QR منتهي الصلاحية، اطلب من اللاعب تحديثه'), findsOneWidget);
    expect(find.text('QR_EXPIRED'), findsOneWidget);
    expect(find.text('اطلب من العضو تحديث الرمز بالتطبيق ثم امسحه مجدداً.'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsNothing);
  });

  testWidgets('rejection card shows the reason and its code; duplicate says nothing new was recorded', (tester) async {
    repo.checkInResults
      ..add(rejected)
      ..add(ApiSuccess(CheckInResult.fromJson(checkInJson(duplicate: true), message: 'اللاعب مسجّل دخوله مسبقاً منذ 19 ثانية')));
    await pump(tester);
    await enter(tester, 'dmo-066025');
    expect(repo.checkIns.single.body['member_code'], 'DMO-066025');
    expect(find.text('مرفوض · اشتراك اللاعب لا يشمل هذا الفرع'), findsOneWidget);
    expect(find.text('BRANCH_NOT_ALLOWED'), findsOneWidget);

    await enter(tester, 'DMO-098969');
    expect(find.text('اللاعب مسجّل دخوله مسبقاً منذ 19 ثانية · لم يُسجَّل دخول جديد'), findsOneWidget);
  });

  testWidgets('a name lists matches with the server verdict; tapping one checks in by id', (tester) async {
    await pump(tester);
    await enter(tester, 'أحمد');
    expect(repo.lookups.single.q, 'أحمد');
    expect(find.text('نتائج البحث عن «أحمد»'), findsOneWidget);
    expect(find.text('اشتراك اللاعب لا يشمل هذا الفرع'), findsOneWidget);

    await tap(tester, find.text('رامي العمر').first);
    expect(repo.checkIns.single.body, {'player_id': 7, 'branch_id': 1});
  });

  testWidgets('network failure: retry resends with the same key', (tester) async {
    repo.checkInResults.add(networkDown);
    await pump(tester);
    await enter(tester, token);
    expect(find.text('لم يُسجَّل الدخول بعد. أعد المحاولة.'), findsOneWidget);
    await tap(tester, find.text('إعادة المحاولة'));
    expect(repo.checkIns, hasLength(2));
    expect(repo.checkIns[1].key, repo.checkIns[0].key);
    expect(find.text('مقبول · تم تسجيل الدخول 17:31'), findsOneWidget);
  });

  testWidgets('no branch for the account: an invitation, no station', (tester) async {
    repo.branchesResult = const ApiSuccess(<StationBranch>[]);
    await pump(tester);
    expect(find.text('لا فرع لحسابك'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  for (final (w, dark) in [(360.0, true), (800.0, false), (1024.0, true), (1440.0, false)]) {
    testWidgets('fits at ${w.toInt()}px ${dark ? 'dark' : 'light'} with a result and a search', (tester) async {
      await pump(tester, width: w, dark: dark);
      await enter(tester, token);
      expect(find.text('مقبول · تم تسجيل الدخول 17:31'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await enter(tester, 'أحمد');
      expect(tester.takeException(), isNull);
    });
  }
}
