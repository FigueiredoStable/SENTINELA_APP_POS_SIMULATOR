import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

enum SecureStorageKey { main, transactions, products, commands }

extension SecureStorageLookup on SecureStorageKey {
  String get instanceName {
    switch (this) {
      case SecureStorageKey.main:
        return 'storageMain';
      case SecureStorageKey.transactions:
        return 'storageTransactions';
      case SecureStorageKey.products:
        return 'storageProducts';
      case SecureStorageKey.commands:
        return 'storageCommands';
    }
  }

  FlutterSecureStorage get instance => GetIt.I<FlutterSecureStorage>(instanceName: instanceName);
}
