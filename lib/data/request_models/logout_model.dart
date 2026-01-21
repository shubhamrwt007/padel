class LogOutModel {
  final int? status;
  final String? message;

  const LogOutModel({
    this.status,
    this.message,
  });

  factory LogOutModel.fromJson(Map<String, dynamic> json) {
    return LogOutModel(
      status: json['status'] as int?,
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'message': message,
  };
}
