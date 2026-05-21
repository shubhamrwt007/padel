class OpenMatchBookingModel {
  bool? success;
  List<OpenMatchBookingData>? data;
  int? currentPage;
  int? totalPages;
  int? totalItems;
  int? itemsPerPage;
  bool? hasNextPage;
  bool? hasPrevPage;

  OpenMatchBookingModel({
    this.success,
    this.data,
    this.currentPage,
    this.totalPages,
    this.totalItems,
    this.itemsPerPage,
    this.hasNextPage,
    this.hasPrevPage,
  });

  OpenMatchBookingModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    data = (json['data'] as List?)
        ?.map((e) => OpenMatchBookingData.fromJson(e))
        .toList();
    currentPage = json['currentPage'];
    totalPages = json['totalPages'];
    totalItems = json['totalItems'];
    itemsPerPage = json['itemsPerPage'];
    hasNextPage = json['hasNextPage'];
    hasPrevPage = json['hasPrevPage'];
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'data': data?.map((e) => e.toJson()).toList(),
        'currentPage': currentPage,
        'totalPages': totalPages,
        'totalItems': totalItems,
        'itemsPerPage': itemsPerPage,
        'hasNextPage': hasNextPage,
        'hasPrevPage': hasPrevPage,
      };
}

class OpenMatchBookingData {
  String? sId;
  ClubId? clubId;
  List<Slot>? slot;
  String? matchType;
  String? skillLevel;
  List<String>? skillDetails;
  String? customerScale;
  String? customerRacketSport;
  String? receivingTP;
  String? customerAge;
  String? volleyNetPositioning;
  String? playerLevel;
  String? reboundSkills;
  String? matchDate;
  List<String>? matchTime;
  bool? matchStatus;
  List<TeamA>? teamA;
  List<TeamB>? teamB;
  UserId? createdBy;
  String? gender;
  bool? status;
  bool? adminStatus;
  bool? isRequest;
  bool? isActive;
  bool? isDeleted;
  String? createdAt;
  String? updatedAt;
  String? startTime;
  String? endTime;
  String? openMatchStatus;
  BookingId? bookingId;
  int? iV;
  String? locationId;
  String? categoryId;
  dynamic? totalAmount;
  dynamic? yourShare;

  OpenMatchBookingData({
    this.sId,
    this.clubId,
    this.slot,
    this.matchType,
    this.skillLevel,
    this.skillDetails,
    this.customerScale,
    this.customerRacketSport,
    this.receivingTP,
    this.customerAge,
    this.volleyNetPositioning,
    this.playerLevel,
    this.reboundSkills,
    this.matchDate,
    this.matchTime,
    this.matchStatus,
    this.teamA,
    this.teamB,
    this.createdBy,
    this.gender,
    this.status,
    this.adminStatus,
    this.isRequest,
    this.isActive,
    this.isDeleted,
    this.createdAt,
    this.updatedAt,
    this.startTime,
    this.endTime,
    this.openMatchStatus,
    this.bookingId,
    this.iV,
    this.locationId,
    this.categoryId,
    this.totalAmount,
    this.yourShare,
  });

