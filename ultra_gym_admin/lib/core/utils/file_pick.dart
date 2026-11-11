import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

/// اختيار ملف للرفع وتحويله لجزء `FormData`. البايتات تُقرأ مباشرة فيعمل على الويب والجهاز.
abstract final class FilePick {
  static const imageExtensions = ['png', 'jpg', 'jpeg', 'webp'];

  /// صورة (شعار، صورة عضو). `maxBytes` حسب المسار (2MB للشعار، 3MB للصور).
  static Future<PickedUpload?> image({int maxBytes = 3 * 1024 * 1024}) =>
      pick(extensions: imageExtensions, maxBytes: maxBytes);

  static Future<PickedUpload?> pick({required List<String> extensions, required int maxBytes}) async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: extensions, withData: true);
    final file = result?.files.singleOrNull;
    final bytes = file?.bytes;
    if (file == null || bytes == null) return null;
    if (bytes.length > maxBytes) {
      final mb = (maxBytes / (1024 * 1024)).toStringAsFixed(0);
      return PickedUpload.tooLarge('حجم الملف أكبر من $mb ميغابايت. اختر ملفاً أصغر.');
    }
    return PickedUpload(MultipartFile.fromBytes(bytes, filename: file.name), file.name, bytes: bytes);
  }
}

/// ملف مختار جاهز للرفع، أو سبب رفضه محلياً.
class PickedUpload {
  const PickedUpload(this.file, this.name, {this.bytes}) : error = null;
  const PickedUpload.tooLarge(this.error) : file = null, name = '', bytes = null;

  final MultipartFile? file;
  final String name;
  final String? error;

  /// البايتات نفسها: جزء `MultipartFile` يُرسل مرة واحدة، فإعادة الإرسال (بعد 422) تبني جزءاً جديداً بـ `part()`.
  final Uint8List? bytes;

  int get size => bytes?.length ?? 0;

  MultipartFile part() => bytes == null ? file! : MultipartFile.fromBytes(bytes!, filename: name);

  /// `FormData` بحقل واحد: `upload.form('photo')`.
  FormData form(String field) => FormData.fromMap({field: file});
}
