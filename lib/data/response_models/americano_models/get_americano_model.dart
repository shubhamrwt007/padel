class GetAmericanoModel {
  bool? success;
  String? message;
  AmericanoData? data;
  PaginationInfo? pagination;

  GetAmericanoModel({
    this.success,
    this.message,
    this.data,
    this.pagination,
  });

  GetAmericanoModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    
    if (json['data'] != null && json['data'] is Map<String, dynamic>) {
      data = AmericanoData.fromJson(json['data']);
    }
    
    if (json['pagination'] != null && json['pagination'] is Map<String, dynamic>) {
      pagination = PaginationInfo.fromJson(json['pagination']);
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = {};
    map['success'] = success;
    map['message'] = message;
    if (data != null) {
      map['data'] = data!.toJson();
    }
    if (pagination != null) {
      map['pagination'] = pagination!.toJson();
    }
    return map;
  }
}

class AmericanoData {
  List<AmericanoMatch>? upcomingAmericanos;
  List<AmericanoMatch>? ongoingAmericanos;
  List<AmericanoMatch>? completedAmericanos;

  AmericanoData({
    this.upcomingAmericanos,
    this.ongoingAmericanos,
    this.completedAmericanos,
  });

  AmericanoData.fromJson(Map<String, dynamic> json) {
    if (json['upcomingAmericanos'] != null && json['upcomingAmericanos'] is List) {
      upcomingAmericanos = <AmericanoMatch>[];
      for (var v in json['upcomingAmericanos']) {
        upcomingAmericanos!.add(AmericanoMatch.fromJson(v));
      }
    }
    if (json['ongoingAmericanos'] != null && json['ongoingAmericanos'] is List) {
      ongoingAmericanos = <AmericanoMatch>[];
      for (var v in json['ongoingAmericanos']) {
        ongoingAmericanos!.add(AmericanoMatch.fromJson(v));
      }
    }
    if (json['completedAmericanos'] != null && json['completedAmericanos'] is List) {
      completedAmericanos = <AmericanoMatch>[];
      for (var v in json['completedAmericanos']) {
        completedAmericanos!.add(AmericanoMatch.fromJson(v));
      }
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'upcomingAmericanos': upcomingAmericanos?.map((e) => e.toJson()).toList(),
      'ongoingAmericanos': ongoingAmericanos?.map((e) => e.toJson()).toList(),
      'completedAmericanos': completedAmericanos?.map((e) => e.toJson()).toList(),
    };
  }
}

class PaginationInfo {
  int? total;
  int? page;
  int? limit;
  int? totalPages;

  PaginationInfo({this.total, this.page, this.limit, this.totalPages});

  PaginationInfo.fromJson(Map<String, dynamic> json) {
    total = json['total'];
    page = json['page'];
    limit = json['limit'];
    totalPages = json['totalPages'] ?? json['total_pages'];
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'page': page,
      'limit': limit,
      'totalPages': totalPages,
    };
  }
}

class AmericanoMatch {
  String? sId;
  ClubInfo? clubId;
  String? matchTitle;
  String? matchDescription;
  String? skillLevel;
  String? americanoFormat;
  String? gender;
  int? maxPlayers;
  int? maxTeams;
  int? maxPoints;
  int? courtCount;
  int? registrationFee;
  int? totalPrice;
  String? matchDate;
  String? matchEndDate;
  String? matchTime;
  String? matchDay;
  String? registrationLastDate;
  String? matchStatus;
  int? joinedMembers;
  bool? isActive;
  bool? isDeleted;
  bool? isRegistered;
  bool? isJoined;
  List<AmericanoPlayer>? players;
  Map<String, dynamic>? prize;

  String get formattedMatchDate {
    if (matchDate == null || matchDate!.isEmpty) return 'Date';
    try {
      final datePart = matchDate!.contains('T') ? matchDate!.split('T').first : matchDate!;
      final parts = datePart.split('-');
      if (parts.length == 3) {
        final day = int.tryParse(parts[2]) ?? 0;
        final months = [
          'January', 'February', 'March', 'April', 'May', 'June',
          'July', 'August', 'September', 'October', 'November', 'December'
        ];
        final monthIndex = (int.tryParse(parts[1]) ?? 1) - 1;
        if (monthIndex >= 0 && monthIndex < 12) {
          return "$day ${months[monthIndex]}";
        }
      }
      return datePart;
    } catch (_) {
      return matchDate ?? 'Date';
    }
  }

