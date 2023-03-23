import 'package:go_router/go_router.dart';
import 'package:karmachain_dash/common_libs.dart';
import 'package:karmachain_dash/ui/screens/karmachain.dart';

/// Shared paths / urls used across the app
class ScreenPaths {
  /// Guest home screen (playground for now)
  static String welcome = '/';
}

/// Shared screen names across the app
class ScreenNames {
  /// Guest home screen (playground for now)
  static String welcome = 'welcome';
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
  return ScreenPaths.welcome;
}

/// The route configuration
final GoRouter appRouter = GoRouter(
    redirect: (context, state) {
      return null;
    },
    initialLocation: _getInitialLocation(),
    routes: <RouteBase>[
      GoRoute(
          // Initial app screen (playground for now)
          name: ScreenNames.welcome,
          path: ScreenPaths.welcome,
          builder: (BuildContext context, GoRouterState state) {
            return const Karmachain(); //WelcomeScreen(title: 'Karma Coin');
          }),
    ]);