  OpenMatchBookingData.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    clubId = json['clubId'] != null ? ClubId.fromJson(json['clubId']) : null;
    slot = (json['slot'] as List?)?.map((e) => Slot.fromJson(e)).toList();
    matchType = json['matchType'];
    skillLevel = json['skillLevel'];
    skillDetails = (json['skillDetails'] as List?)?.cast<String>();
    customerScale = json['customerScale'];
    customerRacketSport = json['customerRacketSport'];
    receivingTP = json['receivingTP'];
    customerAge = json['customerAge'];
    volleyNetPositioning = json['volleyNetPositioning'];
    playerLevel = json['playerLevel'];
    reboundSkills = json['reboundSkills'];
    matchDate = json['matchDate'];
    matchTime = (json['matchTime'] as List?)?.cast<String>();
    matchStatus = json['matchStatus'];
    teamA = (json['teamA'] as List?)?.map((e) => TeamA.fromJson(e)).toList();
    teamB = (json['teamB'] as List?)?.map((e) => TeamB.fromJson(e)).toList();
    createdBy =
        json['createdBy'] != null ? UserId.fromJson(json['createdBy']) : null;
    gender = json['gender'];
    status = json['status'];
    adminStatus = json['adminStatus'];
    isRequest = json['isRequest'];
    isActive = json['isActive'];
    isDeleted = json['isDeleted'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    startTime = json['startTime'];
    endTime = json['endTime'];
    openMatchStatus = json['openMatchStatus'];
    bookingId = json['bookingId'] != null
        ? BookingId.fromJson(json['bookingId'])
        : null;

    iV = json['__v'];
    locationId = json['locationId'];
    categoryId = json['categoryId'];
    totalAmount = json['totalAmount'];
    yourShare = json['yourShare'];
  }

  Map<String, dynamic> toJson() => {
        '_id': sId,
        'clubId': clubId?.toJson(),
        'slot': slot?.map((e) => e.toJson()).toList(),
        'matchType': matchType,
        'skillLevel': skillLevel,
        'skillDetails': skillDetails,
        'customerScale': customerScale,
        'customerRacketSport': customerRacketSport,
        'receivingTP': receivingTP,
        'customerAge': customerAge,
        'volleyNetPositioning': volleyNetPositioning,
        'playerLevel': playerLevel,
        'reboundSkills': reboundSkills,
        'matchDate': matchDate,
        'matchTime': matchTime,
        'matchStatus': matchStatus,
        'teamA': teamA?.map((e) => e.toJson()).toList(),
        'teamB': teamB?.map((e) => e.toJson()).toList(),
        'createdBy': createdBy?.toJson(),
        'gender': gender,
        'status': status,
        'adminStatus': adminStatus,
        'isRequest': isRequest,
        'isActive': isActive,
        'isDeleted': isDeleted,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'startTime': startTime,
        'endTime': endTime,
        'openMatchStatus': openMatchStatus,
        'bookingId': bookingId?.toJson(),
        '__v': iV,
        'locationId': locationId,
        'categoryId': categoryId,
        'totalAmount': totalAmount,
        'yourShare': yourShare,
      };
}
class BookingId {
  String? sId;
  String? bookingStatus;
  String? bookingTime;
  String? startTime;
  String? endTime;
  dynamic? totalAmount;
  String? paymentStatus;

  BookingId.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    bookingStatus = json['bookingStatus'];
    bookingTime = json['bookingTime'];
    startTime = json['startTime'];
    endTime = json['endTime'];
    totalAmount = json['totalAmount'];
    paymentStatus = json['paymentStatus'];
  }

  Map<String, dynamic> toJson() => {
    '_id': sId,
    'bookingStatus': bookingStatus,
    'bookingTime': bookingTime,
    'startTime': startTime,
    'endTime': endTime,
    'totalAmount': totalAmount,
    'paymentStatus': paymentStatus,
  };
}

class ClubId {
  Location? location;
  String? sId;
  String? ownerId;
  String? clubName;
  int? iV;
  String? address;
  List<BusinessHours>? businessHours;
  String? city;
  int? courtCount;
  List<String>? courtImage;
  List<String>? courtName;
  List<String>? courtType;
  String? createdAt;
  List<String>? features;
  bool? isActive;
  bool? isDeleted;
  bool? isFeatured;
  bool? isVerified;
  String? state;
  String? updatedAt;
  String? zipCode;
  String? description;
  List<ClubLocation>? locations;

