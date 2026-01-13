class DeleteSlotHistoryModel {
  final bool success;
  final bool deleted;
  final String message;

  const DeleteSlotHistoryModel({
    required this.success,
    required this.deleted,
    required this.message,
  });

  factory DeleteSlotHistoryModel.fromJson(Map<String, dynamic> json) {
    return DeleteSlotHistoryModel(
      success: json['success'] ?? false,
      deleted: json['deleted'] ?? false,
      message: json['message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'deleted': deleted,
    'message': message,
  };
}
