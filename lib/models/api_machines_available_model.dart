class ApiMachinesAvailable {
  String? message;
  List<Machines>? machines;

  ApiMachinesAvailable({this.message, this.machines});

  ApiMachinesAvailable.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    if (json['machines'] != null) {
      machines = <Machines>[];
      json['machines'].forEach((v) {
        machines!.add(Machines.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['message'] = message;
    if (machines != null) {
      data['machines'] = machines!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Machines {
  String? id;
  String? name;
  String? address;
  MachineType? machineType;

  Machines({this.id, this.name, this.address, this.machineType});

  Machines.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    address = json['address'];
    machineType = json['machine_type'] != null ? MachineType.fromJson(json['machine_type']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['address'] = address;
    if (machineType != null) {
      data['machine_type'] = machineType!.toJson();
    }
    return data;
  }
}

class MachineType {
  String? id;
  String? describe;
  String? createdAt;
  String? updatedAt;
  String? machineType;
  String? machineClass;
  String? productClass;
  List<String>? productDescription;
  int? productMaxCapacity;

  MachineType({this.id, this.describe, this.createdAt, this.updatedAt, this.machineType, this.machineClass, this.productClass, this.productDescription, this.productMaxCapacity});

  MachineType.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    describe = json['describe'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    machineType = json['machine_type'];
    machineClass = json['machine_class'];
    productClass = json['product_class'];
    productDescription = json['product_description'].cast<String>();
    productMaxCapacity = json['product_max_capacity'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['describe'] = describe;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['machine_type'] = machineType;
    data['machine_class'] = machineClass;
    data['product_class'] = productClass;
    data['product_description'] = productDescription;
    data['product_max_capacity'] = productMaxCapacity;
    return data;
  }
}
