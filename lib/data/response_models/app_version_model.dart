class AppVersionModel {
  final bool? success;
  final bool? updateRequired;
  final bool? forceUpdate;
  final bool? isLatest;
  final String? message;
  final VersionData? data;

  AppVersionModel({
    this.success,
    this.updateRequired,
    this.forceUpdate,
    this.isLatest,
    this.message,
    this.data,
  });

  factory AppVersionModel.fromJson(Map<String, dynamic> json) {
    return AppVersionModel(
      success: json['success'],
      updateRequired: json['updateRequired'],
      forceUpdate: json['forceUpdate'],
      isLatest: json['isLatest'],
      message: json['message'],
      data: json['data'] != null ? VersionData.fromJson(json['data']) : null,
    );
  }
}

class VersionData {
  final String? currentVersion;
  final String? minimumVersion;
  final String? latestVersion;
  final String? storeUrl;
  final String? platform;

  VersionData({
    this.currentVersion,
    this.minimumVersion,
    this.latestVersion,
    this.storeUrl,
    this.platform,
  });

  factory VersionData.fromJson(Map<String, dynamic> json) {
    return VersionData(
      currentVersion: json['currentVersion'],
      minimumVersion: json['minimumVersion'],
      latestVersion: json['latestVersion'],
      storeUrl: json['storeUrl'],
      platform: json['platform'],
    );
  }
}
