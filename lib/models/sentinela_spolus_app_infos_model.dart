class SentinelaSpolusAppInfosModel {
  String? appName;
  String? version;
  String? buildNumber;
  String? packageName;

  SentinelaSpolusAppInfosModel({this.appName, this.version, this.buildNumber, this.packageName});

  SentinelaSpolusAppInfosModel.fromJson(Map<String, dynamic> json) {
    appName = json['appName'];
    version = json['version'];
    buildNumber = json['buildNumber'];
    packageName = json['packageName'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['appName'] = appName;
    data['version'] = version;
    data['buildNumber'] = buildNumber;
    data['packageName'] = packageName;
    return data;
  }
}