  AmericanoMatch({
    this.sId,
    this.clubId,
    this.matchTitle,
    this.matchDescription,
    this.skillLevel,
    this.americanoFormat,
    this.gender,
    this.maxPlayers,
    this.maxTeams,
    this.maxPoints,
    this.courtCount,
    this.registrationFee,
    this.totalPrice,
    this.matchDate,
    this.matchEndDate,
    this.matchTime,
    this.matchDay,
    this.registrationLastDate,
    this.matchStatus,
    this.joinedMembers,
    this.isActive,
    this.isDeleted,
    this.isRegistered,
    this.isJoined,
    this.players,
    this.prize,
  });

  List<String> get joinedPlayersAvatars {
    if (players == null) return [];
    return players!
        .map((p) => p.registerUserId?.profilePic)
        .whereType<String>()
        .where((pic) => pic.isNotEmpty)
        .toList();
  }

  AmericanoMatch.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    if (json['clubId'] != null && json['clubId'] is Map<String, dynamic>) {
      clubId = ClubInfo.fromJson(json['clubId']);
    }
    matchTitle = json['matchTitle']?.toString();
    matchDescription = json['matchDescription']?.toString();
    skillLevel = json['skillLevel']?.toString();
    americanoFormat = json['americanoFormat']?.toString();
    gender = json['gender']?.toString();
    maxPlayers = json['maxPlayers'] is int ? json['maxPlayers'] : int.tryParse(json['maxPlayers']?.toString() ?? '');
    maxTeams = json['maxTeams'] is int ? json['maxTeams'] : int.tryParse(json['maxTeams']?.toString() ?? '');
    maxPoints = json['maxPoints'] is int ? json['maxPoints'] : int.tryParse(json['maxPoints']?.toString() ?? '');
    courtCount = json['courtCount'] is int ? json['courtCount'] : int.tryParse(json['courtCount']?.toString() ?? '');
    registrationFee = json['registrationFee'] is int ? json['registrationFee'] : int.tryParse(json['registrationFee']?.toString() ?? '');
    totalPrice = json['totalPrice'] is int ? json['totalPrice'] : int.tryParse(json['totalPrice']?.toString() ?? '');
    matchDate = json['matchDate']?.toString();
    matchEndDate = json['matchEndDate']?.toString();
    matchTime = json['matchTime']?.toString();
    matchDay = json['matchDay']?.toString();
    registrationLastDate = json['registrationLastDate']?.toString();
    matchStatus = json['matchStatus']?.toString();
    joinedMembers = json['joinedMembers'] is int ? json['joinedMembers'] : int.tryParse(json['joinedMembers']?.toString() ?? '');
    isActive = json['isActive'];
    isDeleted = json['isDeleted'];
    isRegistered = json['isRegistered'];
    isJoined = json['isJoined'];

    if (json['players'] != null && json['players'] is List) {
      players = <AmericanoPlayer>[];
      for (var v in json['players']) {
        if (v is Map<String, dynamic>) {
          players!.add(AmericanoPlayer.fromJson(v));
        }
      }
    }
    
    if (json['prize'] != null && json['prize'] is Map<String, dynamic>) {
      prize = Map<String, dynamic>.from(json['prize']);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': sId,
      if (clubId != null) 'clubId': clubId!.toJson(),
      'matchTitle': matchTitle,
      'matchDescription': matchDescription,
      'skillLevel': skillLevel,
      'americanoFormat': americanoFormat,
      'gender': gender,
      'maxPlayers': maxPlayers,
      'maxTeams': maxTeams,
      'maxPoints': maxPoints,
      'courtCount': courtCount,
      'registrationFee': registrationFee,
      'totalPrice': totalPrice,
      'matchDate': matchDate,
      'matchEndDate': matchEndDate,
      'matchTime': matchTime,
      'matchDay': matchDay,
      'registrationLastDate': registrationLastDate,
      'matchStatus': matchStatus,
      'joinedMembers': joinedMembers,
      'isActive': isActive,
      'isDeleted': isDeleted,
      'isRegistered': isRegistered,
      'isJoined': isJoined,
      if (players != null) 'players': players!.map((e) => e.toJson()).toList(),
      if (prize != null) 'prize': prize,
    };
  }
}

class ClubInfo {
  String? sId;
  String? clubName;
  String? logo;
  List<ClubLocation>? locations;

  ClubInfo({this.sId, this.clubName, this.logo, this.locations});

