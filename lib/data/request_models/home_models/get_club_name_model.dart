class CourtsModel {
  bool? success;
  String? message;
  Data? data;

  CourtsModel({this.success, this.message, this.data});

  CourtsModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    data['message'] = this.message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  List<Courts>? courts;
  int? currentPage;
  int? totalPages;
  int? totalItems;
  int? itemsPerPage;

  Data(
      {this.courts,
        this.currentPage,
        this.totalPages,
        this.totalItems,
        this.itemsPerPage});

  Data.fromJson(Map<String, dynamic> json) {
    if (json['courts'] != null) {
      courts = <Courts>[];
      json['courts'].forEach((v) {
        courts!.add(new Courts.fromJson(v));
      });
    }
    currentPage = json['currentPage'];
    totalPages = json['totalPages'];
    totalItems = json['totalItems'];
    itemsPerPage = json['itemsPerPage'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.courts != null) {
      data['courts'] = this.courts!.map((v) => v.toJson()).toList();
    }
    data['currentPage'] = this.currentPage;
    data['totalPages'] = this.totalPages;
    data['totalItems'] = this.totalItems;
    data['itemsPerPage'] = this.itemsPerPage;
    return data;
  }
}

class Courts {
  String? id;
  String? ownerId;
  String? clubName;
  int? iV;
  String? address;
  List<BusinessHours>? businessHours;
  String? city;
  int? courtCount;
  List<String>? courtImage;
  List<String>? courtType;
  String? createdAt;
  String? description;
  String? facebookLink;
  List<String>? features;
  String? instagramLink;
  bool? isActive;
  bool? isDeleted;
  bool? isFeatured;
  bool? isVerified;
  String? linkedinLink;
  Location? location;
  String? logo;
  String? state;
  String? updatedAt;
  String? xlink;
  String? zipCode;
  List<dynamic>? courtName;
  List<CourtDetails>? courts;
  List<dynamic>? categories;
  List<Prices>? prices;
  int? totalAmount;
  List<LocationDetails>? locations;

  Courts(
      {this.id,
        this.ownerId,
        this.clubName,
        this.iV,
        this.address,
        this.businessHours,
        this.city,
        this.courtCount,
        this.courtImage,
        this.courtType,
        this.createdAt,
        this.description,
        this.facebookLink,
        this.features,
        this.instagramLink,
        this.isActive,
        this.isDeleted,
        this.isFeatured,
        this.isVerified,
        this.linkedinLink,
        this.location,
        this.logo,
        this.state,
        this.updatedAt,
        this.xlink,
        this.zipCode,
        this.courtName,
        this.courts,
        this.categories,
        this.prices,
        this.totalAmount,
        this.locations});