  ClubId.fromJson(Map<String, dynamic> json) {
    location =
        json['location'] != null ? Location.fromJson(json['location']) : null;
    sId = json['_id'];
    ownerId = json['ownerId'];
    clubName = json['clubName'];
    iV = json['__v'];
    address = json['address'];

    businessHours = (json['businessHours'] as List?)
        ?.map((e) => BusinessHours.fromJson(e))
        .toList();

    city = json['city'];
    courtCount = json['courtCount'];
    courtImage = (json['courtImage'] as List?)?.cast<String>();
    courtName = (json['courtName'] as List?)?.cast<String>();
    courtType = (json['courtType'] as List?)?.cast<String>();
    createdAt = json['createdAt'];
    features = (json['features'] as List?)?.cast<String>();
    isActive = json['isActive'];
    isDeleted = json['isDeleted'];
    isFeatured = json['isFeatured'];
    isVerified = json['isVerified'];
    state = json['state'];
    updatedAt = json['updatedAt'];
    zipCode = json['zipCode'];
    description = json['description'];
    locations = (json['locations'] as List?)
        ?.map((e) => ClubLocation.fromJson(e))
        .toList();
  }

  Map<String, dynamic> toJson() => {
        'location': location?.toJson(),
        '_id': sId,
        'ownerId': ownerId,
        'clubName': clubName,
        '__v': iV,
        'address': address,
        'businessHours': businessHours?.map((e) => e.toJson()).toList(),
        'city': city,
        'courtCount': courtCount,
        'courtImage': courtImage,
        'courtName': courtName,
        'courtType': courtType,
        'createdAt': createdAt,
        'features': features,
        'isActive': isActive,
        'isDeleted': isDeleted,
        'isFeatured': isFeatured,
        'isVerified': isVerified,
        'state': state,
        'updatedAt': updatedAt,
        'zipCode': zipCode,
        'description': description,
        'locations': locations?.map((e) => e.toJson()).toList(),
      };
}

class Location {
  String? type;
  List<double>? coordinates;

  Location({this.type, this.coordinates});

  Location.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    coordinates = (json['coordinates'] as List?)
        ?.map((e) => (e as num).toDouble())
        .toList();
  }
  Map<String, dynamic> toJson() => {
        'type': type,
        'coordinates': coordinates,
      };
}
class BusinessHours {
  String? time;
  String? day;
  String? sId;

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

class Slot {
  String? slotId;
  String? courtName;
  String? courtId;
  List<SlotTimes>? slotTimes;

  Slot.fromJson(Map<String, dynamic> json) {
    slotId = json['slotId'];
    courtName = json['courtName'];
    courtId = json['courtId'];
    slotTimes = (json['slotTimes'] as List?)
        ?.map((e) => SlotTimes.fromJson(e))
        .toList();
  }

  Map<String, dynamic> toJson() => {
        'slotId': slotId,
        'courtName': courtName,
        'courtId': courtId,
        'slotTimes': slotTimes?.map((e) => e.toJson()).toList(),
      };
}

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

  Map<String, dynamic> toJson() => {
        'time': time,
        'amount': amount,
        'status': status,
        'availabilityStatus': availabilityStatus,
      };
}

class TeamA {
  UserId? userId;
  String? joinedAt;
  String? sId;
  bool? isTemp;
  String? name;
  String? tempPlayerId;
  String? addedBy;
  dynamic? amountPaid;
  bool? paidStatus;

  TeamA({
    this.userId,
    this.joinedAt,
    this.sId,
    this.isTemp,
    this.name,
    this.tempPlayerId,
    this.addedBy,
    this.amountPaid,
    this.paidStatus,
  });

  TeamA.fromJson(Map<String, dynamic> json) {
    userId =
        json['userId'] != null ? UserId.fromJson(json['userId']) : null;
    joinedAt = json['joinedAt'];
    sId = json['_id'];
    isTemp = json['isTemp'];
    name = json['name'];
    tempPlayerId = json['tempPlayerId'];
    addedBy = json['addedBy'];
    amountPaid = json['amountPaid'];
    paidStatus = json['paidStatus'];
  }