  ClubInfo.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    clubName = json['clubName']?.toString();
    logo = json['logo']?.toString();
    if (json['locations'] != null && json['locations'] is List) {
      locations = <ClubLocation>[];
      for (var v in json['locations']) {
        if (v is Map<String, dynamic>) {
          locations!.add(ClubLocation.fromJson(v));
        }
      }
    }
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': sId,
      'clubName': clubName,
      'logo': logo,
      if (locations != null) 'locations': locations!.map((e) => e.toJson()).toList(),
    };
  }
}

class ClubLocation {
  String? city;
  String? address;
  String? zipCode;
  String? state;

  ClubLocation({this.city, this.address, this.zipCode, this.state});

  ClubLocation.fromJson(Map<String, dynamic> json) {
    city = json['city']?.toString();
    address = json['address']?.toString();
    zipCode = json['zipCode']?.toString();
    state = json['state']?.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'city': city,
      'address': address,
      'zipCode': zipCode,
      'state': state,
    };
  }
}

class AmericanoPlayer {
  String? sId;
  String? americanoMatchId;
  String? fullName;
  String? email;
  String? phoneNumber;
  String? gender;
  String? playerLevel;
  int? totalPoints;
  int? pointsAgainst;
  int? pointDifference;
  int? wins;
  int? draws;
  int? losses;
  int? matchesPlayed;
  bool? isActive;
  bool? isDeleted;
  RegisterUser? registerUserId;

  AmericanoPlayer({
    this.sId,
    this.americanoMatchId,
    this.fullName,
    this.email,
    this.phoneNumber,
    this.gender,
    this.playerLevel,
    this.totalPoints,
    this.pointsAgainst,
    this.pointDifference,
    this.wins,
    this.draws,
    this.losses,
    this.matchesPlayed,
    this.isActive,
    this.isDeleted,
    this.registerUserId,
  });

  AmericanoPlayer.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    americanoMatchId = json['americanoMatchId']?.toString();
    fullName = json['fullName']?.toString();
    email = json['email']?.toString();
    phoneNumber = json['phoneNumber']?.toString();
    gender = json['gender']?.toString();
    playerLevel = json['playerLevel']?.toString();
    totalPoints = json['totalPoints'] is int ? json['totalPoints'] : int.tryParse(json['totalPoints']?.toString() ?? '');
    pointsAgainst = json['pointsAgainst'] is int ? json['pointsAgainst'] : int.tryParse(json['pointsAgainst']?.toString() ?? '');
    pointDifference = json['pointDifference'] is int ? json['pointDifference'] : int.tryParse(json['pointDifference']?.toString() ?? '');
    wins = json['wins'] is int ? json['wins'] : int.tryParse(json['wins']?.toString() ?? '');
    draws = json['draws'] is int ? json['draws'] : int.tryParse(json['draws']?.toString() ?? '');
    losses = json['losses'] is int ? json['losses'] : int.tryParse(json['losses']?.toString() ?? '');
    matchesPlayed = json['matchesPlayed'] is int ? json['matchesPlayed'] : int.tryParse(json['matchesPlayed']?.toString() ?? '');
    isActive = json['isActive'];
    isDeleted = json['isDeleted'];
    
    if (json['registerUserId'] != null && json['registerUserId'] is Map<String, dynamic>) {
      registerUserId = RegisterUser.fromJson(json['registerUserId']);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': sId,
      'americanoMatchId': americanoMatchId,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'gender': gender,
      'playerLevel': playerLevel,
      'totalPoints': totalPoints,
      'pointsAgainst': pointsAgainst,
      'pointDifference': pointDifference,
      'wins': wins,
      'draws': draws,
      'losses': losses,
      'matchesPlayed': matchesPlayed,
      'isActive': isActive,
      'isDeleted': isDeleted,
      if (registerUserId != null) 'registerUserId': registerUserId!.toJson(),
    };
  }
}

class RegisterUser {
  String? sId;
  String? name;
  String? profilePic;

  RegisterUser({this.sId, this.name, this.profilePic});

  RegisterUser.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    name = json['name']?.toString();
    profilePic = json['profilePic']?.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': sId,
      'name': name,
      'profilePic': profilePic,
    };
  }
}

class AmericanoLeaderboardResponse {
  final String? americanoFormat;
  final List<AmericanoPlayer> players;
  final List<AmericanoTeam> teams;
  final MyRankInfo? myRankInfo;

  AmericanoLeaderboardResponse({
    this.americanoFormat,
    required this.players,
    required this.teams,
    this.myRankInfo,
  });
}

class AmericanoTeam {
  String? sId;
  String? americanoMatchId;
  String? teamName;
  List<AmericanoTeamPlayer>? players;
  int? totalPoints;
  int? pointsAgainst;
  int? pointDifference;
  int? wins;
  int? draws;
  int? losses;
  int? matchesPlayed;
  bool? isActive;
  bool? isDeleted;
  int? rank;

