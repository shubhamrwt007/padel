// ====================== MAIN WRAPPER ======================

class CarteBookingResponse {
  final bool? requiresPayment;
  final PaymentData? payment;
  final CarteBookingModel? booking;

  CarteBookingResponse({
    this.requiresPayment,
    this.payment,
    this.booking,
  });

  factory CarteBookingResponse.fromJson(Map<String, dynamic> json) {
    // Payment flow
    if (json.containsKey('requiresPayment')) {
      return CarteBookingResponse(
        requiresPayment: json['requiresPayment'],
        payment: PaymentData.fromJson(json),
      );
    }

    // Booking success flow
    return CarteBookingResponse(
      requiresPayment: false,
      booking: CarteBookingModel.fromJson(json),
    );
  }
}

// ====================== PAYMENT ======================

class PaymentData {
  final bool? requiresPayment;
  final String? orderId;
  final int? amount;
  final String? currency;
  final String? key;
  final int? walletAmountUsed;
  final int? razorpayAmountUsed;
  final String? paymentMethod;

  PaymentData({
    this.requiresPayment,
    this.orderId,
    this.amount,
    this.currency,
    this.key,
    this.walletAmountUsed,
    this.razorpayAmountUsed,
    this.paymentMethod,
  });

  factory PaymentData.fromJson(Map<String, dynamic> json) {
    return PaymentData(
      requiresPayment: json['requiresPayment'],
      orderId: json['orderId'],
      amount: json['amount'],
      currency: json['currency'],
      key: json['key'],
      walletAmountUsed: json['walletAmountUsed'],
      razorpayAmountUsed: json['razorpayAmountUsed'],
      paymentMethod: json['paymentMethod'],
    );
  }
}

// ====================== BOOKING ROOT ======================

class CarteBookingModel {
  String? message;
  List<Bookings>? bookings;
  int? count;

  CarteBookingModel({this.message, this.bookings, this.count});

  CarteBookingModel.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    bookings = (json['bookings'] as List?)
        ?.map((e) => Bookings.fromJson(e))
        .toList();
    count = json['count'];
  }
}

// ====================== BOOKINGS ======================

class Bookings {
  String? userId;
  String? registerClubId;
  int? totalAmount;
  String? bookingDate;
  String? bookingStatus;
  String? bookingType;
  List<Slot>? slot;
  String? createdAt;
  String? ownerId;
  String? updatedAt;
  String? sId;
  int? iV;

  Bookings.fromJson(Map<String, dynamic> json) {
    userId = json['userId'];
    registerClubId = json['register_club_id'];
    totalAmount = json['totalAmount'];
    bookingDate = json['bookingDate'];
    bookingStatus = json['bookingStatus'];
    bookingType = json['bookingType'];
    slot = (json['slot'] as List?)?.map((e) => Slot.fromJson(e)).toList();
    createdAt = json['createdAt'];
    ownerId = json['ownerId'];
    updatedAt = json['updatedAt'];
    sId = json['_id'];
    iV = json['__v'];
  }
}

// ====================== SLOT ======================

class Slot {
  String? slotId;
  String? courtName;
  String? courtId;
  String? bookingDate;
  List<SlotTimes>? slotTimes;
  List<BusinessHours>? businessHours;

  Slot.fromJson(Map<String, dynamic> json) {
    slotId = json['slotId'];
    courtName = json['courtName'];
    courtId = json['courtId'];
    bookingDate = json['bookingDate'];
    slotTimes =
        (json['slotTimes'] as List?)?.map((e) => SlotTimes.fromJson(e)).toList();
    businessHours =
        (json['businessHours'] as List?)?.map((e) => BusinessHours.fromJson(e)).toList();
  }
}

// ====================== SLOT TIMES ======================

class SlotTimes {
  String? time;
  int? amount;
  String? status;
  String? availabilityStatus;

  SlotTimes.fromJson(Map<String, dynamic> json) {
    time = json['time'];
    amount = json['amount'];
    status = json['status'];
    availabilityStatus = json['availabilityStatus'];
  }
}

// ====================== BUSINESS HOURS ======================

class BusinessHours {
  String? day;
  String? time;

  BusinessHours.fromJson(Map<String, dynamic> json) {
    day = json['day'];
    time = json['time'];
  }
}
