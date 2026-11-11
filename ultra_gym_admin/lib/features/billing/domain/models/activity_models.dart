import '../../../../core/core.dart';

/// سطر بسجل النشاط (`ActivityLogController::payload`): من فعل ماذا ومتى. التفاصيل تضيف القيم قبل وبعد والعنوان.
class ActivityEntry extends Equatable {
  const ActivityEntry({
    required this.id,
    required this.action,
    required this.module,
    required this.moduleLabel,
    required this.description,
    required this.actor,
    this.actorId,
    this.byPlatformSupport = false,
    this.subject,
    this.createdAt,
    this.oldValues,
    this.newValues,
    this.ip,
  });

  factory ActivityEntry.fromJson(Json j) {
    final actor = j.obj('actor');
    return ActivityEntry(
      id: j.intv('id'),
      action: j.str('action'),
      module: j.str('module'),
      moduleLabel: j.str('module_label'),
      description: j.str('description'),
      actor: actor.str('name', 'النظام'),
      actorId: actor.intOrNull('id'),
      byPlatformSupport: j.flag('by_platform_support'),
      subject: j.objOrNull('subject')?.strOrNull('label'),
      createdAt: j.date('created_at'),
      oldValues: j.objOrNull('old_values'),
      newValues: j.objOrNull('new_values'),
      ip: j.strOrNull('ip_address'),
    );
  }

  final int id;
  final String action, module, moduleLabel, description, actor;

  /// null = النظام.
  final int? actorId;

  /// نفّذه فريق UltraGym بجلسة دعم.
  final bool byPlatformSupport;
  final String? subject, ip;
  final DateTime? createdAt;
  final Json? oldValues, newValues;

  /// المفاتيح التي تغيّرت قيمتها (أو كل القيم الجديدة لعملية إنشاء)، بترتيب الخادم.
  List<({String key, Object? before, Object? after})> get changes {
    final before = oldValues ?? const {};
    final after = newValues ?? const {};
    final keys = {...after.keys, ...before.keys};
    return [
      for (final k in keys)
        if (_text(before[k]) != _text(after[k])) (key: k, before: before[k], after: after[k]),
    ];
  }

  /// قيمة للعرض: القوائم بفواصل، و null "—".
  static String show(Object? v) => _text(v);

  static String _text(Object? v) => switch (v) {
    null => '—',
    final List<Object?> l => l.isEmpty ? '—' : l.map(_text).join('، '),
    final bool b => b ? 'نعم' : 'لا',
    final Map<Object?, Object?> m => m.entries.map((e) => '${e.key}: ${_text(e.value)}').join('، '),
    _ => '$v',
  };

  @override
  List<Object?> get props => [id, action, description, actor, subject, createdAt, oldValues, newValues];
}

/// مستخدم لفلتر السجل (المالك وموظفو الاستقبال من `GET accounts`).
typedef ActivityUser = ({int id, String name});
