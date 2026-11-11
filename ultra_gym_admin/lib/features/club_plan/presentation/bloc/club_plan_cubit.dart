import 'dart:async';

import '../../../../core/core.dart';
import '../../data/repo/club_plan_repository.dart';
import '../../domain/models/club_plan_models.dart';

/// باقة النادي بعمر الهيكل: الميزات (`entitlements`)، واشتراك النادي بالمنصة (للمالك)،
/// و `readOnly` حين يرفض الخادم أي عملية بـ `SUBSCRIPTION_EXPIRED` (يصل للاستقبال أيضاً).
class ClubPlanState extends Equatable {
  const ClubPlanState({this.entitlements = const Slice(), this.subscription, this.readOnlySeen = false});

  final Slice<Entitlements> entitlements;
  final ClubSubscription? subscription;

  /// رفض الخادم عملية لأن الاشتراك منتهٍ (قراءة فقط).
  final bool readOnlySeen;

  /// قبل التحميل أو عند فشله تُعامل كل ميزة كمتاحة: الخادم يرفض ما ليس بالباقة على أي حال.
  bool has(String? feature) => feature == null || (entitlements.data?.has(feature) ?? true);

  bool get readOnly => readOnlySeen || (subscription?.isReadOnly ?? false);
  bool get inGrace => !readOnly && (subscription?.inGrace ?? false);

  ClubPlanState copyWith({
    Slice<Entitlements>? entitlements,
    ClubSubscription? Function()? subscription,
    bool? readOnlySeen,
  }) => ClubPlanState(
    entitlements: entitlements ?? this.entitlements,
    subscription: subscription == null ? this.subscription : subscription(),
    readOnlySeen: readOnlySeen ?? this.readOnlySeen,
  );

  @override
  List<Object?> get props => [entitlements, subscription, readOnlySeen];
}

class ClubPlanCubit extends Cubit<ClubPlanState> {
  ClubPlanCubit(this._repo, SessionEvents events, {required this.owner}) : super(const ClubPlanState()) {
    _events = events.stream.listen((e) {
      if (e == SessionEvent.readOnly && !state.readOnlySeen) emit(state.copyWith(readOnlySeen: true));
    });
  }

  final ClubPlanRepository _repo;

  /// اشتراك النادي بالمنصة للمالك فقط (الخادم يرفضه للاستقبال).
  final bool owner;
  late final StreamSubscription<SessionEvent> _events;

  Future<void> load() async {
    emit(state.copyWith(entitlements: state.entitlements.toLoading()));
    await Future.wait([_entitlements(), if (owner) _subscription()]);
  }

  Future<void> _entitlements() async {
    final r = await _repo.entitlements();
    if (isClosed) return;
    emit(state.copyWith(entitlements: state.entitlements.fromResult(r)));
  }

  /// فشلها لا يهم: بلا شريط فقط.
  Future<void> _subscription() async {
    final r = await _repo.subscription();
    if (isClosed) return;
    if (r case ApiSuccess(:final data)) emit(state.copyWith(subscription: () => data));
  }

  @override
  Future<void> close() async {
    await _events.cancel();
    return super.close();
  }
}
