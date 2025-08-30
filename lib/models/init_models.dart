// class AvailableMachines {
//   List<Machines>? machines;

//   AvailableMachines({this.machines});

//   AvailableMachines.fromJson(Map<String, dynamic> json) {
//     if (json['data'] != null) {
//       machines = <Machines>[];
//       json['data'].forEach((v) {
//         machines!.add(Machines.fromJson(v));
//       });
//     }
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = <String, dynamic>{};
//     if (machines != null) {
//       data['data'] = machines!.map((v) => v.toJson()).toList();
//     }
//     return data;
//   }
// }

// class Machines {
//   String? id;
//   String? name;
//   String? address;
//   Map<String, dynamic>? machineTypeInfo;

//   Machines({this.id, this.name, this.address, this.machineTypeInfo});

//   Machines.fromJson(Map<String, dynamic> json) {
//     id = json['id'];
//     name = json['name'];
//     address = json['address'];
//     machineTypeInfo = json['machine_type'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = <String, dynamic>{};
//     data['id'] = id;
//     data['name'] = name;
//     data['address'] = address;
//     if (machineTypeInfo != null) {
//       data['machine_type_info'] = machineTypeInfo;
//     }
//     return data;
//   }
// }

// class PriceOptionsList {
//   List<PriceOpts>? priceOpts;

//   PriceOptionsList({this.priceOpts});

//   PriceOptionsList.fromJson(Map<String, dynamic> json) {
//     if (json['price_opts'] != null) {
//       priceOpts = <PriceOpts>[];
//       json['price_opts'].forEach((v) {
//         priceOpts!.add(PriceOpts.fromJson(v));
//       });
//     }
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = <String, dynamic>{};
//     if (priceOpts != null) {
//       data['price_opts'] = priceOpts!.map((v) => v.toJson()).toList();
//     }
//     return data;
//   }
// }

// class PriceOpts {
//   late String price;
//   late String credits;

//   PriceOpts({required this.price, required this.credits});

//   PriceOpts.fromJson(Map<String, dynamic> json) {
//     price = json['price'];
//     credits = json['credits'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = <String, dynamic>{};
//     data['price'] = price;
//     data['credits'] = credits;
//     return data;
//   }
// }

// class CountersSettings {
//   int? counterWaitingCard;
//   int? counterWaitingPass;
//   int? counterCardRemoved;
//   int? countError;
//   int? countSuccess;

//   CountersSettings({this.counterWaitingCard, this.counterWaitingPass, this.counterCardRemoved, this.countError, this.countSuccess});

//   CountersSettings.fromJson(Map<String, dynamic> json) {
//     counterWaitingCard = json['counterWaitingCard'];
//     counterWaitingPass = json['counterWaitingPass'];
//     counterCardRemoved = json['counterCardRemoved'];
//     countError = json['countError'];
//     countSuccess = json['countSuccess'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = <String, dynamic>{};
//     data['counterWaitingCard'] = counterWaitingCard;
//     data['counterWaitingPass'] = counterWaitingPass;
//     data['counterCardRemoved'] = counterCardRemoved;
//     data['countError'] = countError;
//     data['countSuccess'] = countSuccess;
//     return data;
//   }
// }
