import '../../../../core/core.dart';

/// جهاز استقبال مسجّل للعمل دون اتصال (`ReceptionController::devicePayload`).
/// يُسجَّل من شاشة الاستقبال نفسها (`POST reception/devices`)، واللوحة تعرضه وتوقفه فقط.
class ReceptionDevice extends Equatable {
  const ReceptionDevice({
    required this.id,
    required this.uuid,
    required this.name,
    required this.status,
    this.branchId,
    this.branchName,
    this.lastPackAt,
    this.lastSyncAt,
    this.createdAt,
  });

  factory ReceptionDevice.fromJson(Json j) {
    final branch = j.obj('branch');
    return ReceptionDevice(
      id: j.intv('id'),
      uuid: j.str('device_uuid'),
      name: j.str('name'),
      status: j.str('status'),
      branchId: branch.intOrNull('id'),
      branchName: branch.strOrNull('name'),
      lastPackAt: j.date('last_pack_at'),
      lastSyncAt: j.date('last_sync_at'),
      createdAt: j.date('created_at'),
    );
  }

  final int id;
  final String uuid, name;

  /// `active` | `revoked`.
  final String status;
  final int? branchId;
  final String? branchName;

  /// آخر تحميل لحزمة البيانات، وآخر مزامنة لعمليات دون اتصال (UTC؛ null = لم يحدث بعد).
  final DateTime? lastPackAt, lastSyncAt, createdAt;

  bool get isActive => status == 'active';

  /// المعرّف مختصراً كما بالنموذج: `7f3c…e91a`.
  String get shortUuid => uuid.length > 12 ? '${uuid.substring(0, 4)}…${uuid.substring(uuid.length - 4)}' : uuid;

  ReceptionDevice revoked() => ReceptionDevice(
    id: id,
    uuid: uuid,
    name: name,
    status: 'revoked',
    branchId: branchId,
    branchName: branchName,
    lastPackAt: lastPackAt,
    lastSyncAt: lastSyncAt,
    createdAt: createdAt,
  );

  @override
  List<Object?> get props => [id, uuid, name, status, branchId, branchName, lastPackAt, lastSyncAt, createdAt];
}

/// نصوص الأجهزة ونغماتها.
abstract final class DeviceTexts {
  static const statuses = [(value: 'active', label: 'فعّال'), (value: 'revoked', label: 'موقوف')];

  static ({String label, UTone tone}) status(ReceptionDevice d) =>
      d.isActive ? (label: 'فعّال', tone: UTone.success) : (label: 'موقوف', tone: UTone.neutral);

  /// "قبل 3 دقائق"، أو `never` حين لم يحدث بعد. بعد 30 يوماً يصير تاريخاً فيُعزل LTR (وإلا انقلب بالسطر العربي).
  static String when(DateTime? utc, DateTime now, {required String never}) {
    if (utc == null) return never;
    final text = Formatters.relative(utc, now: now);
    return now.difference(utc).inDays >= 30 ? Formatters.ltr(text) : text;
  }

  static String pack(ReceptionDevice d, DateTime now) => when(d.lastPackAt, now, never: 'لم يحمّل بعد');

  static String sync(ReceptionDevice d, DateTime now) => when(d.lastSyncAt, now, never: 'لم يزامن بعد');
}