  AmericanoTeam({
    this.sId,
    this.americanoMatchId,
    this.teamName,
    this.players,
    this.totalPoints,
    this.pointsAgainst,
    this.pointDifference,
    this.wins,
    this.draws,
    this.losses,
    this.matchesPlayed,
    this.isActive,
    this.isDeleted,
    this.rank,
  });

  AmericanoTeam.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    americanoMatchId = json['americanoMatchId']?.toString();
    teamName = json['teamName']?.toString();
    if (json['players'] != null && json['players'] is List) {
      players = <AmericanoTeamPlayer>[];
      for (var v in json['players']) {
        if (v is Map<String, dynamic>) {
          players!.add(AmericanoTeamPlayer.fromJson(v));
        }
      }
    }
    totalPoints = json['totalPoints'] is int ? json['totalPoints'] : int.tryParse(json['totalPoints']?.toString() ?? '');
    pointsAgainst = json['pointsAgainst'] is int ? json['pointsAgainst'] : int.tryParse(json['pointsAgainst']?.toString() ?? '');
    pointDifference = json['pointDifference'] is int ? json['pointDifference'] : int.tryParse(json['pointDifference']?.toString() ?? '');
    wins = json['wins'] is int ? json['wins'] : int.tryParse(json['wins']?.toString() ?? '');
    draws = json['draws'] is int ? json['draws'] : int.tryParse(json['draws']?.toString() ?? '');
    losses = json['losses'] is int ? json['losses'] : int.tryParse(json['losses']?.toString() ?? '');
    matchesPlayed = json['matchesPlayed'] is int ? json['matchesPlayed'] : int.tryParse(json['matchesPlayed']?.toString() ?? '');
    isActive = json['isActive'];
    isDeleted = json['isDeleted'];
    rank = json['rank'] is int ? json['rank'] : int.tryParse(json['rank']?.toString() ?? '');
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': sId,
      'americanoMatchId': americanoMatchId,
      'teamName': teamName,
      if (players != null) 'players': players!.map((e) => e.toJson()).toList(),
      'totalPoints': totalPoints,
      'pointsAgainst': pointsAgainst,
      'pointDifference': pointDifference,
      'wins': wins,
      'draws': draws,
      'losses': losses,
      'matchesPlayed': matchesPlayed,
      'isActive': isActive,
      'isDeleted': isDeleted,
      'rank': rank,
    };
  }
}

class AmericanoTeamPlayer {
  String? americanoPlayerId;
  dynamic registerUserId; // Can be String or RegisterUser
  String? fullName;
  String? phoneNumber;
  String? email;
  String? gender;
  String? playerLevel;

  AmericanoTeamPlayer({
    this.americanoPlayerId,
    this.registerUserId,
    this.fullName,
    this.phoneNumber,
    this.email,
    this.gender,
    this.playerLevel,
  });

  AmericanoTeamPlayer.fromJson(Map<String, dynamic> json) {
    americanoPlayerId = json['americanoPlayerId']?.toString();
    if (json['registerUserId'] != null) {
      if (json['registerUserId'] is Map<String, dynamic>) {
        registerUserId = RegisterUser.fromJson(json['registerUserId']);
      } else {
        registerUserId = json['registerUserId']; // String representation
      }
    }
    fullName = json['fullName']?.toString();
    phoneNumber = json['phoneNumber']?.toString();
    email = json['email']?.toString();
    gender = json['gender']?.toString();
    playerLevel = json['playerLevel']?.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'americanoPlayerId': americanoPlayerId,
      'registerUserId': registerUserId is RegisterUser ? (registerUserId as RegisterUser).toJson() : registerUserId,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'email': email,
      'gender': gender,
      'playerLevel': playerLevel,
    };
  }
}


class MyRankInfo {
  final bool? isInMatch;
  final int? rank;
  final int? totalPlayers;
  final int? playersBehind;
  final num? betterThanPercent;
  final String? message;

  MyRankInfo({
    this.isInMatch,
    this.rank,
    this.totalPlayers,
    this.playersBehind,
    this.betterThanPercent,
    this.message,
  });

  factory MyRankInfo.fromJson(Map<String, dynamic> json) {
    return MyRankInfo(
      isInMatch: json['isInMatch'],
      rank: json['rank'],
      totalPlayers: json['totalPlayers'],
      playersBehind: json['playersBehind'],
      betterThanPercent: json['betterThanPercent'],
      message: json['message']?.toString(),
    );
  }
}
