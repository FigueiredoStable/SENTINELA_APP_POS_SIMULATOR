class HeartBeatResponseModel {
  bool? success;
  List<Commands>? commands;
  bool? isBlocked;

  HeartBeatResponseModel({this.success, this.commands, this.isBlocked});

  HeartBeatResponseModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['commands'] != null) {
      commands = <Commands>[];
      json['commands'].forEach((v) {
        commands!.add(Commands.fromJson(v));
      });
    }
    isBlocked = json['is_blocked'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    if (commands != null) {
      data['commands'] = commands!.map((v) => v.toJson()).toList();
    }
    data['is_blocked'] = isBlocked;
    return data;
  }
}

class Commands {
  String? type;
  String? epoch;
  String? command;
  String? eventId;
  String? remoteCreditValue;

  Commands({this.type, this.epoch, this.command, this.eventId, this.remoteCreditValue});

  Commands.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    epoch = json['epoch'];
    command = json['command'];
    eventId = json['event_id'];
    remoteCreditValue = json['remote_credit_value'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['type'] = type;
    data['epoch'] = epoch;
    data['command'] = command;
    data['event_id'] = eventId;
    data['remote_credit_value'] = remoteCreditValue;
    return data;
  }
}
