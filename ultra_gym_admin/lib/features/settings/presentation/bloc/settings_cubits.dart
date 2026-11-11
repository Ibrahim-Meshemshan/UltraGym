import '../../../../core/core.dart';
import '../../../branches/domain/models/branch_models.dart';
import '../../data/repo/settings_repository.dart';
import '../../domain/models/branch_draft.dart';
import '../../domain/models/settings_models.dart';

/// ملف النادي وإعداداته (تبويب النادي، وحد الفروع بتبويب الفروع).
class ClubCubit extends LoadCubit<ClubProfile> {
  ClubCubit(SettingsRepository repo) : super(repo.club);
}

/// أنواع الإشعارات القابلة للإطفاء.
class NotificationCatalogCubit extends LoadCubit<NotificationCatalog> {
  NotificationCatalogCubit(SettingsRepository repo) : super(repo.notificationTypes);
}

/// كل فروع النادي (الفعّالة والموقوفة) لتبويب الفروع.
class SettingsBranchesCubit extends LoadCubit<List<Branch>> {
  SettingsBranchesCubit(SettingsRepository repo) : super(repo.branches);
}

class BranchEditorState extends Equatable {
  const BranchEditorState({required this.draft, this.errors = const {}, this.saving = false, this.failure});

  final BranchDraft draft;

  /// أخطاء الحقول بمفاتيح الخادم (`gender_schedule.0.from`): من التحقق المحلي أو 422.
  final Map<String, String> errors;
  final bool saving;
  final Failure? failure;

  String? error(String path) => errors[path];

  BranchEditorState copyWith({BranchDraft? draft, Map<String, String>? errors, bool? saving, (Failure?,)? failure}) =>
      BranchEditorState(
        draft: draft ?? this.draft,
        errors: errors ?? this.errors,
        saving: saving ?? this.saving,
        failure: failure == null ? this.failure : failure.$1,
      );

  @override
  List<Object?> get props => [draft, errors, saving, failure];
}

/// محرر الفرع: البيانات ونظام الدخول وفتراته محلياً، والحفظ يرسل الفرع كاملاً.
/// تعديل حقل يمسح خطأه، وإضافة فترة أو حذفها تمسح كل الأخطاء (المفاتيح بالترتيب).
class BranchEditorCubit extends Cubit<BranchEditorState> {
  BranchEditorCubit(this._repo, BranchDraft draft) : super(BranchEditorState(draft: draft));

  final SettingsRepository _repo;
  final _keeper = IdempotencyKeeper();

  BranchDraft get _d => state.draft;

  void _edit(BranchDraft next, {String? path}) {
    final errors = path == null ? const <String, String>{} : ({...state.errors}..remove(path));
    emit(state.copyWith(draft: next, errors: errors, failure: (null,)));
  }

  void setName(String v) => _edit(_d.copyWith(name: v), path: 'name');
  void setPhone(String v) => _edit(_d.copyWith(phone: v), path: 'phone');
  void setCity(String v) => _edit(_d.copyWith(city: v), path: 'city');
  void setAddress(String v) => _edit(_d.copyWith(address: v), path: 'address');
  void setPrice(String v) => _edit(_d.copyWith(price: v), path: 'day_pass_price_usd');

  /// أوقات منفصلة بلا فترات: تبدأ بفترة جاهزة للتعديل.
  void setPolicy(String v) => _edit(
    _d.copyWith(policy: v, slots: v == 'time_split' && _d.slots.isEmpty ? [SlotDraft.blank()] : null),
    path: 'gender_schedule',
  );

  void addSlot() {
    if (_d.slots.length >= BranchDraft.maxSlots) return;
    _edit(_d.copyWith(slots: [..._d.slots, SlotDraft.blank()]));
  }

  void removeSlot(int uid) => _edit(
    _d.copyWith(
      slots: [
        for (final s in _d.slots)
          if (s.uid != uid) s,
      ],
    ),
  );

  int _index(int uid) => _d.slots.indexWhere((s) => s.uid == uid);

  void _slot(int uid, String field, SlotDraft Function(SlotDraft s) f) => _edit(
    _d.copyWith(slots: [for (final s in _d.slots) s.uid == uid ? f(s) : s]),
    path: 'gender_schedule.${_index(uid)}.$field',
  );

  void toggleDay(int uid, String day) => _slot(
    uid,
    'days',
    (s) => s.copyWith(days: s.days.contains(day) ? [...s.days.where((d) => d != day)] : [...s.days, day]),
  );

  void setFrom(int uid, String v) => _slot(uid, 'from', (s) => s.copyWith(from: v));
  void setTo(int uid, String v) => _slot(uid, 'to', (s) => s.copyWith(to: v));
  void setGender(int uid, String v) => _slot(uid, 'gender', (s) => s.copyWith(gender: v));

  /// يرجع الفرع المحفوظ، أو null (أخطاء محلية أو فشل الخادم بالحالة).
  Future<Branch?> save() async {
    final local = _d.validate();
    if (local.isNotEmpty) {
      emit(state.copyWith(errors: local, failure: (null,)));
      return null;
    }
    final body = _d.body();
    emit(state.copyWith(saving: true, errors: const {}, failure: (null,)));
    final r = await _repo.saveBranch(body, id: _d.id, idempotencyKey: _d.isNew ? _keeper.keyFor(body) : null);
    if (isClosed) return null;
    switch (r) {
      case ApiSuccess(:final data):
        emit(state.copyWith(saving: false, draft: BranchDraft.of(data)));
        return data;
      case ApiFailure(:final failure):
        emit(state.copyWith(saving: false, errors: failure.fieldErrors, failure: (failure,)));
        return null;
    }
  }
}
