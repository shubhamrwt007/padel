class GetCourtsByDurationModel {
  String? status;
  bool? success;
  int? count;
  List<GetCourtsByDurationData>? data;

  GetCourtsByDurationModel({
    this.status,
    this.success,
    this.count,
    this.data,
  });

  GetCourtsByDurationModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    success = json['success'];
    count = json['count'];
    if (json['data'] != null) {
      data = <GetCourtsByDurationData>[];
      json['data'].forEach((v) {
        data!.add(GetCourtsByDurationData.fromJson(v));
      });
    }
  }
}

class GetCourtsByDurationData {
  String? clubName;
  RegisterClub? registerClub;
  List<Court>? courts;

  GetCourtsByDurationData({
    this.clubName,
    this.registerClub,
    this.courts,
  });

  GetCourtsByDurationData.fromJson(Map<String, dynamic> json) {
    clubName = json['clubName'];
    registerClub = json['register_club_id'] != null
        ? RegisterClub.fromJson(json['register_club_id'])
        : null;

    if (json['courts'] != null) {
      courts = <Court>[];
      json['courts'].forEach((v) {
        courts!.add(Court.fromJson(v));
      });
    }
  }
}

class Court {
  String? id;
  String? courtName;
  List<CourtSlot>? slots;

  Court({
    this.id,
    this.courtName,
    this.slots,
  });

  Court.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    courtName = json['courtName'];

    if (json['slots'] != null) {
      slots = <CourtSlot>[];
      json['slots'].forEach((v) {
        slots!.add(CourtSlot.fromJson(v));
      });
    }
  }
}

class RegisterClub {
  String? id;
  String? clubName;
  String? ownerId;
  String? address;
  List<BusinessHour>? businessHours;
  List<String>? courtType;
  int? totalAmount;
  String? zipCode;
  String? city;
  String? logo;
  List<String>? courtImage;
  List<Location>? locations;

  RegisterClub({
    this.id,
    this.clubName,
    this.ownerId,
    this.address,
    this.businessHours,
    this.courtType,
    this.totalAmount,
    this.zipCode,
    this.city,
    this.logo,
    this.courtImage,
    this.locations,
  });

  RegisterClub.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    clubName = json['clubName'];
    ownerId = json['ownerId'];
    address = json['address'];
    courtType = json['courtType']?.cast<String>();
    totalAmount = json['totalAmount'];
    zipCode = json['zipCode'];
    city = json['city'];
    logo = json['logo'];
    courtImage = json['courtImage']?.cast<String>();

    if (json['businessHours'] != null) {
      businessHours = <BusinessHour>[];
      json['businessHours'].forEach((v) {
        businessHours!.add(BusinessHour.fromJson(v));
      });
    }

    if (json['locations'] != null) {
      locations = <Location>[];
      json['locations'].forEach((v) {
        locations!.add(Location.fromJson(v));
      });
    }
  }
}

class BusinessHour {
  String? id;
  String? day;
  String? time;

  BusinessHour({
    this.id,
    this.day,
    this.time,
  });

  BusinessHour.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    day = json['day'];
    time = json['time'];
  }
}

class Location {
  String? id;
  String? city;
  String? address;
  String? zipCode;
  String? state;
  List<String>? courtType;
  List<String>? categories;

  Location({
    this.id,
    this.city,
    this.address,
    this.zipCode,
    this.state,
    this.courtType,
    this.categories,
  });

  Location.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    city = json['city'];
    address = json['address'];
    zipCode = json['zipCode'];
    state = json['state'];
    courtType = json['courtType']?.cast<String>();
    categories = json['categories']?.cast<String>();
  }
}

class CourtSlot {
  String? id;
  String? time;
  int? amount;
  int? duration;
  String? status;
  String? bookingTime;
  int? bookingCount;
  bool? has30MinPrice;

  CourtSlot({
    this.id,
    this.time,
    this.amount,
    this.duration,
    this.status,
    this.bookingTime,
    this.bookingCount,
    this.has30MinPrice,
  });

  CourtSlot.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    time = json['time'];
    amount = json['amount'];
    duration = json['duration'];
    status = json['status'];
    bookingTime = json['bookingTime'];
    bookingCount = json['bookingCount'];
    has30MinPrice = json['has30MinPrice'];
  }
}
