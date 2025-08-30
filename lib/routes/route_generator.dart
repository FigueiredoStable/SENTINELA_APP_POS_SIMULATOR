import 'package:flutter/material.dart';
import 'package:sentinela_app_pos_simulator/src/pages/blocked/blocked_view.dart';
import 'package:sentinela_app_pos_simulator/src/pages/home/home_view.dart';
import 'package:sentinela_app_pos_simulator/src/pages/loading/loading_view.dart';
import 'package:sentinela_app_pos_simulator/src/pages/payment/payment_view.dart';
import 'package:sentinela_app_pos_simulator/src/pages/splahscreen/splashscreen.dart';

class RouteGenerator {
  static Route<dynamic> generateRoutes(RouteSettings settings) {
    switch (settings.name) {
      case '/splashscreen':
        return MaterialPageRoute(settings: settings, builder: (_) => const SplashScreen());
      case '/loading':
        return MaterialPageRoute(settings: settings, builder: (_) => const LoadingView());
      case '/home':
        return MaterialPageRoute(settings: settings, builder: (_) => const HomeView());
      case '/blocked':
        return MaterialPageRoute(settings: settings, builder: (_) => const BlockedView());
      case '/payment':
        return MaterialPageRoute(settings: settings, builder: (_) => const PaymentView());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(body: Center(child: Text("Route not found: ${settings.name}"))),
        );
    }
  }
}
