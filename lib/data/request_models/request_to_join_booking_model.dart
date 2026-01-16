class RequestToJoinBookingModel {
  final String? message;
  final Request? request;

  const RequestToJoinBookingModel({
    this.message,
    this.request,
  });

  factory RequestToJoinBookingModel.fromJson(Map<String, dynamic> json) {
    return RequestToJoinBookingModel(
      message: json['message'],
      request: json['request'] != null
          ? Request.fromJson(json['request'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'message': message,
    if (request != null) 'request': request!.toJson(),
  };
}

class Request {
  final String? matchCreatorId;
  final String? playerId;
  final String? bookingId;
  final String? preferredTeam;
  final String? status;
  final String? type;
  final String? id;
  final String? createdAt;
  final String? updatedAt;
  final int? version;

  const Request({
    this.matchCreatorId,
    this.playerId,
    this.bookingId,
    this.preferredTeam,
    this.status,
    this.type,
    this.id,
    this.createdAt,
    this.updatedAt,
    this.version,
  });

  factory Request.fromJson(Map<String, dynamic> json) {
    return Request(
      matchCreatorId: json['matchCreatorId'],
      playerId: json['playerId'],
      bookingId: json['bookingId'],
      preferredTeam: json['preferredTeam'],
      status: json['status'],
      type: json['type'],
      id: json['_id'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      version: json['__v'],
    );
  }

  Map<String, dynamic> toJson() => {
    'matchCreatorId': matchCreatorId,
    'playerId': playerId,
    'bookingId': bookingId,
    'preferredTeam': preferredTeam,
    'status': status,
    'type': type,
    '_id': id,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    '__v': version,
  };
}