  Courts.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    ownerId = json['ownerId'];
    clubName = json['clubName'];
    iV = json['__v'];
    address = json['address'];
    if (json['businessHours'] != null) {
      businessHours = <BusinessHours>[];
      json['businessHours'].forEach((v) {
        businessHours!.add(new BusinessHours.fromJson(v));
      });
    }
    city = json['city'];
    courtCount = json['courtCount'];
    courtImage = json['courtImage'] != null ? List<String>.from(json['courtImage']) : null;
    courtType = json['courtType'] != null ? List<String>.from(json['courtType']) : null;
    createdAt = json['createdAt'];
    description = json['description'];
    facebookLink = json['facebookLink'];
    features = json['features'] != null ? List<String>.from(json['features']) : null;
    instagramLink = json['instagramLink'];
    isActive = json['isActive'];
    isDeleted = json['isDeleted'];
    isFeatured = json['isFeatured'];
    isVerified = json['isVerified'];
    linkedinLink = json['linkedinLink'];
    location = json['location'] != null
        ? new Location.fromJson(json['location'])
        : null;
    logo = json['logo'];
    state = json['state'];
    updatedAt = json['updatedAt'];
    xlink = json['xlink'];
    zipCode = json['zipCode'];
    courtName = json['courtName'];
    if (json['courts'] != null) {
      courts = <CourtDetails>[];
      json['courts'].forEach((v) {
        courts!.add(new CourtDetails.fromJson(v));
      });
    }
    categories = json['categories'];
    if (json['prices'] != null) {
      prices = <Prices>[];
      json['prices'].forEach((v) {
        prices!.add(new Prices.fromJson(v));
      });
    }
    totalAmount = json['totalAmount'];
    if (json['locations'] != null) {
      locations = <LocationDetails>[];
      json['locations'].forEach((v) {
        locations!.add(new LocationDetails.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.id;
    data['ownerId'] = this.ownerId;
    data['clubName'] = this.clubName;
    data['__v'] = this.iV;
    data['address'] = this.address;
    if (this.businessHours != null) {
      data['businessHours'] =
          this.businessHours!.map((v) => v.toJson()).toList();
    }
    data['city'] = this.city;
    data['courtCount'] = this.courtCount;
    data['courtImage'] = this.courtImage;
    data['courtType'] = this.courtType;
    data['createdAt'] = this.createdAt;
    data['description'] = this.description;
    data['facebookLink'] = this.facebookLink;
    data['features'] = this.features;
    data['instagramLink'] = this.instagramLink;
    data['isActive'] = this.isActive;
    data['isDeleted'] = this.isDeleted;
    data['isFeatured'] = this.isFeatured;
    data['isVerified'] = this.isVerified;
    data['linkedinLink'] = this.linkedinLink;
    if (this.location != null) {
      data['location'] = this.location!.toJson();
    }
    data['logo'] = this.logo;
    data['state'] = this.state;
    data['updatedAt'] = this.updatedAt;
    data['xlink'] = this.xlink;
    data['zipCode'] = this.zipCode;
    if (this.courtName != null) {
      data['courtName'] = this.courtName!.map((v) => v.toJson()).toList();
    }
    if (this.courts != null) {
      data['courts'] = this.courts!.map((v) => v.toJson()).toList();
    }
    if (this.categories != null) {
      data['categories'] = this.categories!.map((v) => v.toJson()).toList();
    }
    if (this.prices != null) {
      data['prices'] = this.prices!.map((v) => v.toJson()).toList();
    }
    data['totalAmount'] = this.totalAmount;
    if (this.locations != null) {
      data['locations'] = this.locations!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class LocationDetails {
  String? id;
  String? city;
  String? address;
  String? zipCode;
  String? state;
  List<String>? courtType;
  List<String>? categories;

  LocationDetails(
      {this.id,
        this.city,
        this.address,
        this.zipCode,
        this.state,
        this.courtType,
        this.categories});

  LocationDetails.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    city = json['city'];
    address = json['address'];
    zipCode = json['zipCode'];
    state = json['state'];
    courtType = json['courtType'] != null ? List<String>.from(json['courtType']) : null;
    categories = json['categories'] != null ? List<String>.from(json['categories']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.id;
    data['city'] = this.city;
    data['address'] = this.address;
    data['zipCode'] = this.zipCode;
    data['state'] = this.state;
    data['courtType'] = this.courtType;
    data['categories'] = this.categories;
    return data;
  }
}

class BusinessHours {
  String? time;
  String? day;
  String? id;

  BusinessHours({this.time, this.day, this.id});

  BusinessHours.fromJson(Map<String, dynamic> json) {
    time = json['time'];
    day = json['day'];
    id = json['_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['time'] = this.time;
    data['day'] = this.day;
    data['_id'] = this.id;
    return data;
  }
}

class Location {
  String? type;
  List<double>? coordinates;

  Location({this.type, this.coordinates});

  Location.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    coordinates = json['coordinates'] != null ? List<double>.from(json['coordinates']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['type'] = this.type;
    data['coordinates'] = this.coordinates;
    return data;
  }
}

class CourtDetails {
  String? id;
  String? registerClubId;
  int? iV;
  List<Court>? court;
  String? createdAt;
  String? ownerId;
  List<Slot>? slot;
  String? updatedAt;
  List<String>? courtImage;
  int? courtCount;
  String? description;
  List<String>? features;

  CourtDetails(
      {this.id,
        this.registerClubId,
        this.iV,
        this.court,
        this.createdAt,
        this.ownerId,
        this.slot,
        this.updatedAt,
        this.courtImage,
        this.courtCount,
        this.description,
        this.features});

  CourtDetails.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    registerClubId = json['register_club_id'];
    iV = json['__v'];
    if (json['court'] != null) {
      court = <Court>[];
      json['court'].forEach((v) {
        court!.add(new Court.fromJson(v));
      });
    }
    createdAt = json['createdAt'];
    ownerId = json['ownerId'];
    if (json['slot'] != null) {
      slot = <Slot>[];
      json['slot'].forEach((v) {
        slot!.add(new Slot.fromJson(v));
      });
    }
    updatedAt = json['updatedAt'];
    courtImage = json['courtImage'] != null ? List<String>.from(json['courtImage']) : null;
    courtCount = json['courtCount'];
    description = json['description'];
    features = json['features'] != null ? List<String>.from(json['features']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.id;
    data['register_club_id'] = this.registerClubId;
    data['__v'] = this.iV;
    if (this.court != null) {
      data['court'] = this.court!.map((v) => v.toJson()).toList();
    }
    data['createdAt'] = this.createdAt;
    data['ownerId'] = this.ownerId;
    if (this.slot != null) {
      data['slot'] = this.slot!.map((v) => v.toJson()).toList();
    }
    data['updatedAt'] = this.updatedAt;
    data['courtImage'] = this.courtImage;
    data['courtCount'] = this.courtCount;
    data['description'] = this.description;
    data['features'] = this.features;
    return data;
  }
}

class Court {
  String? courtName;
  String? id;

  Court({this.courtName, this.id});

  Court.fromJson(Map<String, dynamic> json) {
    courtName = json['courtName'];
    id = json['_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['courtName'] = this.courtName;
    data['_id'] = this.id;
    return data;
  }
}

class Slot {
  List<BusinessHours>? businessHours;
  List<SlotTimes>? slotTimes;
  String? id;

  Slot({this.businessHours, this.slotTimes, this.id});

  Slot.fromJson(Map<String, dynamic> json) {
    if (json['businessHours'] != null) {
      businessHours = <BusinessHours>[];
      json['businessHours'].forEach((v) {
        businessHours!.add(new BusinessHours.fromJson(v));
      });
    }
    if (json['slotTimes'] != null) {
      slotTimes = <SlotTimes>[];
      json['slotTimes'].forEach((v) {
        slotTimes!.add(new SlotTimes.fromJson(v));
      });
    }
    id = json['_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.businessHours != null) {
      data['businessHours'] =
          this.businessHours!.map((v) => v.toJson()).toList();
    }
    if (this.slotTimes != null) {
      data['slotTimes'] = this.slotTimes!.map((v) => v.toJson()).toList();
    }
    data['_id'] = this.id;
    return data;
  }
}

class SlotTimes {
  String? status;
  String? time;
  int? amount;
  String? availabilityStatus;
  List<dynamic>? courtIds;
  String? date;
  String? id;

  SlotTimes(
      {this.status,
        this.time,
        this.amount,
        this.availabilityStatus,
        this.courtIds,
        this.date,
        this.id});

  SlotTimes.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    time = json['time'];
    amount = json['amount'];
    availabilityStatus = json['availabilityStatus'];
    courtIds = json['courtIds'];
    date = json['date'];
    id = json['_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['time'] = this.time;
    data['amount'] = this.amount;
    data['availabilityStatus'] = this.availabilityStatus;
    if (this.courtIds != null) {
      data['courtIds'] = this.courtIds!.map((v) => v.toJson()).toList();
    }
    data['date'] = this.date;
    data['_id'] = this.id;
    return data;
  }
}

class Prices {
  String? id;
  int? duration;
  String? day;
  int? price;
  String? slotTime;
  String? timePeriod;
  String? registerClubId;
  String? createdAt;
  String? updatedAt;
  int? iV;

  Prices(
      {this.id,
        this.duration,
        this.day,
        this.price,
        this.slotTime,
        this.timePeriod,
        this.registerClubId,
        this.createdAt,
        this.updatedAt,
        this.iV});

  Prices.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    duration = json['duration'];
    day = json['day'];
    price = json['price'];
    slotTime = json['slotTime'];
    timePeriod = json['timePeriod'];
    registerClubId = json['register_club_id'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.id;
    data['duration'] = this.duration;
    data['day'] = this.day;
    data['price'] = this.price;
    data['slotTime'] = this.slotTime;
    data['timePeriod'] = this.timePeriod;
    data['register_club_id'] = this.registerClubId;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    return data;
  }
}
