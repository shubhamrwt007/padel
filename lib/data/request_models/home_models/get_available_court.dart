class GetAllActiveCourtsForSlotWiseModel {
  String? status;
  bool? success;
  int? count;
  List<Data>? data;

  GetAllActiveCourtsForSlotWiseModel({
    this.status,
    this.success,
    this.count,
    this.data,
  });

  GetAllActiveCourtsForSlotWiseModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    success = json['success'];
    count = json['count'];
    data = (json['data'] as List?)
        ?.map((e) => Data.fromJson(e))
        .toList();
  }

  Map<String, dynamic> toJson() => {
        'status': status,
        'success': success,
        'count': count,
        'data': data?.map((e) => e.toJson()).toList(),
      };
}

class Data {
  String? sId;
  String? clubName;
  RegisterClubId? registerClubId;
  String? courtName;
  List<Slots>? slots;
  List<BusinessHours>? businessHours;

  Data({
    this.sId,
    this.clubName,
    this.registerClubId,
    this.courtName,
    this.slots,
    this.businessHours,
  });

  Data.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    clubName = json['clubName'];
    registerClubId = json['register_club_id'] != null
        ? RegisterClubId.fromJson(json['register_club_id'])
        : null;
    courtName = json['courtName'];
    slots = (json['slots'] as List?)
        ?.map((e) => Slots.fromJson(e))
        .toList();
    businessHours = (json['businessHours'] as List?)
        ?.map((e) => BusinessHours.fromJson(e))
        .toList();
  }

  Map<String, dynamic> toJson() => {
        '_id': sId,
        'clubName': clubName,
        'register_club_id': registerClubId?.toJson(),
        'courtName': courtName,
        'slots': slots?.map((e) => e.toJson()).toList(),
        'businessHours': businessHours?.map((e) => e.toJson()).toList(),
      };
}

class RegisterClubId {
  String? sId;
  OwnerId? ownerId;
  String? clubName;
  List<BusinessHours>? businessHours;
  List<String>? courtType;
  List<String>? courtImage;
  String? address;
  String? city;
  String? state;
  String? zipCode;
  List<Location>? locations;


  RegisterClubId({
    this.sId,
    this.ownerId,
    this.clubName,
    this.businessHours,
    this.courtType,
    this.courtImage,
    this.address,
    this.city,
    this.state,
    this.zipCode,
    this.locations
  });

  RegisterClubId.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    ownerId =
        json['ownerId'] != null ? OwnerId.fromJson(json['ownerId']) : null;
    clubName = json['clubName'];
    businessHours = (json['businessHours'] as List?)
        ?.map((e) => BusinessHours.fromJson(e))
        .toList();
    courtType = (json['courtType'] as List?)?.cast<String>();
    courtImage = (json['courtImage'] as List?)?.cast<String>();
    address = json['address'];
    city = json['city'];
    state = json['state'];
    zipCode = json['zipCode'];
    locations = (json['locations'] as List?)
        ?.map((e) => Location.fromJson(e))
        .toList();
  }

  Map<String, dynamic> toJson() => {
        '_id': sId,
        'ownerId': ownerId?.toJson(),
        'clubName': clubName,
        'businessHours': businessHours?.map((e) => e.toJson()).toList(),
        'courtType': courtType,
        'courtImage': courtImage,
        'address': address,
        'city': city,
        'state': state,
        'zipCode': zipCode,
    'locations': locations?.map((e) => e.toJson()).toList(), // 👈 ADD THIS

  };
}
class Location {
  String? sId;
  String? city;
  String? address;
  String? zipCode;
  String? state;
  String? stateId;
  List<String>? courtType;
  bool? status;
  List<String>? categories;

  Location({
    this.sId,
    this.city,
    this.address,
    this.zipCode,
    this.state,
    this.stateId,
    this.courtType,
    this.status,
    this.categories,
  });

  Location.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    city = json['city'];
    address = json['address'];
    zipCode = json['zipCode'];
    state = json['state'];
    stateId = json['stateId'];
    courtType = (json['courtType'] as List?)?.cast<String>();
    status = json['status'];
    categories = (json['categories'] as List?)?.cast<String>();
  }

  Map<String, dynamic> toJson() => {
    '_id': sId,
    'city': city,
    'address': address,
    'zipCode': zipCode,
    'state': state,
    'stateId': stateId,
    'courtType': courtType,
    'status': status,
    'categories': categories,
  };
}

class OwnerId {
  String? sId;
  String? email;
  String? name;

  OwnerId({this.sId, this.email, this.name});

  OwnerId.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    email = json['email'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() => {
        '_id': sId,
        'email': email,
        'name': name,
      };
}

class BusinessHours {
  String? time;
  String? day;
  String? sId;

  BusinessHours({this.time, this.day, this.sId});

  BusinessHours.fromJson(Map<String, dynamic> json) {
    time = json['time'];
    day = json['day'];
    sId = json['_id'];
  }

  Map<String, dynamic> toJson() => {
        'time': time,
        'day': day,
        '_id': sId,
      };
}

class Slots {
  String? sId;
  String? time;
  int? amount;
  String? status;
  String? availabilityStatus;
  int? duration;
  String? bookingTime;
  bool? has30MinPrice;
  String? userId;
  List<BusinessHours>? businessHours;

  Slots({
    this.sId,
    this.time,
    this.amount,
    this.status,
    this.availabilityStatus,
    this.duration,
    this.bookingTime,
    this.has30MinPrice,
    this.userId,
    this.businessHours,
  });

  Slots.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    time = json['time'];
    amount = json['amount'];
    status = json['status'];
    availabilityStatus = json['availabilityStatus'];
    duration = json['duration'];
    bookingTime = json['bookingTime'];
    has30MinPrice = json['has30MinPrice'];
    userId = json['userId'];
    businessHours = (json['businessHours'] as List?)
        ?.map((e) => BusinessHours.fromJson(e))
        .toList();
  }

  Map<String, dynamic> toJson() => {
        '_id': sId,
        'time': time,
        'amount': amount,
        'status': status,
        'availabilityStatus': availabilityStatus,
        'duration': duration,
        'bookingTime': bookingTime,
        'has30MinPrice': has30MinPrice,
        'userId': userId,
        'businessHours': businessHours?.map((e) => e.toJson()).toList(),
      };
}
