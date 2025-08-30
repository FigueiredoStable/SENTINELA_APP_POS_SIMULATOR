import 'dart:async';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class InternetCheckConnectionService {
  final _controller = StreamController<bool>.broadcast();
  late final StreamSubscription _subscription;

  bool _isConnected = true;

  bool get isConnected => _isConnected;

  Stream<bool> get onConnectionChanged => _controller.stream;

  Future<void> init() async {
    final connection = InternetConnection.createInstance(customCheckOptions: [InternetCheckOption(uri: Uri.parse('https://nmhyclmkvjmoqimtlths.supabase.co'))]);
    _isConnected = await connection.hasInternetAccess;
    _subscription = connection.onStatusChange.listen((status) {
      final connected = status == InternetStatus.connected;
      if (_isConnected != connected) {
        _isConnected = connected;
        _controller.add(_isConnected);
      }
    });
  }

  void dispose() {
    _subscription.cancel();
    _controller.close();
  }
}
