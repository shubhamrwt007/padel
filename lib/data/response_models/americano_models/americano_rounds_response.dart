class AmericanoRoundsResponse {
  bool? success;
  String? filter;
  List<AmericanoRoundMatch>? lastRound;
  List<AmericanoRoundMatch>? data;

  AmericanoRoundsResponse({
    this.success,
    this.filter,
    this.lastRound,
    this.data,
  });

  AmericanoRoundsResponse.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    filter = json['filter'];
    if (json['lastRound'] != null) {
      lastRound = <AmericanoRoundMatch>[];
      if (json['lastRound'] is List) {
        for (var v in json['lastRound']) {
          if (v is Map<String, dynamic>) {
            lastRound!.add(AmericanoRoundMatch.fromJson(v));
          }
        }
      }
    }
    if (json['data'] != null) {
      data = <AmericanoRoundMatch>[];
      if (json['data'] is List) {
        for (var v in json['data']) {
          if (v is Map<String, dynamic>) {
            data!.add(AmericanoRoundMatch.fromJson(v));
          }
        }
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = {};
    map['success'] = success;
    map['filter'] = filter;
    if (lastRound != null) {
      map['lastRound'] = lastRound!.map((v) => v.toJson()).toList();
    }
    if (data != null) {
      map['data'] = data!.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

class AmericanoRoundMatch {
  String? sId;
  String? americanoMatchId;
  String? americanoFormat;
  int? roundNo;
  int? matchNo;
  int? courtNo;
  int? playDayNo;
  String? playDate;
  String? status;
  int? maxPoints;
  AmericanoRoundTeam? teamA;
  AmericanoRoundTeam? teamB;
  String? winner;
  bool? scoreApplied;

  AmericanoRoundMatch({
    this.sId,
    this.americanoMatchId,
    this.americanoFormat,
    this.roundNo,
    this.matchNo,
    this.courtNo,
    this.playDayNo,
    this.playDate,
    this.status,
    this.maxPoints,
    this.teamA,
    this.teamB,
    this.winner,
    this.scoreApplied,
  });

  AmericanoRoundMatch.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    americanoMatchId = json['americanoMatchId'];
    americanoFormat = json['americanoFormat'];
    roundNo = json['roundNo'] is int ? json['roundNo'] : int.tryParse(json['roundNo']?.toString() ?? '');
    matchNo = json['matchNo'] is int ? json['matchNo'] : int.tryParse(json['matchNo']?.toString() ?? '');
    courtNo = json['courtNo'] is int ? json['courtNo'] : int.tryParse(json['courtNo']?.toString() ?? '');
    playDayNo = json['playDayNo'] is int ? json['playDayNo'] : int.tryParse(json['playDayNo']?.toString() ?? '');
    playDate = json['playDate']?.toString();
    status = json['status']?.toString();
    maxPoints = json['maxPoints'] is int ? json['maxPoints'] : int.tryParse(json['maxPoints']?.toString() ?? '');
    teamA = json['teamA'] != null && json['teamA'] is Map<String, dynamic>
        ? AmericanoRoundTeam.fromJson(json['teamA'])
        : null;
    teamB = json['teamB'] != null && json['teamB'] is Map<String, dynamic>
        ? AmericanoRoundTeam.fromJson(json['teamB'])
        : null;
    winner = json['winner']?.toString();
    scoreApplied = json['scoreApplied'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = {};
    map['_id'] = sId;
    map['americanoMatchId'] = americanoMatchId;
    map['americanoFormat'] = americanoFormat;
    map['roundNo'] = roundNo;
    map['matchNo'] = matchNo;
    map['courtNo'] = courtNo;
    map['playDayNo'] = playDayNo;
    map['playDate'] = playDate;
    map['status'] = status;
    map['maxPoints'] = maxPoints;
    if (teamA != null) {
      map['teamA'] = teamA!.toJson();
    }
    if (teamB != null) {
      map['teamB'] = teamB!.toJson();
    }
    map['winner'] = winner;
    map['scoreApplied'] = scoreApplied;
    return map;
  }
}

class AmericanoRoundTeam {
  String? teamName;
  List<AmericanoRoundPlayer>? players;
  int? points;
  int? faults;
  int? errors;
  int? forcedErrors;

  AmericanoRoundTeam({
    this.teamName,
    this.players,
    this.points,
    this.faults,
    this.errors,
    this.forcedErrors,
  });

  AmericanoRoundTeam.fromJson(Map<String, dynamic> json) {
    teamName = json['teamName']?.toString();
    if (json['players'] != null && json['players'] is List) {
      players = <AmericanoRoundPlayer>[];
      for (var v in json['players']) {
        if (v is Map<String, dynamic>) {
          players!.add(AmericanoRoundPlayer.fromJson(v));
        }
      }
    }
    points = json['points'] is int ? json['points'] : int.tryParse(json['points']?.toString() ?? '');
    faults = json['faults'] is int ? json['faults'] : int.tryParse(json['faults']?.toString() ?? '');
    errors = json['errors'] is int ? json['errors'] : int.tryParse(json['errors']?.toString() ?? '');
    forcedErrors = json['forcedErrors'] is int ? json['forcedErrors'] : int.tryParse(json['forcedErrors']?.toString() ?? '');
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = {};
    map['teamName'] = teamName;
    if (players != null) {
      map['players'] = players!.map((v) => v.toJson()).toList();
    }
    map['points'] = points;
    map['faults'] = faults;
    map['errors'] = errors;
    map['forcedErrors'] = forcedErrors;
    return map;
  }
}

class AmericanoRoundPlayer {
  String? americanoPlayerId;
  String? fullName;
  String? phoneNumber;
  String? email;
  String? gender;
  String? playerLevel;
  RegisterUserMinimal? registerUserId;

  AmericanoRoundPlayer({
    this.americanoPlayerId,
    this.fullName,
    this.phoneNumber,
    this.email,
    this.gender,
    this.playerLevel,
    this.registerUserId,
  });

  AmericanoRoundPlayer.fromJson(Map<String, dynamic> json) {
    americanoPlayerId = json['americanoPlayerId']?.toString();
    fullName = json['fullName']?.toString();
    phoneNumber = json['phoneNumber']?.toString();
    email = json['email']?.toString();
    gender = json['gender']?.toString();
    playerLevel = json['playerLevel']?.toString();
    if (json['registerUserId'] != null) {
      if (json['registerUserId'] is Map<String, dynamic>) {
        registerUserId = RegisterUserMinimal.fromJson(json['registerUserId']);
      } else {
        registerUserId = RegisterUserMinimal(sId: json['registerUserId'].toString());
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = {};
    map['americanoPlayerId'] = americanoPlayerId;
    map['fullName'] = fullName;
    map['phoneNumber'] = phoneNumber;
    map['email'] = email;
    map['gender'] = gender;
    map['playerLevel'] = playerLevel;
    if (registerUserId != null) {
      map['registerUserId'] = registerUserId!.toJson();
    }
    return map;
  }
}

class RegisterUserMinimal {
  String? sId;
  String? name;
  String? profilePic;
  String? phoneNumber;
  String? gender;
  String? email;

  RegisterUserMinimal({
    this.sId,
    this.name,
    this.profilePic,
    this.phoneNumber,
    this.gender,
    this.email,
  });

  RegisterUserMinimal.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    name = json['name']?.toString();
    profilePic = json['profilePic']?.toString();
    phoneNumber = json['phoneNumber']?.toString();
    gender = json['gender']?.toString();
    email = json['email']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = {};
    map['_id'] = sId;
    map['name'] = name;
    map['profilePic'] = profilePic;
    map['phoneNumber'] = phoneNumber;
    map['gender'] = gender;
    map['email'] = email;
    return map;
  }
}
