class LogoutModel {
  final String? status;
  final String? message;

  const LogoutModel({this.status, this.message});

  factory LogoutModel.fromJson(Map<String, dynamic> json) => LogoutModel(
    status: json['status'],
    message: json['message'],
  );

  Map<String, dynamic> toJson() => {
    'status': status,
    'message': message,
  };
}