class RemovePlayerModel {
  String? message;
  Match? match;

  RemovePlayerModel({this.message, this.match});

  RemovePlayerModel.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    match = json['match'] != null ? new Match.fromJson(json['match']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['message'] = this.message;
    if (this.match != null) {
      data['match'] = this.match!.toJson();
    }
    return data;
  }
}

class Match {
  String? sId;
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
  List<String>? playerIds;
  int? duration;
  int? totalTime;
  String? bookingTime;
  String? matchType;
  bool? matchStatus;
  int? walletAmountUsed;
  int? razorpayAmountUsed;
  String? paymentMethod;
  String? paymentStatus;
  List<TeamA>? teamA;
  List<TeamB>? teamB;
  int? iV;

  Match(
      {this.sId,
        this.userId,
        this.registerClubId,
        this.totalAmount,
        this.bookingDate,
        this.bookingStatus,
        this.bookingType,
        this.slot,
        this.createdAt,
        this.ownerId,
        this.updatedAt,
        this.playerIds,
        this.duration,
        this.totalTime,
        this.bookingTime,
        this.matchType,
        this.matchStatus,
        this.walletAmountUsed,
        this.razorpayAmountUsed,
        this.paymentMethod,
        this.paymentStatus,
        this.teamA,
        this.teamB,
        this.iV});

  Match.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    userId = json['userId'];
    registerClubId = json['register_club_id'];
    totalAmount = json['totalAmount'];
    bookingDate = json['bookingDate'];
    bookingStatus = json['bookingStatus'];
    bookingType = json['bookingType'];
    if (json['slot'] != null) {
      slot = <Slot>[];
      json['slot'].forEach((v) {
        slot!.add(new Slot.fromJson(v));
      });
    }
    createdAt = json['createdAt'];
    ownerId = json['ownerId'];
    updatedAt = json['updatedAt'];
    playerIds = json['playerIds'].cast<String>();
    duration = json['duration'];
    totalTime = json['totalTime'];
    bookingTime = json['bookingTime'];
    matchType = json['matchType'];
    matchStatus = json['matchStatus'];
    walletAmountUsed = json['walletAmountUsed'];
    razorpayAmountUsed = json['razorpayAmountUsed'];
    paymentMethod = json['paymentMethod'];
    paymentStatus = json['paymentStatus'];
    if (json['teamA'] != null) {
      teamA = <TeamA>[];
      json['teamA'].forEach((v) {
        teamA!.add(new TeamA.fromJson(v));
      });
    }
    if (json['teamB'] != null) {
      teamB = <TeamB>[];
      json['teamB'].forEach((v) {
        teamB!.add(new TeamB.fromJson(v));
      });
    }
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['userId'] = this.userId;
    data['register_club_id'] = this.registerClubId;
    data['totalAmount'] = this.totalAmount;
    data['bookingDate'] = this.bookingDate;
    data['bookingStatus'] = this.bookingStatus;
    data['bookingType'] = this.bookingType;
    if (this.slot != null) {
      data['slot'] = this.slot!.map((v) => v.toJson()).toList();
    }
    data['createdAt'] = this.createdAt;
    data['ownerId'] = this.ownerId;
    data['updatedAt'] = this.updatedAt;
    data['playerIds'] = this.playerIds;
    data['duration'] = this.duration;
    data['totalTime'] = this.totalTime;
    data['bookingTime'] = this.bookingTime;
    data['matchType'] = this.matchType;
    data['matchStatus'] = this.matchStatus;
    data['walletAmountUsed'] = this.walletAmountUsed;
    data['razorpayAmountUsed'] = this.razorpayAmountUsed;
    data['paymentMethod'] = this.paymentMethod;
    data['paymentStatus'] = this.paymentStatus;
    if (this.teamA != null) {
      data['teamA'] = this.teamA!.map((v) => v.toJson()).toList();
    }
    if (this.teamB != null) {
      data['teamB'] = this.teamB!.map((v) => v.toJson()).toList();
    }
    data['__v'] = this.iV;
    return data;
  }
}

class Slot {
  String? slotId;
  String? courtName;
  String? courtId;
  String? bookingDate;
  List<SlotTimes>? slotTimes;
  List<dynamic>? businessHours;

  Slot(
      {this.slotId,
        this.courtName,
        this.courtId,
        this.bookingDate,
        this.slotTimes,
        this.businessHours});

  Slot.fromJson(Map<String, dynamic> json) {
    slotId = json['slotId'];
    courtName = json['courtName'];
    courtId = json['courtId'];
    bookingDate = json['bookingDate'];
    if (json['slotTimes'] != null) {
      slotTimes = <SlotTimes>[];
      json['slotTimes'].forEach((v) {
        slotTimes!.add(new SlotTimes.fromJson(v));
      });
    }
    if (json['businessHours'] != null) {
      businessHours = <dynamic>[];
      json['businessHours'].forEach((v) {
        businessHours!.add(v);
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['slotId'] = this.slotId;
    data['courtName'] = this.courtName;
    data['courtId'] = this.courtId;
    data['bookingDate'] = this.bookingDate;
    if (this.slotTimes != null) {
      data['slotTimes'] = this.slotTimes!.map((v) => v.toJson()).toList();
    }
    if (this.businessHours != null) {
      data['businessHours'] = this.businessHours;
    }
    return data;
  }
}

class SlotTimes {
  String? time;
  int? amount;
  String? status;
  String? availabilityStatus;

  SlotTimes({this.time, this.amount, this.status, this.availabilityStatus});

  SlotTimes.fromJson(Map<String, dynamic> json) {
    time = json['time'];
    amount = json['amount'];
    status = json['status'];
    availabilityStatus = json['availabilityStatus'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['time'] = this.time;
    data['amount'] = this.amount;
    data['status'] = this.status;
    data['availabilityStatus'] = this.availabilityStatus;
    return data;
  }
}

class TeamA {
  String? userId;
  String? joinedAt;
  String? sId;

  TeamA({this.userId, this.joinedAt, this.sId});

  TeamA.fromJson(Map<String, dynamic> json) {
    userId = json['userId'];
    joinedAt = json['joinedAt'];
    sId = json['_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['userId'] = this.userId;
    data['joinedAt'] = this.joinedAt;
    data['_id'] = this.sId;
    return data;
  }
}

class TeamB {
  String? userId;
  String? joinedAt;
  String? sId;

  TeamB({this.userId, this.joinedAt, this.sId});

  TeamB.fromJson(Map<String, dynamic> json) {
    userId = json['userId'];
    joinedAt = json['joinedAt'];
    sId = json['_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['userId'] = this.userId;
    data['joinedAt'] = this.joinedAt;
    data['_id'] = this.sId;
    return data;
  }
}