class GetPendingRequestCountModel {
  final String? message;
  final int? count;

  const GetPendingRequestCountModel({
    this.message,
    this.count,
  });

  factory GetPendingRequestCountModel.fromJson(Map<String, dynamic> json) {
    return GetPendingRequestCountModel(
      message: json['message'] as String?,
      count: json['count'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'count': count,
    };
  }
}
