class RemoteCommandEventModel {
  final int order;
  final bool status;
  final String command;

  RemoteCommandEventModel({
    required this.order,
    required this.status,
    required this.command,
  });

  factory RemoteCommandEventModel.fromJson(Map<String, dynamic> json) {
    return RemoteCommandEventModel(
      order: json['order'] as int,
      status: json['status'] as bool,
      command: json['command'] as String,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'order': order,
      'status': status,
      'command': command,
    };
  }
  @override
  String toString() {
    return toJson().toString();
  }
}
