import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

import '../config/app_config.dart';

enum ConnectionStatus { unknown, online, offline }

/// فحص الاتصال الموحّد: `connectivity_plus` يلتقط تغيّر الشبكة فوراً، والفحص الفعلي على `/ping` بالخادم.
/// يبدأ مع التطبيق ويعيش طوال عمره. أي فشل شبكة بطلب يستدعي `recheck()`.
class ConnectionCubit extends Cubit<ConnectionStatus> {
  ConnectionCubit({Connectivity? connectivity, InternetConnection? checker})
      : _connectivity = connectivity ?? Connectivity(),
        _checker = checker ??
            InternetConnection.createInstance(
              useDefaultOptions: false,
              customCheckOptions: [InternetCheckOption(uri: Uri.parse('${AppConfig.apiBaseUrl}/ping'))],
            ),
        super(ConnectionStatus.unknown);

  final Connectivity _connectivity;
  final InternetConnection _checker;
  StreamSubscription<List<ConnectivityResult>>? _networkSub;
  StreamSubscription<InternetStatus>? _statusSub;

  bool get isOnline => state == ConnectionStatus.online;
  bool get isOffline => state == ConnectionStatus.offline;

  final _reconnected = StreamController<void>.broadcast();

  /// يطلق عند عودة الاتصال بعد انقطاع (الشاشات تتحدث وحدها، والمزامنة تبدأ).
  Stream<void> get onReconnected => _reconnected.stream;

  void start() {
    _networkSub ??= _connectivity.onConnectivityChanged.listen((_) => recheck());
    _statusSub ??= _checker.onStatusChange.listen(
      (s) => _set(s == InternetStatus.connected ? ConnectionStatus.online : ConnectionStatus.offline),
    );
    recheck();
  }

  Future<void> recheck() async {
    final ok = await _checker.hasInternetAccess;
    _set(ok ? ConnectionStatus.online : ConnectionStatus.offline);
  }

  void _set(ConnectionStatus s) {
    if (isClosed) return;
    if (s == ConnectionStatus.online && state == ConnectionStatus.offline) _reconnected.add(null);
    emit(s);
  }

  @override
  Future<void> close() async {
    await _networkSub?.cancel();
    await _statusSub?.cancel();
    await _reconnected.close();
    return super.close();
  }
}
