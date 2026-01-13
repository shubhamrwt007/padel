class DeleteBulkSlotHistoryModel {
  final bool? success;
  final int? deletedCount;
  final String? message;

  const DeleteBulkSlotHistoryModel({
    this.success,
    this.deletedCount,
    this.message,
  });

  factory DeleteBulkSlotHistoryModel.fromJson(Map<String, dynamic> json) {
    return DeleteBulkSlotHistoryModel(
      success: json['success'] as bool?,
      deletedCount: json['deletedCount'] as int?,
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'deletedCount': deletedCount,
    'message': message,
  };
}
