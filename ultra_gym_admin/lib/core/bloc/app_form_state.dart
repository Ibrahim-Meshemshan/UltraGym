part of 'app_form_cubit.dart';

/// حالة النموذج: القيم غير النصية، أخطاء الحقول، الفشل العام، والإرسال.
class AppFormState extends Equatable {
  const AppFormState({this.values = const {}, this.fieldErrors = const {}, this.failure, this.submitting = false});

  /// القيم غير النصية (القوائم، التواريخ، الاختيارات). النصوص في controllers الـ Cubit.
  final Json values;

  /// خطأ واحد لكل حقل (تحقق محلي أو 422).
  final Map<String, String> fieldErrors;

  /// الفشل العام (409، شبكة...) يُعرض أعلى النموذج.
  final Failure? failure;
  final bool submitting;

  String? errorOf(String name) => fieldErrors[name];

  AppFormState copyWith({
    Json? values,
    Map<String, String>? fieldErrors,
    Failure? Function()? failure,
    bool? submitting,
  }) => AppFormState(
    values: values ?? this.values,
    fieldErrors: fieldErrors ?? this.fieldErrors,
    failure: failure == null ? this.failure : failure(),
    submitting: submitting ?? this.submitting,
  );

  @override
  List<Object?> get props => [values, fieldErrors, failure, submitting];
}
