class UpdateFcmTokenModel {
  final int? status;
  final String? message;
  final int? removedInvalidTokens;

  const UpdateFcmTokenModel({
    this.status,
    this.message,
    this.removedInvalidTokens,
  });

  factory UpdateFcmTokenModel.fromJson(Map<String, dynamic> json) {
    return UpdateFcmTokenModel(
      status: json['status'],
      message: json['message'],
      removedInvalidTokens: json['removedInvalidTokens'],
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'message': message,
    'removedInvalidTokens': removedInvalidTokens,
  };
}
