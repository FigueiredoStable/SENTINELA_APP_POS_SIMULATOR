import 'package:flutter/material.dart';

class NavigationService extends NavigatorObserver {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  String? _lastRoute;
  String? get currentRoute => _lastRoute;

  // ===== Hooks do NavigatorObserver =====
  @override
  void didPush(Route route, Route? previousRoute) {
    _lastRoute = route.settings.name ?? _lastRoute;
    super.didPush(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _lastRoute = newRoute?.settings.name ?? _lastRoute;
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    _lastRoute = previousRoute?.settings.name ?? _lastRoute;
    super.didPop(route, previousRoute);
  }

  // ===== Métodos utilitários de navegação =====
  Future<T?>? pushTo<T extends Object?>(String route, {Object? arguments}) {
    return navigatorKey.currentState?.pushNamed<T>(route, arguments: arguments);
  }

  Future<T?>? pushReplacement<T extends Object?, TO extends Object?>(String route, {Object? arguments, TO? result}) {
    return navigatorKey.currentState?.pushReplacementNamed<T, TO>(route, arguments: arguments, result: result);
  }

  Future<T?>? pushAndRemoveUntil<T extends Object?>(String route, {Object? arguments}) {
    return navigatorKey.currentState?.pushNamedAndRemoveUntil<T>(route, (r) => false, arguments: arguments);
  }

  void pop<T extends Object?>([T? result]) {
    if (navigatorKey.currentState?.canPop() ?? false) {
      navigatorKey.currentState?.pop<T>(result);
    }
  }

  void goBackOrToInitial() {
    if (navigatorKey.currentState?.canPop() ?? false) {
      navigatorKey.currentState?.pop();
    } else {
      goBackToInitial();
    }
  }

  void goBackToInitial() {
    navigatorKey.currentState?.pushNamedAndRemoveUntil('/home', (r) => false);
  }

  void forceGoHome() {
    navigatorKey.currentState?.popUntil((route) => route.settings.name == '/home');
  }

  bool isInitialRoute() => !(navigatorKey.currentState?.canPop() ?? true);

  bool isPaymentActualRoute() => _lastRoute == '/payment';
}
