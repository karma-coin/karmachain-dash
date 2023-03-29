import 'package:fixnum/fixnum.dart';
import 'package:go_router/go_router.dart';
import 'package:karmachain_dash/common_libs.dart';
import 'package:karmachain_dash/ui/screens/blocks.dart';
import 'package:karmachain_dash/ui/screens/karmachain.dart';

/// Shared paths / urls used across the app
class ScreenPaths {
  /// Guest home screen (playground for now)
  static String home = '/';
  static String blocks = '/blocks';
}

/// Shared screen names across the app
class ScreenNames {
  /// Guest home screen (playground for now)
  static String home = 'home';
  static String blocks = 'blocks';
}

popUntil(String path) {
  String currentRoute = appRouter.location;
  while (appRouter.canPop() && path != currentRoute) {
    currentRoute = appRouter.location;
    if (path != currentRoute) {
      appRouter.pop();
    }
  }
}

void pushNamedAndRemoveUntil(String path) {
  while (appRouter.canPop()) {
    appRouter.pop();
  }
  appRouter.go(path);
}

String _getInitialLocation() {
  return ScreenPaths.home;
}

/// The route configuration
final GoRouter appRouter = GoRouter(
    redirect: (context, state) {
      return null;
    },
    initialLocation: _getInitialLocation(),
    routes: <RouteBase>[
      GoRoute(
          name: ScreenNames.home,
          path: ScreenPaths.home,
          builder: (BuildContext context, GoRouterState state) {
            return const Karmachain();
          }),
      GoRoute(
          name: ScreenNames.blocks,
          path: ScreenPaths.blocks,
          builder: (BuildContext context, GoRouterState state) {
            return Blocks();
          }),
    ]);
