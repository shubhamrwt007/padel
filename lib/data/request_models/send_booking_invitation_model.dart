class SendBookingInvitationModel {
  int? status;
  String? message;
  int? sent;
  int? total;

  SendBookingInvitationModel({
    this.status,
    this.message,
    this.sent,
    this.total,
  });

  factory SendBookingInvitationModel.fromJson(Map<String, dynamic> json) {
    return SendBookingInvitationModel(
      status: json['status'],
      message: json['message'],
      sent: json['sent'],
      total: json['total'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'sent': sent,
      'total': total,
    };
  }
}