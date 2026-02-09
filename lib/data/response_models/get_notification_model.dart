class GetNotificationModel {
  final String? message;
  final List<GetNotificationResponse>? notifications;

  GetNotificationModel({
    required this.message,
    required this.notifications,
  });

  factory GetNotificationModel.fromJson(Map<String, dynamic> json) {
    return GetNotificationModel(
      message: json['message'] ?? '',
      notifications: (json['notifications'] as List<dynamic>?)
          ?.map((e) => GetNotificationResponse.fromJson(e))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'message': message,
    'notifications': notifications?.map((e) => e.toJson()).toList(),
  };
}

class GetNotificationResponse {
  final String? id;
  final String? userId;
  final String? matchId;
  final String? adminId;
  final String? notificationType;
  final String? redirect;
  final String? profileImage;
  final BookingId? bookingId;
  final String? notificationUrl;
  final String? title;
  final String? message;
  final bool? isRead;
  final String? createdAt;
  final String? updatedAt;
  final int? version;

  GetNotificationResponse({
    required this.id,
    required this.userId,
    required this.matchId,
    required this.adminId,
    required this.notificationType,
    required this.redirect,
    required this.profileImage,
    required this.bookingId,
    required this.notificationUrl,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
  });

  factory GetNotificationResponse.fromJson(Map<String, dynamic> json) {
    return GetNotificationResponse(
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '',
      adminId: json['adminId'] ?? '',
      matchId: json['matchId'] ?? '',
      notificationType: json['notificationType'] ?? '',
      profileImage: json['profileImage'] ?? '',
      bookingId: json['bookingId'] != null
          ? BookingId.fromJson(json['bookingId'])
          : null,
      notificationUrl: json['notificationUrl'] ?? '',
      redirect: json['redirect'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      version: json['__v'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'userId': userId,
    'adminId': adminId,
    'matchId': matchId,
    'notificationType': notificationType,
    'profileImage': profileImage,
    if (bookingId != null) 'bookingId': bookingId!.toJson(),
    'notificationUrl': notificationUrl,
    'redirect': redirect,
    'title': title,
    'message': message,
    'isRead': isRead,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    '__v': version,
  };
}

class BookingId {
  final String? id;
  final String? userId;
  final String? registerClubId;
  final int? totalAmount;
  final String? bookingDate;
  final String? bookingStatus;
  final String? bookingType;
  final List<Slot>? slots;
  final String? createdAt;
  final String? ownerId;
  final String? updatedAt;
  final int? version;
  final String? cancellationDate;
  final String? cancellationReason;
  final String? cancellationReasonForOwner;
  final String? rejectedDate;

  BookingId({
    required this.id,
    required this.userId,
    required this.registerClubId,
    required this.totalAmount,
    required this.bookingDate,
    required this.bookingStatus,
    required this.bookingType,
    required this.slots,
    required this.createdAt,
    required this.ownerId,
    required this.updatedAt,
    required this.version,
    required this.cancellationDate,
    required this.cancellationReason,
    required this.cancellationReasonForOwner,
    required this.rejectedDate,
  });

  factory BookingId.fromJson(Map<String, dynamic> json) {
    return BookingId(
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '',
      registerClubId: json['register_club_id'] ?? '',
      totalAmount: json['totalAmount'] ?? 0,
      bookingDate: json['bookingDate'] ?? '',
      bookingStatus: json['bookingStatus'] ?? '',
      bookingType: json['bookingType'] ?? '',
      slots: (json['slot'] as List<dynamic>?)
          ?.map((e) => Slot.fromJson(e))
          .toList() ??
          [],
      createdAt: json['createdAt'] ?? '',
      ownerId: json['ownerId'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      version: json['__v'] ?? 0,
      cancellationDate: json['cancellationDate'] ?? '',
      cancellationReason: json['cancellationReason'] ?? '',
      cancellationReasonForOwner: json['cancellationReasonForOwner'] ?? '',
      rejectedDate: json['rejectedDate'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'userId': userId,
    'register_club_id': registerClubId,
    'totalAmount': totalAmount,
    'bookingDate': bookingDate,
    'bookingStatus': bookingStatus,
    'bookingType': bookingType,
    'slot': slots?.map((e) => e.toJson()).toList(),
    'createdAt': createdAt,
    'ownerId': ownerId,
    'updatedAt': updatedAt,
    '__v': version,
    'cancellationDate': cancellationDate,
    'cancellationReason': cancellationReason,
    'cancellationReasonForOwner': cancellationReasonForOwner,
    'rejectedDate': rejectedDate,
  };
}

class Slot {
  final String? slotId;
  final String? courtName;
  final String? courtId;
  final String? bookingDate;
  final List<SlotTime>? slotTimes;
  final List<BusinessHour>? businessHours;

  Slot({
    required this.slotId,
    required this.courtName,
    required this.courtId,
    required this.bookingDate,
    required this.slotTimes,
    required this.businessHours,
  });

  factory Slot.fromJson(Map<String, dynamic> json) {
    return Slot(
      slotId: json['slotId'] ?? '',
      courtName: json['courtName'] ?? '',
      courtId: json['courtId'] ?? '',
      bookingDate: json['bookingDate'] ?? '',
      slotTimes: (json['slotTimes'] as List<dynamic>?)
          ?.map((e) => SlotTime.fromJson(e))
          .toList() ??
          [],
      businessHours: (json['businessHours'] as List<dynamic>?)
          ?.map((e) => BusinessHour.fromJson(e))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'slotId': slotId,
    'courtName': courtName,
    'courtId': courtId,
    'bookingDate': bookingDate,
    'slotTimes': slotTimes?.map((e) => e.toJson()).toList(),
    'businessHours': businessHours?.map((e) => e.toJson()).toList(),
  };
}

class SlotTime {
  final String? time;
  final int? amount;
  final String? status;
  final String? availabilityStatus;

  SlotTime({
    required this.time,
    required this.amount,
    required this.status,
    required this.availabilityStatus,
  });

  factory SlotTime.fromJson(Map<String, dynamic> json) {
    return SlotTime(
      time: json['time'] ?? '',
      amount: json['amount'] ?? 0,
      status: json['status'] ?? '',
      availabilityStatus: json['availabilityStatus'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'time': time,
    'amount': amount,
    'status': status,
    'availabilityStatus': availabilityStatus,
  };
}

class BusinessHour {
  final String? day;
  final String? time;

  BusinessHour({
    required this.day,
    required this.time,
  });

  factory BusinessHour.fromJson(Map<String, dynamic> json) {
    return BusinessHour(
      day: json['day'] ?? '',
      time: json['time'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'day': day,
    'time': time,
  };
}
