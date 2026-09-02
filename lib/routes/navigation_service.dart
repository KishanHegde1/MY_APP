import 'package:flutter/material.dart';

final class NavigationService {
  NavigationService({GlobalKey<NavigatorState>? navigatorKey})
    : navigatorKey = navigatorKey ?? GlobalKey<NavigatorState>();

  final GlobalKey<NavigatorState> navigatorKey;

  NavigatorState get _navigator {
    final state = navigatorKey.currentState;
    if (state == null) {
      throw StateError('Navigator is not mounted yet.');
    }
    return state;
  }

  Future<T?> pushNamed<T extends Object?>(
    String routeName, {
    Object? arguments,
  }) => _navigator.pushNamed<T>(routeName, arguments: arguments);

  Future<T?> replaceNamed<T extends Object?, TO extends Object?>(
    String routeName, {
    Object? arguments,
    TO? result,
  }) => _navigator.pushReplacementNamed<T, TO>(
    routeName,
    arguments: arguments,
    result: result,
  );

  Future<T?> clearAndPushNamed<T extends Object?>(
    String routeName, {
    Object? arguments,
  }) => _navigator.pushNamedAndRemoveUntil<T>(
    routeName,
    (_) => false,
    arguments: arguments,
  );

  bool canPop() => _navigator.canPop();

  void pop<T extends Object?>([T? result]) => _navigator.pop<T>(result);
}