  Map<String, dynamic> toJson() => {
        'userId': userId?.toJson(),
        'joinedAt': joinedAt,
        '_id': sId,
        'isTemp': isTemp,
        'name': name,
        'tempPlayerId': tempPlayerId,
        'addedBy': addedBy,
        'amountPaid': amountPaid,
        'paidStatus': paidStatus,
      };
}

class TeamB {
  UserId? userId;
  String? joinedAt;
  String? sId;
  bool? isTemp;
  String? name;
  String? tempPlayerId;
  String? addedBy;
  dynamic? amountPaid;
  bool? paidStatus;

  TeamB({
    this.userId,
    this.joinedAt,
    this.sId,
    this.isTemp,
    this.name,
    this.tempPlayerId,
    this.addedBy,
    this.amountPaid,
    this.paidStatus,
  });

  TeamB.fromJson(Map<String, dynamic> json) {
    userId =
        json['userId'] != null ? UserId.fromJson(json['userId']) : null;
    joinedAt = json['joinedAt'];
    sId = json['_id'];
    isTemp = json['isTemp'];
    name = json['name'];
    tempPlayerId = json['tempPlayerId'];
    addedBy = json['addedBy'];
    amountPaid = json['amountPaid'];
    paidStatus = json['paidStatus'];
  }

  Map<String, dynamic> toJson() => {
        'userId': userId?.toJson(),
        'joinedAt': joinedAt,
        '_id': sId,
        'isTemp': isTemp,
        'name': name,
        'tempPlayerId': tempPlayerId,
        'addedBy': addedBy,
        'amountPaid': amountPaid,
        'paidStatus': paidStatus,
      };
}

class UserId {
  Location? location;
  String? sId;
  String? email;
  String? countryCode;
  int? phoneNumber;
  dynamic? xpPoints;
  String? name;
  String? lastName;
  String? gender;
  String? category;
  bool? isActive;
  bool? isDeleted;
  String? role;
  List<String>? fcmTokens;
  String? playerLevel;
  String? level;

  String? profilePic;
  String? createdAt;
  String? updatedAt;
  int? iV;

  UserId.fromJson(Map<String, dynamic> json) {
    location =
        json['location'] != null ? Location.fromJson(json['location']) : null;
    sId = json['_id'];
    email = json['email'];
    countryCode = json['countryCode'];
    phoneNumber = json['phoneNumber'];
    name = json['name'];
    lastName = json['lastName'];
    gender = json['gender'];
    category = json['category'];
    isActive = json['isActive'];
    isDeleted = json['isDeleted'];
    role = json['role'];
    fcmTokens = (json['fcmTokens'] as List?)?.cast<String>();
    playerLevel = json['playerLevel'];
    level = json['level'];
    profilePic = json['profilePic'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    xpPoints = json['xpPoints'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() => {
        'location': location?.toJson(),
        '_id': sId,
        'email': email,
        'countryCode': countryCode,
        'phoneNumber': phoneNumber,
        'name': name,
        'lastName': lastName,
        'gender': gender,
        'category': category,
        'isActive': isActive,
        'isDeleted': isDeleted,
        'role': role,
        'fcmTokens': fcmTokens,
        'playerLevel': playerLevel,
        'level': level,
        'profilePic': profilePic,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'xpPoints': xpPoints,
        '__v': iV,
      };
}

class ClubLocation {
  String? sId;
  String? city;
  String? address;
  String? zipCode;
  String? state;
  List<String>? courtType;
  List<String>? categories;

  ClubLocation.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    city = json['city'];
    address = json['address'];
    zipCode = json['zipCode'];
    state = json['state'];
    courtType = (json['courtType'] as List?)?.cast<String>();
    categories = (json['categories'] as List?)?.cast<String>();
  }

  Map<String, dynamic> toJson() => {
        '_id': sId,
        'city': city,
        'address': address,
        'zipCode': zipCode,
        'state': state,
        'courtType': courtType,
        'categories': categories,
      };
}
